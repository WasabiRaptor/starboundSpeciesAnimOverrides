require("/scripts/poly.lua")
require("/scripts/vec2.lua")
require("/scripts/speciesAnimOverride_validateIdentity.lua")
armsToArm = {
	frontarms = "frontArm",
	backarms = "backArm"
}
beamMinerImage = "/items/tools/miningtools/beamaxe.png"
beamMinerOffset = {-2, 0}
setCosmetic = {}
movement = {}
currentCosmeticName = {}
equipmentChanged = false
refreshCosmetics = true
falling = false

function init()
	self.loopedMessages = {}
	self.timerList = {}
	self.rpcList = {}
	self.offsets = {enabled = false, parts = {}}
	self.rotating = {enabled = false, parts = {}}
	self.scaling = {enabled = false, parts = {}}
	self.animStateData = root.assetJson("/stats/speciesAnimOverride/" .. config.getParameter("animationConfig")).animatedParts.stateTypes
	self.animTransformGroups = root.assetJson("/stats/speciesAnimOverride/"..config.getParameter("animationConfig")).transformationGroups
	self.animFunctionQueue = {}
	self.parts = {}
	self.globalTagDefaults = root.assetJson("/stats/speciesAnimOverride/"..config.getParameter("animationConfig")).globalTagDefaults or {}
	self.armData = {
		frontArmOffsetData = {
			handPosition = {0,0},
			rotationCenter = {0,0}
		},
		backArmOffsetData = {
			handPosition = {0,0},
			rotationCenter = {0,0}
		}
	}

	self.settings = sb.jsonMerge(status.statusProperty("speciesAnimOverrideSettings") or {}, status.statusProperty("speciesAnimOverrideOverrideSettings") or {})

	message.setHandler("speciesAnimOverrideRefreshSettings", function (_,_, settings)
		self.settings = settings
	end)

	message.setHandler("refreshAnimOverrides", function(_, _)
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

			animator.setAnimationState(statename, state.default, true)
			animator.setGlobalTag(statename.."Frame", 1)
			animator.setGlobalTag(statename.."Anim", state.default)
		end
		for partname, string in pairs(self.parts) do
			animator.setPartTag(partname, "partImage", "")
			animator.setPartTag(partname, "colorRemap", "")
			self.parts[partname] = nil
		end
		for name, transformGroup in pairs( self.animTransformGroups or {} ) do
			animator.resetTransformationGroup(name)
		end
		refreshCosmetics = true
		currentCosmeticName = {}
		self.overrideData = status.statusProperty("speciesAnimOverrideData") or {}
		initAfterInit()
	end)

	message.setHandler("setAnimOverridesLoungeAnim", function (anim)
		self.loungeAnim = anim
	end)

	message.setHandler("AORefreshClothesNow", function()
		addRPC(world.sendEntityMessage(entity.id(), "animOverrideGetEquipsAndLounge"), function (data)
			readCosmeticItemData(data)
			self.loungingIn = data.lounging
		end)
	end)

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

	beamMinerImage = status.statusProperty("beamMinerImage") or beamMinerImage

	effect.setParentDirectives("crop;0;0;0;0")
	self.overrideData = status.statusProperty("speciesAnimOverrideData") or {}

	if status.statusProperty("animOverridesStoredPortrait") then
		initAfterInit(true)
		local equipment = status.statusProperty("animOverridesStoredEquipment")
		if equipment then
			readCosmeticItemData(equipment)
		end
	end

	message.setHandler("animOverrideScale", function(_, _, ...)
		animOverrideScale(...)
	end)
	if self.scale == nil then
		self.scale = status.statusProperty("animOverrideScale") or 1
	end
	self.oldScale = self.scale
	self.scaleDuration = 0
	self.scaleTime = 0
end

