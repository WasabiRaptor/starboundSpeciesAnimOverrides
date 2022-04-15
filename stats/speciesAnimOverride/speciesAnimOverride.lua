function init()
	self.loopedMessages = {}
	self.equipment = {}
	self.offsets = {enabled = false, parts = {}}
	self.rotating = {enabled = false, parts = {}}
	self.animStateData = root.assetJson("/stats/speciesAnimOverride/"..config.getParameter("animationConfig")).animatedParts.stateTypes
	self.animFunctionQueue = {}
	self.parts = {}
	self.globalTagDefaults = root.assetJson("/stats/speciesAnimOverride/"..config.getParameter("animationConfig")).globalTagDefaults or {}

	for statename, state in pairs(self.animStateData) do
		state.animationState = {
			anim = state.default,
			priority = state.states[state.default].priority,
			cycle = state.states[state.default].cycle,
			frames = state.states[state.default].frames,
			mode = state.states[state.default].mode,
			speed = state.states[state.default].frames / state.states[state.default].cycle,
			frame = 1,
			time = 0
		}
		state.tag = nil
		self.animFunctionQueue[statename] = {}

		animator.setGlobalTag(statename.."Frame", 1)
		animator.setGlobalTag(statename.."Anim", state.default)
	end

	if config.getParameter("overrideData") then
		status.setStatusProperty("speciesAnimOverrideData", config.getParameter("overrideData"))
	end

end

