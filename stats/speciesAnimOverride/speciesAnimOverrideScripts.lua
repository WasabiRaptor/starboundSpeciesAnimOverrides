function setCosmetic.head(cosmetic)
	if cosmetic ~= nil then
		if (currentCosmeticName.head == cosmetic.name) and (not refreshCosmetics) then return end

		equipmentChanged = true
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
		if (currentCosmeticName.chest == cosmetic.name) and (not refreshCosmetics) then return end

		equipmentChanged = true
		currentCosmeticName.chest = cosmetic.name

		local item = root.itemConfig(cosmetic)
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
		if (currentCosmeticName.legs == cosmetic.name) and (not refreshCosmetics) then return end
		equipmentChanged = true
		currentCosmeticName.legs = cosmetic.name

		local item = root.itemConfig(cosmetic)

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
		if (currentCosmeticName.back == cosmetic.name) and (not refreshCosmetics) then return end

		equipmentChanged = true
		currentCosmeticName.back = cosmetic.name

		local item = root.itemConfig(cosmetic)

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
	if not falling then
		doAnims(self.speciesData.animations.fall)
		falling = true
	end
end

function movement.flying()
	doAnims(self.speciesData.animations.fly)
end

function scaleUpdated(dt)
	world.sendEntityMessage(entity.id(), "primaryItemUpdateScale", self.currentScale or 1, (self.controlParameters or {}).yOffset or 0)
	world.sendEntityMessage(entity.id(), "altItemUpdateScale", self.currentScale or 1, (self.controlParameters or {}).yOffset or 0)
end

function createScaledHitbox(anims, animsTable, currentScale)
	animsTable.scaledControlParameters[currentScale] = sb.jsonMerge(self.playerMovementParams, animsTable.controlParameters or {})

	local scaledControlParameters = animsTable.scaledControlParameters[currentScale]
	scaledControlParameters.collisionPoly = poly.scale(scaledControlParameters.collisionPoly, {currentScale,currentScale})

	local yOffset = ((((anims or {}).offset or {}).scaled or {}).y or 0)/8

	scaledControlParameters.yOffset = yOffset - (yOffset * currentScale)

	scaledControlParameters.collisionPoly = poly.translate(scaledControlParameters.collisionPoly, {0, scaledControlParameters.yOffset})

	scaledControlParameters.walkSpeed = scaledControlParameters.walkSpeed * currentScale
	scaledControlParameters.runSpeed = scaledControlParameters.runSpeed * currentScale
	scaledControlParameters.flySpeed = scaledControlParameters.flySpeed * currentScale
	scaledControlParameters.airJumpProfile.jumpSpeed = scaledControlParameters.airJumpProfile.jumpSpeed * currentScale
	scaledControlParameters.liquidJumpProfile.jumpSpeed = scaledControlParameters.liquidJumpProfile.jumpSpeed * currentScale
	if currentScale < 1 then
		scaledControlParameters.gravityMultiplier = scaledControlParameters.gravityMultiplier * currentScale
	end
	scaledControlParameters.mass = scaledControlParameters.mass * currentScale
	scaledControlParameters.groundForce = scaledControlParameters.groundForce * currentScale
	scaledControlParameters.airForce = scaledControlParameters.airForce * currentScale
	scaledControlParameters.liquidForce = scaledControlParameters.liquidForce * currentScale
end

function animOverrideScale(scale, duration)
	self.oldScale = math.min(self.settings.scaleMax or 3, math.max(self.currentScale or self.scale or 1, self.settings.scaleMin or 0.1))
	self.scale = math.min(self.settings.scaleMax or 3, math.max(scale, self.settings.scaleMin or 0.1))
	self.scaleDuration = duration or 1
	self.scaleTime = 0
	status.setStatusProperty("animOverrideScale", self.scale)

end