local doNotRedraw
function initAfterInit(inInit)
	local originalSpecies = status.statusProperty("animOverridesStoredSpecies") or world.entitySpecies(entity.id())
	self.species = self.overrideData.species or status.statusProperty("animOverridesStoredSpecies") or world.entitySpecies(entity.id())
	self.gender = self.overrideData.gender or status.statusProperty("animOverridesStoredGender") or world.entityGender(entity.id())
	self.identity = self.overrideData.identity or {}
	validateIdentity(self.identity)
	local blacklist = root.assetJson("/animOverrideBlacklist.config")

	if self.settings.noSpriteRedraw or (originalSpecies ~= nil and blacklist[originalSpecies]) then
		effect.setParentDirectives("")
		animator.setGlobalTag("directives", "crop;0;0;0;0")
		status.setStatusProperty("speciesAnimOverrideData", {})
		doNotRedraw = true
	else
		if self.species ~= nil and blacklist[self.species] then
			self.species = originalSpecies
			self.identity = {}
		end
		doNotRedraw = false
		effect.setParentDirectives("crop;0;0;0;0")
	end
	if not inInit then
		world.sendEntityMessage(entity.id(), "giveAnimOverrideAimTech" )
	else
		timer("techMessage", 0.5, function () world.sendEntityMessage(entity.id(), "giveAnimOverrideAimTech" ) end)
	end

	self.speciesFile = root.assetJson("/species/"..self.species..".species") or {}
	self.bodyconfig = root.assetJson("/humanoid.config")
	local speciesData
	if self.speciesFile.speciesAnimOverride ~= nil then
		if self.speciesFile.speciesAnimOverride:sub(1,1) == "/" then
			speciesData = root.assetJson(self.speciesFile.speciesAnimOverride)
		else
			speciesData = root.assetJson("/humanoid/"..self.species.."/"..self.speciesFile.speciesAnimOverride)
		end
	else
		speciesData = root.assetJson("/humanoid/speciesAnimOverride.config")
	end
	if self.overrideData.humanoidConfig then
		self.bodyconfig = sb.jsonMerge(self.bodyconfig, root.assetJson(self.overrideData.humanoidConfig))
	elseif self.speciesFile.humanoidConfig ~= nil then
		self.bodyconfig = sb.jsonMerge(self.bodyconfig, root.assetJson(self.speciesFile.humanoidConfig))
	end

	self.originalSpeciesFile = root.assetJson("/species/"..originalSpecies..".species") or {}
	self.originalSpeciesBodyConfig = root.assetJson("/humanoid.config")
	if self.originalSpeciesFile.humanoidConfig ~= nil then
		originalSpeciesBodyConfig = sb.jsonMerge(originalSpeciesBodyConfig, root.assetJson(self.originalSpeciesFile.humanoidConfig))
	end

	self.settings = sb.jsonMerge(self.speciesFile.animOverrideDefaultSettings or {}, self.settings)

	local mergeConfigs = speciesData.merge or {}
	local configs = { speciesData }
	while type(mergeConfigs[#mergeConfigs]) == "string" do
		local insertPos = #mergeConfigs
		local newConfig = root.assetJson(mergeConfigs[#mergeConfigs])
		for i = #(newConfig.merge or {}), 1, -1 do
			table.insert(mergeConfigs, insertPos, newConfig.merge[i])
		end

		table.insert(configs, 1, newConfig)

		table.remove(mergeConfigs, #mergeConfigs)
	end

	local scripts = {}
	local finalConfig = {}
	for i, config in ipairs(configs) do
		finalConfig = sb.jsonMerge(finalConfig, config)
		for j, script in ipairs(config.scripts or {}) do
			table.insert(scripts, script)
		end
	end
	self.speciesData = finalConfig
	self.speciesData.scripts = scripts

	require("/stats/speciesAnimOverride/speciesAnimOverrideScripts.lua")
	for _, script in ipairs(self.speciesData.scripts) do
		require(script)
	end

	animator.resetTransformationGroup("handoffset")
	animator.resetTransformationGroup("globalOffset")
	local handoffset = vec2.div(self.bodyconfig.frontHandPosition, 8)
	animator.translateTransformationGroup("handoffset", handoffset)
	animator.translateTransformationGroup("globalOffset", {((self.bodyconfig.globalOffset or {})[1] or 0)/8, ((self.bodyconfig.globalOffset or {})[2] or 0)/8})
	local frontOffset = vec2.div(self.bodyconfig.frontArmOffset or {0,0}, 8)
	local backOffset = vec2.div(self.bodyconfig.backArmOffset or {0,0}, 8)


	self.armData.frontArmOffsetData = {
		handPosition = vec2.add(handoffset, frontOffset),
		rotationCenter = vec2.add(vec2.div(self.bodyconfig.frontArmRotationCenter, 8), frontOffset)
	}
	self.armData.backArmOffsetData = {
		handPosition = vec2.add(handoffset, backOffset),
		rotationCenter = vec2.add(vec2.div(self.bodyconfig.backArmRotationCenter, 8), backOffset)
	}
	status.setStatusProperty("frontarmAnimOverrideArmOffset", self.armData.frontArmOffsetData)
	status.setStatusProperty("backarmAnimOverrideArmOffset", self.armData.backArmOffsetData)

	for name, offset in pairs( self.speciesData.offsets or {} ) do
		animator.resetTransformationGroup(name)
		animator.translateTransformationGroup(name, {offset[1]/8, offset[2]/8})
	end

	self.playerMovementParams = sb.jsonMerge(root.assetJson("/default_actor_movement.config"), root.assetJson("/player.config").movementParameters)
	self.playerMovementParams.standingPoly = nil
	self.playerMovementParams.crouchingPoly = nil
	self.zeroGMovementParams = root.assetJson("/player.config").zeroGMovementParameters
	if not self.speciesData.animations.idle.controlParameters then
		self.speciesData.animations.idle.controlParameters = sb.jsonMerge((self.bodyconfig.movementParameters or {}), self.playerMovementParams)
		self.speciesData.animations.idle.controlParameters.collisionPoly = sb.jsonMerge({}, self.bodyconfig.movementParameters.standingPoly)
		self.speciesData.animations.idle.controlParameters.standingPoly = nil
		self.speciesData.animations.idle.controlParameters.crouchingPoly = nil
	end
	if not self.speciesData.animations.sit.controlParameters then
		self.speciesData.animations.sit.controlParameters = sb.jsonMerge((self.bodyconfig.movementParameters or {}), self.playerMovementParams)
		self.speciesData.animations.sit.controlParameters.collisionPoly = sb.jsonMerge({}, self.bodyconfig.movementParameters.standingPoly)
		self.speciesData.animations.sit.controlParameters.standingPoly = nil
		self.speciesData.animations.sit.controlParameters.crouchingPoly = nil
	end
	if not self.speciesData.animations.lay.controlParameters then
		self.speciesData.animations.lay.controlParameters = sb.jsonMerge((self.bodyconfig.movementParameters or {}), self.playerMovementParams)
		self.speciesData.animations.lay.controlParameters.collisionPoly = sb.jsonMerge({}, self.bodyconfig.movementParameters.standingPoly)
		self.speciesData.animations.lay.controlParameters.standingPoly = nil
		self.speciesData.animations.lay.controlParameters.crouchingPoly = nil
	end
	if not self.speciesData.animations.duck.controlParameters then
		self.speciesData.animations.duck.controlParameters = sb.jsonMerge((self.bodyconfig.movementParameters or {}), self.playerMovementParams)
		self.speciesData.animations.duck.controlParameters.collisionPoly = sb.jsonMerge({}, self.bodyconfig.movementParameters.crouchingPoly)
		self.speciesData.animations.duck.controlParameters.standingPoly = nil
		self.speciesData.animations.duck.controlParameters.crouchingPoly = nil
	end
	if not self.speciesData.animations.duck.duckOffset then
		self.speciesData.animations.duck.duckOffset = self.bodyconfig.duckOffset/8
	end

	for animTableName, anims in pairs(self.speciesData.animations) do
		local animsTable = self.speciesData.animations.idle
		local currentScale = self.currentScale or 1
		if (anims or {}).controlParameters then
			animsTable = anims
		end
		self.duckOffset = (anims or {}).duckOffset or 0
		if not animsTable.scaledControlParameters then
			animsTable.scaledControlParameters = {}
		end
		if not animsTable.scaledControlParameters[currentScale] then
			createScaledHitbox(anims, animsTable, currentScale)
		end
	end

	if type(self.speciesFile) == "table" then
		for i, data in ipairs(self.speciesFile.genders or {}) do
			if data.name == (status.statusProperty("animOverridesStoredGender") or world.entityGender(entity.id())) then
				self.identity.hairGroup = ((self.identity.hairGroup ~= "") and self.identity.hairGroup) or ((data.hairGroup ~= "") and data.hairGroup) or "hair"
				self.identity.facialHairGroup = ((self.identity.facialHairGroup ~= "") and self.identity.facialHairGroup) or ((data.facialHairGroup ~= "") and data.facialHairGroup) or "facialHair"
				self.identity.facialMaskGroup = ((self.identity.facialMaskGroup ~= "") and self.identity.facialMaskGroup) or ((data.facialMaskGroup ~= "") and data.facialMaskGroup) or "facialMask"
			end
		end
	end

	local portrait = status.statusProperty("animOverridesStoredPortrait")
	if not portrait then
		portrait = world.entityPortrait(entity.id(), "full")
		status.setStatusProperty("animOverridesStoredGender", world.entityGender(entity.id()))
		status.setStatusProperty("animOverridesStoredSpecies", world.entitySpecies(entity.id()))
		status.setStatusProperty("animOverridesStoredPortrait", portrait)
	end

	local gotOffsets
	for _, part in ipairs(portrait) do
		local imageString = part.image

		if not self.identity.imagePath and not self.overrideData.species then
			local found1, found2 = imageString:find("humanoid/")
			if type(found1) == "number" and type(found2) == "number" then
				local found3, found4 = imageString:find("/"..status.statusProperty("animOverridesStoredGender") or world.entityGender(entity.id()).."body")
				if type(found3) == "number" and type(found4) == "number" then
					self.identity.imagePath = imageString:sub(found2+1, found3-1)
				end
			end
		else
			self.identity.imagePath = self.species
		end

		--get personality values
		if (not self.identity.body) or (not self.identity.bodyDirectives) then
			local found1, found2 = imageString:find("body.png:idle.")
			if type(found1) == "number" and type(found2) == "number" then
				self.identity.body = self.identity.body or imageString:sub(found2+1, found2+1)

				local found3 = imageString:find("?")
				local directives = imageString:sub(found3)
				self.identity.bodyDirectives = self.identity.bodyDirectives or directives
			end
		end
		if not self.identity.emoteDirectives then
			local found1, found2 = imageString:find("emote.png")
			if type(found1) == "number" and type(found2) == "number" then
				local found3 = imageString:find("?")
				local directives = imageString:sub(found3)
				self.identity.emoteDirectives = self.identity.emoteDirectives or directives
			end
		end
		if not self.identity.arm then
			local found1, found2 = imageString:find("backarm.png:idle.")
			if type(found1) == "number" and type(found2) == "number" then
				self.identity.arm = imageString:sub(found2+1, found2+1)
			end
		end

		if (not self.identity.hairType) or (not self.identity.hairDirectives) then
			local found1, found2 = imageString:find("/"..(self.identity.hairGroup or "hair").."/")
			if type(found1) == "number" and type(found2) == "number" then
				local found3, found4 = imageString:find(".png:normal")
				self.identity.hairType = self.identity.hairType or imageString:sub(found2+1, found3-1)

				local found5, found6 = imageString:find("?addmask=")
				local directives = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha

				self.identity.hairDirectives = self.identity.hairDirectives or directives
			end
		end

		if (not self.identity.facialHairType) or not (self.identity.facialHairDirectives) then
			local found1, found2 = imageString:find("/"..(self.identity.facialHairGroup or "facialHair").."/")
			if type(found1) == "number" and type(found2) == "number" then
				found3, found4 = imageString:find(".png:normal")
				self.identity.facialHairType = self.identity.facialHairType or imageString:sub(found2+1, found3-1)

				local found5, found6 = imageString:find("?addmask=")
				local directives = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha
				self.identity.facialHairDirectives = self.identity.facialHairDirectives or directives
			end
		end

		if (not self.identity.facialMaskType) or (not self.identity.facialMaskDirectives) then
			local found1, found2 = imageString:find("/"..(self.identity.facialMaskGroup or "facialMask").."/")
			if type(found1) == "number" and type(found2) == "number" then
				found3, found4 = imageString:find(".png:normal")
				self.identity.facialMaskType = self.identity.facialMaskType or imageString:sub(found2+1, found3-1)

				local found5, found6 = imageString:find("?addmask=")
				local directives = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha
				self.identity.facialMaskDirectives = self.identity.facialMaskDirectives or directives
			end
		end

		if not gotOffsets and (self.identity.body ~= nil) and (self.identity.arm ~= nil) then
			local bodyIdle = "idle."..self.identity.body
			local armIdle = "idle."..self.identity.arm

			gotOffsets = true

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
	self.overrideData.species = self.species
	self.overrideData.gender = self.gender
	self.overrideData.identity = self.identity
	status.setStatusProperty("speciesAnimOverrideData", self.overrideData)
	timer("persistentEffects", 0.5, function ()
		status.setPersistentEffects("species", self.speciesFile.statusEffects or {})
	end)
	addDirectives()
	local fb = ""
	if (self.speciesFile.humanoidOverrides or {}).bodyFullbright then
		fb = "?multiply=FFFFFFfe"
	end
	animator.setGlobalTag("customDirectives", (self.overrideData.directives or ""))
	animator.setGlobalTag("bodyDirectives", (self.identity.bodyDirectives or "")..fb)
	animator.setPartTag("hair", "bodyDirectives", (self.identity.hairDirectives or self.identity.bodyDirectives or "")..fb)
	animator.setPartTag("hair_fg", "bodyDirectives", (self.identity.hairDirectives or self.identity.bodyDirectives or "")..fb)
	animator.setPartTag("facialHair", "bodyDirectives", (self.identity.facialHairDirectives or self.identity.bodyDirectives or "")..fb)
	animator.setPartTag("facialMask", "bodyDirectives", (self.identity.facialMaskDirectives or self.identity.bodyDirectives or "")..fb)
	animator.setPartTag("emote", "bodyDirectives", (self.identity.emoteDirectives or self.identity.bodyDirectives or "")..fb)

	animator.setGlobalTag( "bodyPersonality", self.identity.body )
	for i, data in ipairs( ((self.speciesData.personalityOffsets or {}).bodyOffsets or {})[self.identity.body] or {} ) do
		table.insert(self.speciesData.animations.idle.offset.parts, data)
	end

	animator.setGlobalTag( "backarmPersonality", self.identity.arm )
	animator.setGlobalTag( "frontarmPersonality", self.identity.arm )

	for tagname, string in pairs(self.speciesData.globalTagDefaults or {}) do
		local part = replaceSpeciesGenderTags(string)
		self.globalTagDefaults[tagname] = part
		animator.setGlobalTag(tagname, part)
	end
	for partname, string in pairs(self.speciesData.partImages or {}) do
		local set = false
		if type(string) == "string" then
			local part = replaceSpeciesGenderTags(string)
			local success, notEmpty = pcall(root.nonEmptyRegion, (part))
			if success and notEmpty ~= nil then
				setPartImage(partname, part)
				set = true
			end
		end
		if not set then
			animator.setPartTag(partname, "partImage", "")
			animator.setPartTag(partname, "colorRemap", "")
			self.parts[partname] = nil
		end
	end
	for partname, remapPart in pairs(self.speciesData.remapParts or {}) do
		if not self.parts[partname] then
			local part = replaceSpeciesGenderTags((self.speciesData.partImages or {})[partname] or ("/humanoid/<species>/"..partname..".png"), remapPart.imagePath or remapPart.species, remapPart.reskin)
			local success2, baseColorMap = pcall(root.assetJson, "/species/" .. (remapPart.species or "human") .. ".species:baseColorMap")
			local colorRemap
			if success2 and baseColorMap ~= nil and remapPart.remapColors and self.speciesFile.baseColorMap then
				colorRemap = remapBaseColors(remapPart.remapColors, baseColorMap, self.speciesFile.baseColorMap)
			end
			setPartImage(partname, part, colorRemap)
		end
	end
	for partname, data in pairs(self.speciesData.partTagDefaults or {}) do
		for tagname, string in pairs(data) do
			local part = replaceSpeciesGenderTags(string)
			animator.setPartTag(partname, tagname, part)
		end
	end

	timer("getInitEquips", 0, function()
		addRPC(world.sendEntityMessage(entity.id(), "animOverrideGetEquipsAndLounge"), function (data)
			readCosmeticItemData(data)
			self.loungingIn = data.lounging
		end)
		movement.idle()
		scaleUpdated(0)
	end)

	self.inited = true
end

function remapBaseColors(remapColors, baseColorMapFrom, baseColorMapTo)
	colorRemap = "?replace"
	for _, data in ipairs(remapColors) do
		if not data[1] then
			if not data.check or data.check and checkSettings(self.settings, data.check) then
				for color, replace in pairs(data or {}) do
					if type(replace) == "string" then
						colorRemap = colorRemap .. ";" .. color .. "=" .. replace
					end
				end
				colorRemap = colorRemap .. "?replace"
			end
		else
			local from = baseColorMapFrom[data[1]]
			local to = baseColorMapTo[data[2]]
			local check = data[3]
			if (not check) or check and checkSettings(self.settings, check) then
				if from and to then
					for i, color in ipairs(from or {}) do
						colorRemap = colorRemap .. ";" .. color .. "=" .. (to[i] or to[#to])
					end
				end
			end
		end
	end
	return colorRemap
end

function resetPart(partname)
	local partPath = (self.speciesData.partImages or {})[partname]

	animator.setPartTag(partname, "partImage", "")
	animator.setPartTag(partname, "colorRemap", "")
	self.parts[partname] = nil

	if type(partPath) == "string" then
		local part = replaceSpeciesGenderTags(partPath)
		local success, notEmpty = pcall(root.nonEmptyRegion, (part))
		if success and notEmpty ~= nil then
			setPartImage(partname, part)
		end
	end
	local remapPart = (self.speciesData.remapParts or {})[partname]
	if type(remapPart) == "table" then
		if not self.parts[partname] then
			local part = replaceSpeciesGenderTags((self.speciesData.partImages or {})[partname] or ("/humanoid/<species>/"..partname..".png"), remapPart.imagePath or remapPart.species, remapPart.reskin)
			local success2, baseColorMap = pcall(root.assetJson, "/species/" .. (remapPart.species or "human") .. ".species:baseColorMap")
			local colorRemap
			if success2 and baseColorMap ~= nil and remapPart.remapColors and self.speciesFile.baseColorMap then
				colorRemap = remapBaseColors(remapPart.remapColors, baseColorMap, self.speciesFile.baseColorMap)
			end
			setPartImage(partname, part, colorRemap)
		end
	end
	local partTags = (self.speciesData.partTagDefaults or {})[partname]
	if type(partTags) == "table" then
		for tagname, string in pairs(partTags) do
			local part = replaceSpeciesGenderTags(string)
			animator.setPartTag(partname, tagname, part)
		end
	end
end


function setPartImage(partname, partImage, colorRemap, customDirectives, tagDefaults)
	animator.setPartTag(partname, "partImage", partImage)
	animator.setPartTag(partname, "colorRemap", colorRemap or "")
	self.parts[partname] = partImage
	if not (tagDefaults or self.speciesData.globalTagDefaults or {})[partname .. "Mask"] then
		self.globalTagDefaults[partname .. "Mask"] = partImage
		animator.setGlobalTag(partname .. "Mask", partImage)
	end
	animator.setPartTag(partname, "customDirectives", customDirectives or self.overrideData.directives or "")
end

function addDirectives()
end

function replaceSpeciesGenderTags(string, speciesPath, reskinPath)
	return sb.replaceTags(string, { gender = self.gender, species = (speciesPath or self.identity.imagePath or "any"), reskin = (reskinPath or self.reskin or ""),
		hair = (self.identity.hairType or "0"), hairGroup = (self.identity.hairGroup or "hair"),
		facialHair = (self.identity.facialHairType or "0"), facialHairGroup = (self.identity.facialHairGroup or "facialHair"),
		facialMask = (self.identity.facialMaskType or "0"), facialMaskGroup = (self.identity.facialMaskGroup or "facialMask"),
	})
end

function update(dt)

	local direction = mcontroller.facingDirection()
	animator.setFlipped(direction == -1)
	self.direction = direction * mcontroller.movingDirection()
	animator.setGlobalTag("direction", self.direction )

	if (not self.inited) then
		initAfterInit()
	else
		doUpdate(dt)
	end
end

function doUpdate(dt)


	self.lastScale = self.currentScale
	self.scaleTime = self.scaleTime + dt
	if self.scaleTime < self.scaleDuration then
		self.currentScale = self.oldScale + (self.scale - self.oldScale) * (self.scaleTime / self.scaleDuration)
	else
		self.currentScale = self.scale or 1
	end

	if doNotRedraw then
		self.lastScale = 1
		self.oldScale = 1
		self.currentScale = 1
		self.duckOffset = 0
		updateAnimsNoRedraw(dt)
		checkRPCsFinished(dt)
		checkTimers(dt)
		checkHumanoidAnimNoRedraw(dt)
	else
		updateAnims(dt)
		checkRPCsFinished(dt)
		checkTimers(dt)

		getCosmeticItems()
		getHandItems()
		checkHumanoidAnim(dt)
	end



	animator.resetTransformationGroup("globalRotation")
	animator.rotateTransformationGroup("globalRotation", mcontroller.rotation() * mcontroller.facingDirection())

	status.setStatusProperty("animOverridesCurrentScale", self.currentScale )
	if self.lastScale ~= self.currentScale then
		scaleUpdated(dt)
	end
	status.setStatusProperty("animOverridesDuckOffset", (self.duckOffset or 0) * (self.currentScale or 1))

	if self.controlParameters and not status.statusProperty("speciesAnimOverrideControlParams") then
		mcontroller.controlParameters(self.controlParameters)
		animator.resetTransformationGroup("globalScale")
		animator.scaleTransformationGroup("globalScale", {self.currentScale, self.currentScale})
		animator.translateTransformationGroup("globalScale", {self.controlParameters.xOffset or 0, self.controlParameters.yOffset or 0})
		status.setStatusProperty("animOverridesGlobalScaleYOffset", self.controlParameters.yOffset or 0)
	end
	status.setStatusProperty("speciesAnimOverrideControlParams", nil)
end

function uninit()
	status.setStatusProperty("beamMinerImage", beamMinerImage)
	world.sendEntityMessage(entity.id(), "removeAnimOverrideAimTech" )
end

function timedLoopedMessage(name, time, eid, message, args, callback, failCallback)
	return timer(name, time, function ()
		addRPC(world.sendEntityMessage(eid, message, table.unpack(args or {})), callback, failCallback)
	end)
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

function checkRPCsFinished(dt)
	for i, list in pairs(self.rpcList) do
		list.dt = list.dt + dt -- I think this is good to have, incase the time passed since the RPC was put into play is important
		if list.rpc:finished() then
			if list.rpc:succeeded() and list.callback ~= nil then
				list.callback(list.rpc:result(), list.dt)
			elseif list.failCallback ~= nil then
				list.failCallback(list.dt)
			end
			table.remove(self.rpcList, i)
		end
	end
end

function addRPC(rpc, callback, failCallback)
	if callback ~= nil or failCallback ~= nil  then
		table.insert(self.rpcList, {rpc = rpc, callback = callback, failCallback = failCallback, dt = 0})
	end
end

function randomTimer(name, min, max, callback)
	if name == nil or self.timerList[name] == nil then
		local timer = {
			targetTime = (math.random(min * 100, max * 100))/100,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			self.timerList[name] = timer
		else
			table.insert(self.timerList, timer)
		end
		return true
	end
end

function timer(name, time, callback)
	if name == nil or self.timerList[name] == nil then
		local timer = {
			targetTime = time,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			self.timerList[name] = timer
		else
			table.insert(self.timerList, timer)
		end
		return true
	end
end

function forceTimer(name, time, callback)
		local timer = {
			targetTime = time,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			self.timerList[name] = timer
		else
			table.insert(self.timerList, timer)
		end
		return true
end

function checkTimers(dt)
	for name, timer in pairs(self.timerList) do
		timer.currTime = timer.currTime + dt
		if timer.currTime >= timer.targetTime then
			if timer.callback ~= nil then
				timer.callback()
			end
			if type(name) == "number" then
				---@diagnostic disable-next-line: param-type-mismatch
				table.remove(self.timerList, name)
			else
				self.timerList[name] = nil
			end
		end
	end
end

function getHandItems()
	if self.settings.noHandItems then return end
	if mcontroller.facingDirection() < 0 then
		local continue = getHandItem("alt", "backarms", getHandItem("primary", "frontarms", {}) or {})
		if continue then
			doSecondHand("primary", "frontarms", continue)
		end
	else
		local continue = getHandItem("alt", "frontarms", getHandItem("primary", "backarms", {}) or {})
		if continue then
			doSecondHand("primary", "backarms", continue)
		end
	end
end

function getHandItem(hand, part, continue)

	local itemDescriptor = world.entityHandItemDescriptor(entity.id(), hand)
	clearAnimatedActiveItemTags(hand, part)

	if itemDescriptor ~= nil and continue.secondArmAngle == nil then
		local item = root.itemConfig(itemDescriptor)
		local itemType = root.itemType(itemDescriptor.name)
		if ( itemType == "activeitem" )
		and (not itemDescriptor.parameters or not itemDescriptor.parameters.itemHasOverrideLockScript) then
			loopedMessage("giveItemScript"..hand, entity.id(), "giveHeldItemOverrideLockScript", {itemDescriptor} )
			setEmptyHand(hand, part)
			return
		end

		if itemType == "activeitem" then
			local itemOverrideData = status.statusProperty(hand.."ItemOverrideData") or {}
			if itemOverrideData.setHoldingItem ~= false then
				local angle = (itemOverrideData.setArmAngle or 0 * math.pi / 180)
				rotationArmVisible(part)
				rotateArmAngle(part, angle)

				if item.config.animation then
					if itemOverrideData.setTwoHandedGrip then
						animator.setGlobalTag("frontarmsRotationFrame", itemOverrideData.setFrontArmFrame or "rotation")
						animator.setGlobalTag("backarmsRotationFrame", itemOverrideData.setBackArmFrame or "rotation")
						if part == "backarms" then
							return { secondArmAngle = angle, secondArmAnimatedItem = hand, itemOverrideData = itemOverrideData, itemDescriptor = itemDescriptor, item = item }
						else
							animatedActiveItem(item, itemDescriptor, itemOverrideData, hand, part, continue)
							return { secondArmAngle = angle }
						end
					else
						if part == "frontarms" then
							animator.setGlobalTag("frontarmsRotationFrame", itemOverrideData.setFrontArmFrame or "rotation")
						end
						if part == "backarms" then
							animator.setGlobalTag("backarmsRotationFrame", itemOverrideData.setBackArmFrame or "rotation")
						end
						animatedActiveItem(item, itemDescriptor, itemOverrideData, hand, part, continue)
						return
					end
				else
					local outside = ""
					if itemOverrideData.setOutsideOfHand then
						outside = "_outside"
					end

					local itemImage = fixFilepath(item.config.inventoryIcon, item)

					if itemOverrideData.setTwoHandedGrip then
						animator.setGlobalTag("frontarmsRotationFrame", itemOverrideData.setFrontArmFrame or "rotation")
						animator.setGlobalTag("backarmsRotationFrame", itemOverrideData.setBackArmFrame or "rotation")
						if part == "backarms" then
							return { secondArmAngle = angle, secondArmImage = itemImage, outside = outside }
						else
							animator.setPartTag(part .. "_item_0", "partImage", itemImage or "")
							animator.setAnimationState(part .. "_item_0", "item"..(outside), itemImage or "")
							return { secondArmAngle = angle }
						end
					else
						if part == "frontarms" then
							animator.setGlobalTag("frontarmsRotationFrame", itemOverrideData.setFrontArmFrame or "rotation")
						end
						if part == "backarms" then
							animator.setGlobalTag("backarmsRotationFrame", itemOverrideData.setBackArmFrame or "rotation")
						end
						animator.setPartTag(part .. "_item_0", "partImage", itemImage or "")
						animator.setAnimationState(part .. "_item_0", "item"..(outside), itemImage or "")
					end
				end
			else
				setEmptyHand(hand, part)
			end
		else
			if itemType == "object" or itemType == "material" or itemType == "liquid" then
				local aim = status.statusProperty("speciesAnimOverrideAim")
				if not aim then return end
				rotateAimArm(aim, part)
				local itemImage = beamMinerImage
				local offset = beamMinerOffset
				translateArmOffset(hand, part, offset)
				animator.setPartTag(part .. "_item_0", "partImage", itemImage or "")

				rotationArmVisible(part)
				return
			elseif item.config.image or item.config.inventoryIcon then
				local aim = status.statusProperty("speciesAnimOverrideAim")
				if not aim then return end
				local angle = rotateAimArm(aim, part)
				local itemImage = fixFilepath(item.config.image or item.config.inventoryIcon, item)
				local offset = item.config.handPosition or {0,0}
				if itemType == "inspectiontool" then
					offset[1] = offset[1]*8
					offset[2] = offset[2]*8
				end
				offset[1] = offset[1] * -1
				offset[2] = offset[2] * -1

				if itemType == "beamminingtool" then
					beamMinerImage = itemImage or beamMinerImage
					beamMinerOffset = offset
				end
				rotationArmVisible(part)

				if item.config.twoHanded then
					if part == "backarms" then
						return { secondArmAngle = angle, secondArmImage = itemImage, secondArmOffset = offset }
					else
						translateArmOffset(hand, part, offset)
						animator.setPartTag(part .. "_item_0", "partImage", itemImage or "")
						return { secondArmAngle = angle }
					end
				else
					translateArmOffset(hand, part, offset)
					animator.setPartTag(part .. "_item_0", "partImage", itemImage or "")
				end
			else
				setEmptyHand(hand, part)
			end
		end
	else
		doSecondHand(hand, part, continue)
	end
end

function doSecondHand(hand, part, continue)
	if continue.secondArmAngle then
		clearAnimatedActiveItemTags(hand, part)
		rotationArmVisible(part)
		rotateArmAngle(part, continue.secondArmAngle)
		if continue.secondArmOffset then
			translateArmOffset(hand, part, continue.secondArmOffset)
		end
		if continue.secondArmAnimatedItem then
			animatedActiveItem(continue.item, continue.itemDescriptor, continue.itemOverrideData, continue.secondArmAnimatedItem, part, continue)
		else
			animator.setPartTag(part .. "_item_0", "partImage", continue.secondArmImage or "")
			animator.setAnimationState(part .. "_item_0", "item"..(continue.outside or ""))
		end
	else
		setEmptyHand(hand, part)
	end
end

function translateArmOffset(hand, part, addOffset, number)
	local offset = self.bodyconfig[armsToArm[part].."Offset"] or {0,0}
	animator.resetTransformationGroup(part.."_item_"..(number or 0).."_offset")
	animator.translateTransformationGroup(part.."_item_"..(number or 0).."_offset", {(offset[1]+addOffset[1])/8, (offset[2]+addOffset[2])/8})
end

local itemImages = { primary = {}, alt = {} }
local usedParts = 0
local resetPart = {}
function animatedActiveItem(item, itemDescriptor, itemOverrideData, hand, part, continue)
	if self.settings.noAnimatedItems then return end

	local newItem = false
	local refreshImages = false
	if itemImages[hand].name ~= itemDescriptor.name then
		local animation = sb.jsonMerge( (root.assetJson(fixFilepath(item.config.animation, item)) or {}), (item.config.animationCustom or {}))

		itemImages[hand] = {
			name = itemDescriptor.name,
			animation = animation,
			tags = animation.globalTagDefaults,
			parts = {},
			partMap = {},
			partStates = {},
			transformationGroups = {}
		}
		for transformationGroup, data in pairs(animation.transformationGroups or {}) do
			itemImages[hand].transformationGroups[transformationGroup] = {}
		end

		local zlevels = {}
		local usedZlevels = {}
		for itemPart, data in pairs(itemImages[hand].animation.animatedParts.parts or {}) do
			local z = data.properties.zLevel or 0
			while usedZlevels[z] do z = z - 0.01 end
			usedZlevels[z] = true
			table.insert(zlevels, {z = z, name = itemPart})
		end
		table.sort(zlevels, function(a,b)
			return a.z < b.z
		end)
		for i,part in ipairs(zlevels) do
			usedParts = math.max(usedParts, (i-1))
			itemImages[hand].partMap[part.name] = i - 1
		end
		usedParts = math.min(usedParts, config.getParameter("itemAnimationLayers") or 10)

		newItem = true
		refreshImages = true
	end

	if not self.settings.noAnimatingItems then
		for stateType, data in pairs(itemImages[hand].animation.animatedParts.stateTypes or {}) do
			if newItem then
				itemImages[hand].partStates[stateType] = {
					current = data.default,
					states = data.states,
					updated = 0,
					time = 0,
					frame = 1,
				}
			end

			stateData = itemImages[hand].partStates[stateType]
			setAnimData = itemOverrideData.setAnimationState[stateType]
			if stateData then
				if setAnimData and setAnimData[3] ~= stateData.updated then
					local old = stateData.current
					local startNew
					stateData.current, startNew, stateData.updated = table.unpack(setAnimData)
					if old ~= stateData.current or startNew then
						stateData.time = -script.updateDt() -- cancel increment to 0
					end
					if old ~= stateData.current then
						refreshImages = true
					end
				end
				stateData.time = stateData.time + script.updateDt()
				local currentState = stateData.states[stateData.current]
				if not currentState or not currentState.cycle or not currentState.frames then
					stateData.frame = 1
				elseif stateData.time < currentState.cycle then
					stateData.frame = math.floor(stateData.time / currentState.cycle * currentState.frames) + 1
				else
					if currentState.mode == "loop" then
						stateData.frame = math.floor(stateData.time / currentState.cycle * currentState.frames) % currentState.frames + 1
					elseif currentState.mode == "end" then
						stateData.frame = currentState.frames
					elseif currentState.mode == "transition" then
						stateData.current = currentState.transition
						stateData.time = stateData.time - currentState.cycle
						currentState = stateData.states[stateData.current]
						if not currentState or not currentState.cycle or not currentState.frames then
							stateData.frame = 1
						else
							stateData.frame = math.floor(stateData.time / currentState.cycle * currentState.frames) + 1
						end
						refreshImages = true
					end
				end
			end
		end
	end

	if refreshImages then
		for itemPart, data in pairs(itemImages[hand].animation.animatedParts.parts or {}) do
			local properties = data.properties
			local partStates = {}
			for stateType, states in pairs(data.partStates or {}) do
				table.insert(partStates, stateType)
				properties = sb.jsonMerge(properties,
					(states[((itemImages[hand].partStates or {})[stateType] or {}).current] or {}).properties or {}
				)
			end
			local image = (properties or {}).image
			if type(image) == "string" then
				local tags = {}
				if type((item.config.animationParts or {})[itemPart]) == "string" then
					tags.partImage = (item.config.animationParts or {})[itemPart]
				end
				if type((item.parameters.animationParts or {})[itemPart]) == "string" then
					tags.partImage = (item.parameters.animationParts or {})[itemPart]
				end

				for tagname, tag in pairs(properties) do
					local tagType = type(tag)
					if (tagType == "string" or tagType == "number") and (tagname ~= "zLevel" and tagname ~= "image") then
						tags[tagname] = tostring(tag)
					end
				end
				local offset = properties.offset
				if properties.centered == false then
					local tagtable = sb.jsonMerge(itemImages[hand].tags or {},
						sb.jsonMerge(itemOverrideData.setGlobalTag or {},
							sb.jsonMerge(tags or {}, itemOverrideData.setPartTag[itemPart] or {})))
					if image and image ~= "" then
						local path = fixFilepath(sb.replaceTags((image or ""), tags), item)
						local success, imageSize = pcall(root.imageSize, (path))
						if success then
							offset = vec2.add(offset,vec2.div(imageSize,2*8))
						end

					end
				end

				itemImages[hand].parts[itemPart] = {
					transformationGroups = properties.transformationGroups,
					partIndex = itemImages[hand].partMap[itemPart],
					tags = tags,
					image = image,
					fullbright = properties.fullbright,
					offset = offset,
					rotationCenter = properties.rotationCenter,
					partStates = partStates
				}
			else
				itemImages[hand].parts[itemPart] = nil
				animator.setPartTag(part.."_item_"..itemImages[hand].partMap[itemPart], "partImage", "")
			end
		end
	end

	for transformGroup, transformations in pairs(itemOverrideData.transformQueue) do
		for i, args in ipairs(transformations) do
			queueHandItemTransform(hand, part, transformGroup, table.unpack(args))
		end
		itemOverrideData.transformQueue[transformGroup] = {{}}
	end
	status.setStatusProperty(hand.."ItemOverrideData", itemOverrideData)

	local outside = ""
	if itemOverrideData.setOutsideOfHand then
		outside = "_outside"
	end

	for truePartname, data in pairs(itemImages[hand].parts or {}) do

		local partname = part.."_item_"..data.partIndex

		--[[
			so the funny thing here is, the game doesn't care if you're trying to set a tag on a part that doesn't exist
			but it throws a fucking fit and crashes if you try and transform a group that doesn't exist, so its a good thing
			we can check if those exist, but even if it doesn't crash on setting a non-existent part if we don't have the transform
			group then we very much don't have the part either
		]]
		if animator.hasTransformationGroup(partname) then
			local offsetGroup = partname.."_offset"
			local offset = self.bodyconfig[armsToArm[part].."Offset"] or {0,0}
			local itemOffset = data.offset or {0,0}

			animator.translateTransformationGroup(offsetGroup, {itemOffset[1]+(offset[1]/8), itemOffset[2]+(offset[2]/8)} )
			for i, transformGroup in ipairs(data.transformationGroups or {}) do
				for j, transformation in ipairs(itemImages[hand].transformationGroups[transformGroup] or {}) do
					doHandItemTransform( partname, table.unpack(transformation))
				end
			end

			local fullbright = ""
			if data.fullbright then
				fullbright = "_fullbright"
			end

			if data.image and data.image ~= "" then
				local tagtable = sb.jsonMerge(itemImages[hand].tags or {},
					sb.jsonMerge(itemOverrideData.setGlobalTag or {},
						sb.jsonMerge(data.tags or {}, itemOverrideData.setPartTag[truePartname] or {})))
				for i, stateType in ipairs(data.partStates or {}) do
					tagtable.frame = (itemImages[hand].partStates[stateType] or {}).frame or tagtable.frame
				end
				tagtable.variant = ((item.parameters or {}).animationPartVariants or {})[truePartname] or ""

				local path = fixFilepath( sb.replaceTags( (data.image or ""), tagtable), item)
				animator.setPartTag( partname, "partImage", path or "" )
				animator.setAnimationState(partname, "item"..outside..fullbright)
			end
		end
	end
end

function clearAnimatedActiveItemTags(hand, part)
	for index = 0, usedParts do
		animator.resetTransformationGroup( part.."_item_"..index)
		animator.resetTransformationGroup( part.."_item_"..index.."_offset")
		animator.setPartTag( part.."_item_"..index, "partImage", "")
		animator.setAnimationState( part.."_item_"..index, "none" )
	end
end

function queueHandItemTransform(hand, part, transformGroup, func, ...)
	if func == "resetTransformationGroup" then
		itemImages[hand].transformationGroups[transformGroup] = {}
	elseif type(func) == "string" then
		table.insert(itemImages[hand].transformationGroups[transformGroup], {func, ... })
	end
end

function doHandItemTransform(transformGroup, func, ...)
	animator[func](transformGroup, ...)
end

function localToGlobal( position )
	local lpos = { position[1], position[2] }
	if mcontroller.facingDirection() == -1 then lpos[1] = -lpos[1] end
	local mpos = mcontroller.position()
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end
function globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if mcontroller.facingDirection() == -1 then pos[1] = -pos[1] end
	return pos
end

function rotateAimArm(aim, part)
	local target = globalToLocal(aim)
	local center = vec2.add(vec2.mul(self.armData[armsToArm[part].."OffsetData"].rotationCenter, self.currentScale or 1), {0, (self.controlParameters or {}).yOffset or 0 })
	local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))
	animator.resetTransformationGroup( part.."rotation" )
	animator.rotateTransformationGroup( part.."rotation", angle, self.armData[armsToArm[part].."OffsetData"].rotationCenter )
	return angle
end

function rotateArmAngle(part, angle)
	local center = self.armData[armsToArm[part].."OffsetData"].rotationCenter
	animator.resetTransformationGroup( part.."rotation" )
	animator.rotateTransformationGroup( part.."rotation", angle, center )
	return angle
end

function rotationArmVisible(part, outside)
	animator.setGlobalTag( part.."RotationVisible", "" )
	animator.setGlobalTag( part.."Visible", "?crop;0;0;0;0" )
	animator.setAnimationState(part.."RotationState", "rotation")
end

function setEmptyHand(hand, part)
	animator.setAnimationState(part.."RotationState", "none")
	animator.setGlobalTag( part.."RotationVisible", "?crop;0;0;0;0" )
	animator.setGlobalTag( part.."Visible", "" )
	itemImages[hand] = { parts = {} }
end

function getCosmeticItems()
	timedLoopedMessage("getEquipsAndLounging", 1, entity.id(), "animOverrideGetEquipsAndLounge", {}, function(data)
		readCosmeticItemData(data)
		self.loungingIn = data.lounging
	end)
	loopedMessage("getLounging", entity.id(), "animOverrideGetLounge", {}, function(data)
		self.loungingIn = data.lounging
	end)
end
function readCosmeticItemData(data)
	setCosmetic.head(data.headCosmetic or data.head)
	setCosmetic.chest(data.chestCosmetic or data.chest)
	setCosmetic.legs(data.legsCosmetic or data.legs)
	setCosmetic.back(data.backCosmetic or data.back)
	if equipmentChanged then
		status.setStatusProperty("animOverridesStoredEquipment", data)
	end
	refreshCosmetics = false
end

function fixFilepath(string, item)
	if type(string) == "string" then
		local firstChar = string:sub(1,1)
		if string == "" then return
		elseif firstChar == "?" or firstChar == ":" then return
		elseif firstChar == "/" then
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
	local colorReplaceString = item.parameters.directives or ""
	if type(colors) == "string" then
		return colors
	elseif type(colors) == "table" then
		local index = ((item.parameters.colorIndex or 0) % #colors) + 1
		if type(colors[index]) == "string" then
			return colorReplaceString..colors[index]
		else
			for color, replace in pairs(colors[index] or {}) do
				colorReplaceString = colorReplaceString.."?replace;"..color.."="..replace
			end
		end
	end
	return colorReplaceString
end

function updateAnims(dt)
	for statename, state in pairs(self.animStateData) do
		state.animationState.time = state.animationState.time + dt
		local ended, times, time = hasAnimEnded(statename)
		if (not ended) or (state.animationState.mode == "loop") then
			local frame = math.floor( time * state.animationState.speed )
			state.animationState.frame = frame + 1
			state.animationState.reverseFrame = math.abs(frame - state.animationState.frames)
			animator.setGlobalTag( statename.."Frame", state.animationState.frame or 1 )
		end
	end

	offsetAnimUpdate()
	rotationAnimUpdate()
	scaleAnimUpdate()

	animator.setGlobalTag( "directives", getDirectives() )

	for statename, state in pairs(self.animStateData) do
		local ended, times, time = hasAnimEnded(statename)
		if ended then
			endAnim(state, statename)
		end
		if ended and state.animationState.mode == "transition" then
			doAnim(statename, state.animationState.transition)
		end
	end
end

function updateAnimsNoRedraw(dt)
	for statename, state in pairs(self.animStateData) do
		state.animationState.time = state.animationState.time + dt
		local ended, times, time = hasAnimEnded(statename)
		if (not ended) or (state.animationState.mode == "loop") then
			local frame = math.floor( time * state.animationState.speed )
			state.animationState.frame = frame + 1
			state.animationState.reverseFrame = math.abs(frame - state.animationState.frames)
			animator.setGlobalTag( statename.."Frame", state.animationState.frame or 1 )
		elseif ended and state.animationState.mode == "transition" then
			doAnim(statename, state.animationState.transition)
		end
	end

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

function checkHumanoidAnim(dt)
	local portrait = world.entityPortrait(entity.id(), "full")
	for _, part in ipairs(portrait) do
		local imageString = part.image
		-- check for doing an emote animation
		local found1, found2 = imageString:find("/emote.png:")
		if found1 ~= nil then
			local found3, found4 = imageString:find(".1", found2, found2 + 10)
			if found3 ~= nil then
				local emote = imageString:sub(found2 + 1, found3 - 1)
				if type((self.speciesData.emoteAnimations or {})[emote]) == "table" then
					doAnims((self.speciesData.emoteAnimations or {})[emote])
				else
					doAnim("emoteState", emote)
				end
				break
			end
		end
	end

	if self.loungingIn ~= nil and not self.loungeAnim then
		local sitOrLay = world.getObjectParameter(self.loungingIn, "sitOrientation") or "sit"
		animator.setGlobalTag("state", sitOrLay)
		self.loungeAnim = sitOrLay
		doAnims(self.speciesData.animations[sitOrLay])
		addRPC(world.sendEntityMessage(self.loungingIn, "animOverridesLoungeAnim", entity.id()), function (anim)
			self.loungeAnim = anim
		end)
		return
	elseif self.loungingIn ~= nil and self.loungeAnim then
		doAnims(self.speciesData.animations[self.loungeAnim])
		return
	else
		self.loungeAnim = false
	end

	if mcontroller.onGround() then
		falling = false
		if mcontroller.walking() then movement.walking() return end
		if mcontroller.running() then movement.running() return end
		if mcontroller.crouching() then movement.crouching() return end
		movement.idle() return
	end
	if mcontroller.liquidMovement() then falling = false movement.liquidMovement() return end
	if mcontroller.jumping() then falling = false movement.jumping() return end
	if mcontroller.falling() then movement.falling() return end
	if mcontroller.flying() then falling = false movement.flying() return end
end

function checkHumanoidAnimNoRedraw(dt)
	if mcontroller.onGround() then
		falling = false
		if mcontroller.walking() then movement.walking() return end
		if mcontroller.running() then movement.running() return end
		if mcontroller.crouching() then movement.crouching() return end
		movement.idle() return
	end
	if mcontroller.liquidMovement() then falling = false movement.liquidMovement() return end
	if mcontroller.jumping() then falling = false movement.jumping() return end
	if mcontroller.falling() then movement.falling() return end
	if mcontroller.flying() then falling = false movement.flying() return end
end

function doAnims( anims, force )
	for state,anim in pairs( anims or {} ) do
		if state == "offset" then
			offsetAnim( anim )
		elseif state == "rotate" then
			rotate( anim )
		elseif state == "scale" then
			scale( anim )
		elseif state == "tags" then
			setAnimTag( anim )
		elseif state == "priority" then
			changePriorityLength( anim )
		elseif state == "controlParameters" or state == "scaledControlParameters" or state == "invertYOffset" or state == "duckOffset" then
		elseif state == "state" then
			animator.setGlobalTag("state", anim)
		else
			doAnim( state.."State", anim, force)
		end
	end
	local animsTable = self.speciesData.animations.idle
	local currentScale = self.currentScale or 1
	if (anims or {}).controlParameters then
		animsTable = anims
	end
	self.duckOffset = (anims or {}).duckOffset or 0
	if not animsTable.scaledControlParameters[currentScale] then
		createScaledHitbox(anims, animsTable, currentScale)
	end

	self.controlParameters = animsTable.scaledControlParameters[currentScale] or self.speciesData.animations.idle.scaledControlParameters[currentScale] or self.speciesData.animations.idle.controlParameters
end

function doAnim( state, anim, force)
	if not self.animStateData[state] then
		sb.logError("Attempt to call invalid Anim State: "..tostring(state))
		return
	end
	if not self.animStateData[state].states[anim] then
		sb.logError("Attempt to call invalid Anim State: "..tostring(state).."."..tostring(anim))
		return
	end

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
			transition = self.animStateData[state].states[anim].transition,
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
		reversible = data.reversible,
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

function scale( data )
	if data == self.scaling.data and self.scaling.enabled then return
	else
		for i, part in ipairs(self.scaling.parts) do
			for j, group in ipairs(part.groups) do
				animator.resetTransformationGroup(group)
			end
		end
	end

	self.scaling = {
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
		table.insert(self.scaling.parts, {
			groups = r.groups or {"globalScale2"},
			center = r.center or {0,0},
			x = r.x or {1},
			y = r.y or {1},
			lastX = (r.x or {1})[1],
			lastY = (r.y or {1})[1]
		})
		if (r.x and #r.x > 1) or (r.y and #r.y > 1) then
			continue = true
		end
	end
	scaleAnimUpdate()
	if not continue then
		self.scaling.enabled = false
	end
end


function offsetAnimUpdate()
	if self.offsets == nil or not self.offsets.enabled then return end
	local state = self.offsets.timing.."State"
	local ended, times, time = hasAnimEnded(state)
	if ended and not self.offsets.loop then self.offsets.enabled = false end
	local frame = self.animStateData[state].animationState.frame
	if self.offsets.reversible and self.direction == -1 then
		frame = self.animStateData[state].animationState.reverseFrame
	end

	for _,r in ipairs(self.offsets.parts) do
		local x = r.x[ frame ] or r.x[#r.x] or 0
		local y = r.y[ frame ] or r.y[#r.y] or 0
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

function scaleAnimUpdate()
	if self.scaling == nil or not self.scaling.enabled then return end
	local state = self.scaling.timing.."State"
	local ended, times, time = hasAnimEnded(state)
	if ended and not self.scaling.loop then self.scaling.enabled = false end
	local speed = self.animStateData[state].animationState.speed
	local frame = self.animStateData[state].animationState.frame
	local index = frame + 1
	local nextFrame = frame + 1
	local nextIndex = index + 1

	if self.scaling.prevFrame ~= frame then
		if self.scaling.frames ~= nil then
			for i = 1, #self.scaling.frames do
				if (self.scaling.frames[i] == frame) then
					self.scaling.prevFrame = frame
					self.scaling.prevIndex = i

					self.scaling.frame = self.scaling.frames[i + 1] or frame + 1
					self.scaling.index = i + 1
				end
				if self.scaling.loop and (i == #self.scaling.frames) then
					self.scaling.prevFrame = frame
					self.scaling.prevIndex = i

					self.scaling.frame = 0
					self.scaling.index = 1
				end
			end
		else
			self.scaling.prevFrame = self.scaling.frame
			self.scaling.frame = nextFrame

			self.scaling.prevIndex = self.scaling.index
			self.scaling.index = nextIndex
		end
	end

	local currTime = time * speed
	local progress = (currTime - self.scaling.prevFrame)/(math.abs(self.scaling.frame - self.scaling.prevFrame))

	for _, r in ipairs(self.scaling.parts) do
		local previousX = r.x[self.scaling.prevIndex] or r.lastX
		local nextX = r.x[self.scaling.index] or previousX
		local X = previousX + (nextX - previousX) * progress
		r.lastX = previousX

		local previousY = r.y[self.scaling.prevIndex] or r.lastY
		local nextY = r.y[self.scaling.index] or previousY
		local Y = previousY + (nextY - previousY) * progress
		r.lastY = previousY

		for _, group in ipairs(r.groups) do
			animator.resetTransformationGroup( group )
			animator.scaleTransformationGroup( group, {X,Y}, r.center)
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

function checkSettings(settings, check)
	for setting, value in pairs(check or {}) do
		if (type(settings[setting]) == "table") and settings[setting].name ~= nil then
			if not value then return false
			elseif type(value) == "table" then
				if not checkTable(value, settings[setting]) then return false end
			end
		elseif type(value) == "table" then
			local match = false
			for i, value in ipairs(value) do if (settings[setting] or false) == value then
				match = true
				break
			end end
			if not match then return false end
		elseif (settings[setting] or false) ~= value then return false
		end
	end
	return true
end

function checkTable(check, checked)
	for k, v in pairs(check) do
		if type(v) == "table" then
			if not checkTable(v, (checked or {})[k]) then return false end
		elseif v == true and type((checked or {})[k]) ~= "boolean" and ((checked or {})[k]) ~= nil then
		elseif not (v == (checked or {})[k] or false) then return false
		end
	end
	return true
end