function initAfterInit()
	self.species = self.overrideData.species or world.entitySpecies(entity.id())
	self.gender = self.overrideData.gender or world.entityGender(entity.id())
	self.identity = self.overrideData.identity or {}
	local success, speciesData = pcall(root.assetJson, ("/humanoid/"..self.species.."/speciesAnimOverride.config"))
	if success then
		self.speciesData = speciesData
	else
		self.speciesData = root.assetJson("/humanoid/speciesAnimOverride.config")
	end

	if self.speciesData.scripts ~= nil then
		for _, script in ipairs(self.speciesData.scripts) do
			require(script)
		end
	end
	local success, speciesFile = pcall(root.assetJson,("/species/"..self.species..".species"))
	self.speciesFile = speciesFile
	self.bodyconfig = root.assetJson((speciesFile or {}).humanoidConfig or "/humanoid.config")
	animator.translateTransformationGroup("handoffset", self.bodyconfig.frontHandPosition)
	animator.translateTransformationGroup("backarmoffset", self.bodyconfig.backArmOffset)
	animator.translateTransformationGroup("globalOffset", {((self.speciesData.globalOffset or {})[1] or 0)/8, ((self.speciesData.globalOffset or {})[2] or 0)/8})

	for tagname, string in pairs(self.speciesData.globalTagDefaults or {}) do
		local part = replaceSpeciesGenderTags(string)
		self.globalTagDefaults[tagname] = part
		animator.setGlobalTag(tagname, part)
	end
	for partname, string in pairs(self.speciesData.partImages or {}) do
		local part = replaceSpeciesGenderTags(string)
		animator.setPartTag(partname, "partImage", part)
		self.parts[partname] = part
	end
	for partname, data in pairs(self.speciesData.partTagDefaults or {}) do
		for tagname, string in pairs(data) do
			local part = replaceSpeciesGenderTags(string)
			animator.setPartTag(partname, tagname, part)
		end
	end

	local portrait = world.entityPortrait(entity.id(), "full")
	local gotEmote
	for _, part in ipairs(portrait) do
		local imageString = part.image
		-- check for doing an emote animation
		if not gotEmote then
			local found1, found2 = imageString:find("/emote.png:")
			if found1 ~= nil then
				local found3, found4 = imageString:find(".1", found2, found2+10 )
				if found3 ~= nil then
					gotEmote = true
					if not self.directives then
						local directives = imageString:sub(found4+1)
						if (self.speciesFile.humanoidOverrides or {}).bodyFullbright then
							directives = directives.."?multiply=FFFFFFfb"
						end
						sb.logInfo(directives)
						self.directives = self.overrideData.directives or directives
						animator.setGlobalTag("customizeDirectives", self.directives)
					end
				end
			end
		end

		--get personality values
		if not self.identity.body then
			found1, found2 = imageString:find("body.png:idle.")
			if found1 ~= nil then
				self.identity.body = imageString:sub(found2+1, found2+1)
			end
		end
		if not self.identity.arm then
			found1, found2 = imageString:find("backarm.png:idle.")
			if found1 ~= nil then
				self.identity.arm = imageString:sub(found2+1, found2+1)
			end
		end

		if not self.identity.hairGroup and type(self.speciesFile) == "table" then
			for i, data in ipairs(self.speciesFile.genders or {}) do
				if data.name == self.gender then
					self.identity.hairGroup = data.hairGroup or "hair"
				end
			end
		end
		if not self.identity.hairType then
			found1, found2 = imageString:find("/"..(self.identity.hairGroup or "hair").."/")
			if found1 ~= nil then
				found3, found4 = imageString:find(".png")
				self.identity.hairType = imageString:sub(found2+1, found3-1)
			end
		end

		if not self.identity.facialHairGroup and type(self.speciesFile) == "table" then
			for i, data in ipairs(self.speciesFile.genders or {}) do
				if data.name == self.gender then
					self.identity.facialHairGroup = data.facialHairGroup or "facialHair"
				end
			end
		end
		if not self.identity.facialHairType then
			found1, found2 = imageString:find("/"..(self.identity.facialHairGroup or "facialHair").."/")
			if found1 ~= nil then
				found3, found4 = imageString:find(".png")
				self.identity.facialHairType = imageString:sub(found2+1, found3-1)
			end
		end

		if not self.identity.facialMaskGroup and type(self.speciesFile) == "table" then
			for i, data in ipairs(self.speciesFile.genders or {}) do
				if data.name == self.gender then
					self.identity.facialMaskGroup = data.facialMaskGroup or "facialMask"
				end
			end
		end
		if not self.identity.facialMaskType then
			found1, found2 = imageString:find("/"..(self.identity.facialMaskGroup or "facialMask").."/")
			if found1 ~= nil then
				found3, found4 = imageString:find(".png")
				self.identity.facialMaskType = imageString:sub(found2+1, found3-1)
			end
		end


		if not self.identity.offsets and (self.identity.body ~= nil) and (self.identity.arm ~= nil) then
			local bodyIdle = "idle."..self.identity.body
			local armIdle = "idle."..self.identity.arm

			self.identity.offsets = true

			for i, data in ipairs(self.bodyconfig.personalities) do
				if data[1] == bodyIdle and data[2] == armIdle then
					table.insert(self.speciesData.animations.idle.offset.parts, {
						groups = (self.speciesData.personalityOffsets or {}).bodyGroups,
						x = {data[3][1]},
						y = {data[3][2]}
					})
					table.insert(self.speciesData.animations.idle.offset.parts, {
						groups = (self.speciesData.personalityOffsets or {}).armGroups,
						x = {data[4][1]},
						y = {data[4][2]}
					})
				end
			end
		end
	end
	animator.setGlobalTag( "bodyPersonality", self.identity.body )
	for i, data in ipairs( ((self.speciesData.personalityOffsets or {}).bodyOffsets or {})[self.identity.body] or {} ) do
		table.insert(self.speciesData.animations.idle.offset.parts, data)
	end

	animator.setGlobalTag( "backarmPersonality", self.identity.arm )
	animator.setGlobalTag( "frontarmPersonality", self.identity.arm )

	if self.identity.hairType ~= nil then
		local hairPath = "/humanoid/"..self.species.."/"..self.identity.hairGroup.."/"..self.identity.hairType..".png"
		animator.setPartTag( "hair", "partImage", hairPath )
		animator.setPartTag( "hair_fg", "partImage", hairPath )
	end
	if self.identity.facialHairType ~= nil then
		local hairPath = "/humanoid/"..self.species.."/"..self.identity.facialHairGroup.."/"..self.identity.facialHairType..".png"
		animator.setPartTag( "facialHair", "partImage", hairPath )
	end
	if self.identity.facialMaskType ~= nil then
		local hairPath = "/humanoid/"..self.species.."/"..self.identity.facialMaskGroup.."/"..self.identity.facialMaskType..".png"
		animator.setPartTag( "facialMask", "partImage", hairPath )
	end


	self.inited = true
end

function replaceSpeciesGenderTags(string)
	return sb.replaceTags(string, { gender = self.gender, species = self.species })
end

function update(dt)
	effect.setParentDirectives("crop;0;0;0;0")
	self.overrideData = status.statusProperty("speciesAnimOverrideData") or {}

	if (not self.inited) or (self.overrideData.gender ~= nil and self.overrideData.gender ~= self.gender) or (self.overrideData.species ~= nil and self.overrideData.species ~= self.species) then
		initAfterInit()
	else
		doUpdate(dt)
	end
end

function doUpdate(dt)
	updateAnims(dt)
	animator.setFlipped(mcontroller.facingDirection() == -1)
	animator.setGlobalTag("direction", mcontroller.facingDirection() * mcontroller.movingDirection() )
	getCosmeticItems()
	getHandItems()
	checkHumanoidAnim()
	mcontroller.controlParameters({ collisionPoly = self.hitbox })
	animator.resetTransformationGroup("globalRotation")
	animator.rotateTransformationGroup("globalRotation", mcontroller.rotation() * mcontroller.facingDirection())
end

function uninit()
end

function loopedMessage(name, eid, message, args, callback, failCallback)
	if self.loopedMessages[name] == nil then
		self.loopedMessages[name] = {
			rpc = world.sendEntityMessage(eid, message, table.unpack(args or {})),
			callback = callback,
			failCallback = failCallback
		}
	elseif self.loopedMessages[name].rpc:finished() then
		if self.loopedMessages[name].rpc:succeeded() and self.loopedMessages[name].callback ~= nil then
			self.loopedMessages[name].callback(self.loopedMessages[name].rpc:result())
		elseif self.loopedMessages[name].failCallback ~= nil then
			self.loopedMessages[name].failCallback()
		end
		self.loopedMessages[name] = nil
	end
end

function getHandItems()
	if mcontroller.facingDirection() < 0 then
		getHandItem("primary", "frontarms")
		getHandItem("alt", "backarms")
	else
		getHandItem("primary", "backarms")
		getHandItem("alt", "frontarms")
	end
end

function getHandItem(hand, part)
	local itemDescriptor = world.entityHandItemDescriptor(entity.id(), hand)
	if itemDescriptor ~= nil then
		if root.itemType(itemDescriptor.name) == "activeitem" then
			if  (not itemDescriptor.parameters or not itemDescriptor.parameters.itemHasOverrideLockScript) then
				loopedMessage("giveItemScript"..hand, entity.id(), "giveHeldItemOverrideLockScript", {itemDescriptor} )
			end
			local itemOverrideData = status.statusProperty(hand.."ItemOverrideData") or {}
			if itemOverrideData.setHoldingItem ~= false then
				local item = root.itemConfig(itemDescriptor)
				-- this is going to take a lot more effort I don't want to spend right now
			else

			end
		end

	else

	end
end

function setEmptyHand(hand, part)
end

setCosmetic = {}
currentCosmeticName = {}

function getCosmeticItems()
	loopedMessage("getEquipsAndLounging", entity.id(), "animOverrideGetEquipsAndLounge", {}, function(data)
		setCosmetic.head(data.headCosmetic or data.head)
		setCosmetic.chest(data.chestCosmetic or data.chest)
		setCosmetic.legs(data.legsCosmetic or data.legs)
		setCosmetic.back(data.backCosmetic or data.back)
		self.loungingIn = data.lounging
	end )
end

function setCosmetic.head(cosmetic)
	if cosmetic ~= nil then
		if currentCosmeticName.head == cosmetic.name then return end
		currentCosmeticName.head = cosmetic.name

		local item = root.itemConfig(cosmetic)
		local mask = fixFilepath(item.config.mask, item)
		local image = fixFilepath(item.config[self.gender.."Frames"], item)
		local directives = getCosmeticDirectives(item)

		animator.setPartTag("head_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("head_cosmetic", "partImage", image or "" )
		animator.setGlobalTag( "headMask", mask or self.globalTagDefaults.headMask or "" )

		setCosmetic.head_addon(cosmetic, item, directives)
	else
		currentCosmeticName.head = nil
		setCosmetic.head_clear(cosmetic)
	end
end

function setCosmetic.head_addon(cosmetic, item, directives)
end
function setCosmetic.head_clear(cosmetic)
	animator.setPartTag("head_cosmetic", "partImage", "" )
	animator.setGlobalTag( "headMask", self.globalTagDefaults.headMask or "" )
end


function setCosmetic.chest(cosmetic)
	if cosmetic ~= nil then
		if currentCosmeticName.chest == cosmetic.name then return end
		currentCosmeticName.chest = cosmetic.name

		local item = root.itemConfig(cosmetic)
		local bodyType = item.bodyType or "humanoid"
		if bodyType ~= self.speciesData.bodyType then return setCosmetic.chest_clear(cosmetic) end

		local images = item.config[self.gender.."Frames"]

		local chest = fixFilepath(images.body, item)

		local backSleeve = fixFilepath(images.backSleeve, item)
		local frontSleeve = fixFilepath(images.frontSleeve, item)

		local frontMask = fixFilepath(images.frontMask, item)
		local backMask = fixFilepath(images.backMask, item)

		local chestMask = fixFilepath(images.bodyMask, item)

		local directives = getCosmeticDirectives(item)

		animator.setPartTag("chest_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("backarms_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("frontarms_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("backarms_rotation_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("frontarms_rotation_cosmetic", "cosmeticDirectives", directives or "" )

		animator.setPartTag("chest_cosmetic", "partImage", chest or "" )
		animator.setPartTag("backarms_cosmetic", "partImage", backSleeve or "" )
		animator.setPartTag("frontarms_cosmetic", "partImage", frontSleeve or "" )
		animator.setPartTag("backarms_rotation_cosmetic", "partImage", backSleeve or "" )
		animator.setPartTag("frontarms_rotation_cosmetic", "partImage", frontSleeve or "" )

		animator.setGlobalTag( "frontarmsMask", frontMask or self.globalTagDefaults.frontarmsMask or "" )
		animator.setGlobalTag( "backarmsMask", backMask or self.globalTagDefaults.backarmsMask or "" )
		animator.setGlobalTag( "chestMask", chestMask or self.globalTagDefaults.chestMask or "" )

		setCosmetic.chest_addon(cosmetic, item, images, directives)
	else
		currentCosmeticName.chest = nil
		setCosmetic.chest_clear(cosmetic)
	end
end
function setCosmetic.chest_addon(cosmetic, item, images, directives)
end
function setCosmetic.chest_clear(cosmetic)
	animator.setPartTag("chest_cosmetic", "partImage", "" )
	animator.setPartTag("backarms_cosmetic", "partImage", "" )
	animator.setPartTag("frontarms_cosmetic", "partImage", "" )
	animator.setPartTag("backarms_rotation_cosmetic", "partImage", "" )
	animator.setPartTag("frontarms_rotation_cosmetic", "partImage", "" )

	animator.setGlobalTag( "frontarmsMask", self.globalTagDefaults.frontarmsMask or "" )
	animator.setGlobalTag( "backarmsMask", self.globalTagDefaults.backarmsMask or "" )
	animator.setGlobalTag( "chestMask", self.globalTagDefaults.chestMask or "" )
end

function setCosmetic.legs(cosmetic)
	if cosmetic ~= nil then
		if currentCosmeticName.legs == cosmetic.name then return end
		currentCosmeticName.legs = cosmetic.name

		local item = root.itemConfig(cosmetic)
		local bodyType = item.bodyType or "humanoid"
		if bodyType ~= self.speciesData.bodyType then return setCosmetic.legs_clear(cosmetic) end

		local body = fixFilepath(item.config[self.gender.."Frames"], item)
		local tail = fixFilepath(item.config[self.gender.."TailFrames"], item)

		local frontlegs = fixFilepath(item.config[self.gender.."frontlegsFrames"], item)

		local mask = fixFilepath(item.config.mask, item)
		local tailMask = fixFilepath(item.config.tailMask, item)

		local directives = getCosmeticDirectives(item)

		animator.setPartTag("body_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("body_cosmetic", "partImage", body or "" )

		animator.setPartTag("frontlegs_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("frontlegs_cosmetic", "partImage", frontlegs or body or "" )

		animator.setPartTag("tail_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("tail_cosmetic", "partImage", tail or "" )

		animator.setGlobalTag( "bodyMask", mask or self.globalTagDefaults.bodyMask or "" )
		animator.setGlobalTag( "tailMask", tailMask or self.globalTagDefaults.tailMask or "" )

		setCosmetic.legs_addon(cosmetic, item, directives)
	else
		currentCosmeticName.legs = nil
		setCosmetic.legs_clear(cosmetic)
	end
end
function setCosmetic.legs_addon(cosmetic, item, directives)
end
function setCosmetic.legs_clear(cosmetic)
	animator.setPartTag("body_cosmetic", "partImage", "" )
	animator.setPartTag("tail_cosmetic", "partImage", "" )
	animator.setPartTag("frontlegs_cosmetic", "partImage", "" )

	animator.setGlobalTag( "bodyMask", self.globalTagDefaults.bodyMask or "" )
	animator.setGlobalTag( "tailMask", self.globalTagDefaults.tailMask or "" )
end

function setCosmetic.back(cosmetic)
	if cosmetic ~= nil then
		if currentCosmeticName.back == cosmetic.name then return end
		currentCosmeticName.back = cosmetic.name

		local item = root.itemConfig(cosmetic)
		local bodyType = item.bodyType or "humanoid"
		if bodyType ~= self.speciesData.bodyType then return setCosmetic.back_clear(cosmetic) end

		local directives = getCosmeticDirectives(item)

		animator.setPartTag("back_cosmetic", "cosmeticDirectives", directives or "" )
		animator.setPartTag("back_cosmetic", "partImage", fixFilepath(item.config[self.gender.."Frames"], item) or "" )

		setCosmetic.back_addon(cosmetic, item, directives)
	else
		currentCosmeticName.back = nil
		setCosmetic.back_clear(cosmetic)
	end
end
function setCosmetic.back_addon(cosmetic, item, directives)
end
function setCosmetic.back_clear(cosmetic)
	animator.setPartTag("back_cosmetic", "partImage", "" )
end

function fixFilepath(string, item)
	if string ~= nil then
		if string[1] == "/" then
			return string
		else
			return item.directory..string
		end
	else
		return
	end
end

function getCosmeticDirectives(item)
	local colors = item.config.colorOptions
	local index = ((item.parameters.colorIndex or 1) % #colors) + 1
	local colorReplaceString = ""
	for color, replace in pairs(colors[index]) do
		colorReplaceString = colorReplaceString.."?replace;"..color.."="..replace
	end
	return colorReplaceString
end

function updateAnims(dt)
	for statename, state in pairs(self.animStateData) do
		state.animationState.time = state.animationState.time + dt
		local ended, times, time = hasAnimEnded(statename)
		if (not ended) or (state.animationState.mode == "loop") then
			state.animationState.frame = math.floor( time * state.animationState.speed ) + 1
			animator.setGlobalTag( statename.."Frame", state.animationState.frame or 1 )
		end
	end

	offsetAnimUpdate()
	rotationAnimUpdate()
	--armRotationUpdate()

	animator.setGlobalTag( "directives", getDirectives() )

	for statename, state in pairs(self.animStateData) do
		if state.animationState.time >= state.animationState.cycle then
			endAnim(state, statename)
		end
	end
end

function endAnim(state, statename)
	for _, func in pairs(self.animFunctionQueue[statename]) do
		func()
	end
	self.animFunctionQueue[statename] = {}

	if (state.tag ~= nil) and state.tag.reset then
		if state.tag.part == "global" then
			animator.setGlobalTag( state.tag.name, "" )
		else
			animator.setPartTag( state.tag.part, state.tag.name, "" )
		end
		state.tag = nil
	end
end

function checkHumanoidAnim()
	local portrait = world.entityPortrait(entity.id(), "full")
	local gotEmote
	for _, part in ipairs(portrait) do
		local imageString = part.image
		-- check for doing an emote animation
		if not gotEmote then
			local found1, found2 = imageString:find("/emote.png:")
			if found1 ~= nil then
				local found3, found4 = imageString:find(".1", found2, found2+10 )
				if found3 ~= nil then
					doAnim("emoteState", imageString:sub(found2+1, found3-1))
					gotEmote = true
				end
			end
		end
	end

	animator.resetTransformationGroup("sitrotation")
	if self.loungingIn ~= nil then
		local sitOrLay = world.getObjectParameter(self.loungingIn, "sitOrientation") or "sit"
		animator.setGlobalTag("state", sitOrLay)
		doAnims(self.speciesData.animations[sitOrLay])
		return
	end

	if mcontroller.onGround() then
		if mcontroller.walking() then movement.walking() return end
		if mcontroller.running() then movement.running() return end
		if mcontroller.crouching() then movement.crouching() return end
		movement.idle() return
	end
	if mcontroller.liquidMovement() then movement.liquidMovement() return end
	if mcontroller.jumping() then movement.jumping() return end
	if mcontroller.falling() then movement.falling() return end
	if mcontroller.flying() then movement.fly() return end
end

movement = {}

function movement.idle()
	doAnims(self.speciesData.animations.idle)
end

function movement.walking()
	doAnims(self.speciesData.animations.walk)
end

function movement.running()
	doAnims(self.speciesData.animations.run)
end

function movement.crouching()
	doAnims(self.speciesData.animations.duck)
end

function movement.liquidMovement()
	doAnims(self.speciesData.animations.swim)
end

function movement.jumping()
	doAnims(self.speciesData.animations.jump)
end

function movement.falling()
	doAnims(self.speciesData.animations.fall)
end

function movement.flying()
	doAnims(self.speciesData.animations.fly)
end

function doAnims( anims, force )
	for state,anim in pairs( anims or {} ) do
		if state == "offset" then
			offsetAnim( anim )
		elseif state == "rotate" then
			rotate( anim )
		elseif state == "tags" then
			setAnimTag( anim )
		elseif state == "priority" then
			changePriorityLength( anim )
		elseif state == "hitbox" then
		elseif state == "state" then
			animator.setGlobalTag("state", anim)
		else
			doAnim( state.."State", anim, force)
		end
	end

	self.hitbox = ( (anims or {}).hitbox or self.speciesData.animations.idle.hitbox )
end

function doAnim( state, anim, force)
	local oldPriority = (self.animStateData[state].animationState or {}).priority or 0
	local newPriority = (self.animStateData[state].states[anim] or {}).priority or 0
	local isSame = (self.animStateData[state].animationState or {}).anim == anim
	local force = force
	local priorityHigher = ((newPriority >= oldPriority) or (newPriority == -1))
	if (not isSame and priorityHigher) or hasAnimEnded(state) or force then
		if isSame then
			local mode = self.animStateData[state].animationState.mode
			if mode == "end" then
				force = true
			elseif mode == "loop" then
				return
			end
		end
		self.animStateData[state].animationState = {
			anim = anim,
			priority = newPriority,
			cycle = self.animStateData[state].states[anim].cycle,
			frames = self.animStateData[state].states[anim].frames,
			mode = self.animStateData[state].states[anim].mode,
			speed = self.animStateData[state].states[anim].frames / self.animStateData[state].states[anim].cycle,
			frame = 1,
			time = 0
		}
		animator.setGlobalTag( state.."Frame", 1 )
		animator.setGlobalTag( state.."Anim", self.animStateData[state].states[anim].animFrames or anim )

		animator.setAnimationState(state, self.animStateData[state].states[anim].baseAnim or anim, force)
	end
end

function queueAnimEndFunction(state, func, newPriority)
	if newPriority then
		self.animStateData[state].animationState.priority = newPriority
	end
	table.insert(self.animFunctionQueue[state], func)
end

function setAnimTag(anim)
	for _,tag in ipairs(anim) do
		self.animStateData[tag.owner.."State"].tag = {
			part = tag.part,
			name = tag.name,
			reset = tag.reset or true
		}
		if tag.part == "global" then
			animator.setGlobalTag( tag.name, tag.value )
		else
			animator.setPartTag( tag.part, tag.name, tag.value )
		end
	end
end

function changePriorityLength(anim)
	for state, data in pairs(anim) do
		self.animStateData[state.."State"].animationState.priority = data[1] or self.animStateData[state.."State"].animationState.priority
		self.animStateData[state.."State"].animationState.cycle = data[2] or self.animStateData[state.."State"].animationState.cycle
	end
end

function offsetAnim( data )
	if data == self.offsets.data then
		if not self.offsets.enabled and self.offsets.continue then self.offsets.enabled = true end
		return
	else
		for i, part in ipairs(self.offsets.parts) do
			for j, group in ipairs(part.groups) do
				animator.resetTransformationGroup(group)
			end
		end
	end

	self.offsets = {
		enabled = data ~= nil,
		data = data,
		parts = {},
		loop = data.loop or false,
		timing = data.timing or "body"
	}
	local continue = false
	for _, part in ipairs(data.parts or {}) do
		table.insert(self.offsets.parts, {
			x = part.x or {0},
			y = part.y or {0},
			groups = part.groups or {"headbob"},
			})
		if (part.x and #part.x > 1) or (part.y and #part.y > 1) then
			continue = true
		end
	end
	self.offsets.continue = true
	offsetAnimUpdate()
	if not continue then
		self.offsets.continue = false
		self.offsets.enabled = false
	end
end

function rotate( data )
	if data == self.rotating.data and self.rotating.enabled then return
	else
		for i, part in ipairs(self.rotating.parts) do
			for j, group in ipairs(part.groups) do
				animator.resetTransformationGroup(group)
			end
		end
	end

	self.rotating = {
		enabled = data ~= nil,
		data = data,
		frames = data.frames,
		parts = {},
		loop = data.loop or false,
		timing = data.timing or "body",

		frame = 1,
		index = 2,
		prevFrame = 0,
		prevIndex = 1

	}
	local continue = false
	for _, r in ipairs(data.parts or {}) do
		table.insert(self.rotating.parts, {
			groups = r.groups or {"frontarmsrotation"},
			center = r.center or {0,0},
			rotation = r.rotation or {0},
			last = r.rotation[1] or 0
		})
		if r.rotation and #r.rotation > 1 then
			continue = true
		end
	end
	rotationAnimUpdate()
	if not continue then
		self.rotating.enabled = false
	end
end

function offsetAnimUpdate()
	if self.offsets == nil or not self.offsets.enabled then return end
	local state = self.offsets.timing.."State"
	local ended, times, time = hasAnimEnded(state)
	if ended and not self.offsets.loop then self.offsets.enabled = false end

	for _,r in ipairs(self.offsets.parts) do
		local x = r.x[ self.animStateData[state].animationState.frame ] or r.x[#r.x] or 0
		local y = r.y[ self.animStateData[state].animationState.frame ] or r.y[#r.y] or 0
		for i = 1, #r.groups do
			animator.resetTransformationGroup( r.groups[i] )
			animator.translateTransformationGroup( r.groups[i], { x / 8, y / 8 } )
		end
	end
end

function rotationAnimUpdate()
	if self.rotating == nil or not self.rotating.enabled then return end
	local state = self.rotating.timing.."State"
	local ended, times, time = hasAnimEnded(state)
	if ended and not self.rotating.loop then self.rotating.enabled = false end
	local speed = self.animStateData[state].animationState.speed
	local frame = self.animStateData[state].animationState.frame
	local index = frame + 1
	local nextFrame = frame + 1
	local nextIndex = index + 1

	if self.rotating.prevFrame ~= frame then
		if self.rotating.frames ~= nil then
			for i = 1, #self.rotating.frames do
				if (self.rotating.frames[i] == frame) then
					self.rotating.prevFrame = frame
					self.rotating.prevIndex = i

					self.rotating.frame = self.rotating.frames[i + 1] or frame + 1
					self.rotating.index = i + 1
				end
				if self.rotating.loop and (i == #self.rotating.frames) then
					self.rotating.prevFrame = frame
					self.rotating.prevIndex = i

					self.rotating.frame = 0
					self.rotating.index = 1
				end
			end
		else
			self.rotating.prevFrame = self.rotating.frame
			self.rotating.frame = nextFrame

			self.rotating.prevIndex = self.rotating.index
			self.rotating.index = nextIndex
		end
	end

	local currTime = time * speed
	local progress = (currTime - self.rotating.prevFrame)/(math.abs(self.rotating.frame - self.rotating.prevFrame))

	for _, r in ipairs(self.rotating.parts) do
		local previousRotation = r.rotation[self.rotating.prevIndex] or r.last
		local nextRotation = r.rotation[self.rotating.index] or previousRotation
		local rotation = previousRotation + (nextRotation - previousRotation) * progress
		r.last = previousRotation

		for _, group in ipairs(r.groups) do
			animator.resetTransformationGroup( group )
			animator.rotateTransformationGroup( group, (rotation * math.pi/180), r.center)
		end
	end
end


function hasAnimEnded(state)
	local ended = (self.animStateData[state].animationState.time >= self.animStateData[state].animationState.cycle)
	local times = math.floor(self.animStateData[state].animationState.time/self.animStateData[state].animationState.cycle)
	local currentCycle = (self.animStateData[state].animationState.time - (self.animStateData[state].animationState.cycle*times))
	return ended, times, currentCycle
end


function getDirectives()
	local directivesList = status.statusProperty("speciesAnimOverrideDirectives") or {}
	local directives = ""
	for _, directive in pairs(directivesList) do
		directives = directives.."?"..directive
	end
	return directives
end
