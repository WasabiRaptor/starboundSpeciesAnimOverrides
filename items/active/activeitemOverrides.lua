
local hand
local locked
local old = {
	init = init,
	uninit = uninit,
	update = update
}
local handTable = {
	primary = {"back","","front"},
	alt = {"front","","back"}
}

local activeItemOverrideFuncs = {}
local animatorOverrideFuncs = {}
local itemData = {
	--setBackArmFrame = "",
	--setFrontArmFrame = "",
	transformQueue = {},
	setAnimationState = {},
	setGlobalTag = {},
	setPartTag = {}
}

local arm
local armOffset
local armOffsets = {}
local scale
local yOffset

require("/scripts/vec2.lua")

function init()
	activeItem.setInstanceValue("itemHasOverrideLockScript", true)

	hand = activeItem.hand()
	activeItem.setScriptedAnimationParameter("animOverridesHand", hand)

	for funcName, func in pairs(activeItemOverrideFuncs) do
		if type(old[funcName]) ~= "function" then
			old[funcName] = activeItem[funcName]
			activeItem[funcName] = func
		end
	end
	for funcName, func in pairs(animatorOverrideFuncs) do
		if type(old[funcName]) ~= "function" then
			old[funcName] = animator[funcName]
			animator[funcName] = func
		end
	end

	message.setHandler( hand.."ItemLock", function(_,_, lock)
		lockItem(lock)
	end)

	message.setHandler( item.name().."Lock", function(_,_, lock)
		lockItem(lock)
	end)
	message.setHandler(activeItem.hand().."ItemUpdateScale", function (_,_,newScale, newYOffset)
		updateOverrideScale(newScale or 1, newYOffset or 0)
	end)
	message.setHandler(activeItem.hand().."ItemUpdateSpecies", function (_,_)
		updateOverrideSpecies()
	end)

	updateOverrideScale(status.statusProperty("animOverridesCurrentScale") or 1, status.statusProperty("animOverridesGlobalScaleYOffset") or 0)
	updateOverrideSpecies()

	if old.init ~= nil then old.init() end

	status.setStatusProperty(hand.."ItemOverrideData", itemData)
end

function updateOverrideSpecies()
	armOffsets.front = status.statusProperty("frontarmAnimOverrideArmOffset")
	armOffsets.back = status.statusProperty("backarmAnimOverrideArmOffset")
	activeItem.setScriptedAnimationParameter("frontarmAnimOverrideArmOffset", armOffsets.front)
	activeItem.setScriptedAnimationParameter("backarmAnimOverrideArmOffset", armOffsets.back)
end

function updateOverrideScale(newScale, newYOffset)
	scale = newScale
	yOffset = newYOffset
	activeItem.setScriptedAnimationParameter("animOverridesCurrentScale", scale or 1)
	activeItem.setScriptedAnimationParameter("animOverridesGlobalScaleYOffset", yOffset or 0)
end

function update(dt, fireMode, shiftHeld, moves)
	itemData = status.statusProperty(hand .. "ItemOverrideData") or itemData
	arm = handTable[hand][mcontroller.facingDirection()+2]
	armOffset = armOffsets[arm]

	if old.update ~= nil then
		if locked then
			old.update(dt, "none", false, {})
		else
			old.update(dt, fireMode, shiftHeld, moves)
		end
	end
	status.setStatusProperty(hand .. "ItemOverrideData", itemData)
end

function lockItem(lock)
	if not locked and lock then
		locked = lock
		if old.uninit ~= nil then old.uninit() end
	elseif locked and not lock then
		locked = lock
		if old.init ~= nil then old.init() end
	end
end

function uninit()
	if old.uninit ~= nil then old.uninit() end
end

function saveDataDoOld(funcName, ...)
	itemData[funcName] = ...
	return old[funcName](...)
end
function interceptFunction(func)
	activeItemOverrideFuncs[func] = function(...)
		saveDataDoOld(func, ...)
	end
end
interceptFunction("setInventoryIcon")
interceptFunction("setHoldingItem")
interceptFunction("setBackArmFrame")
interceptFunction("setFrontArmFrame")
interceptFunction("setTwoHandedGrip")
interceptFunction("setOutsideOfHand")
interceptFunction("setArmAngle")

function transformQueue(funcName, transformGroup, ...)
	if not itemData.transformQueue[transformGroup] then
		itemData.transformQueue[transformGroup] = {{"resetTransformationGroup"}}
	end
	if #itemData.transformQueue[transformGroup] < 30 then
		table.insert(itemData.transformQueue[transformGroup], { funcName, ... })
	else
		--sb.logInfo("too many transformations in "..transformGroup.."'s queue to do " .. funcName .. ": " .. sb.printJson({...}))
		--sb.logInfo(sb.printJson(itemData.transformQueue,1))
	end
	return old[funcName](transformGroup,...)
end
function interceptTransform(func)
	animatorOverrideFuncs[func] = function(...)
		transformQueue(func, ...)
	end
end
interceptTransform("rotateTransformationGroup")
interceptTransform("scaleTransformationGroup")
interceptTransform("transformTransformationGroup")
interceptTransform("translateTransformationGroup")
function animatorOverrideFuncs.resetTransformationGroup(transformGroup, ...)
	itemData.transformQueue[transformGroup] = {{"resetTransformationGroup"}}
	return old.resetTransformationGroup(transformGroup,...)
end

function animatorOverrideFuncs.setAnimationState(statetype, state, startNew)
	itemData.setAnimationState[statetype] = {state, startNew or false, world.time()} -- time to differentiate repeat calls
	return old.setAnimationState(statetype, state, startNew)
end

function animatorOverrideFuncs.setGlobalTag(tagname, tagvalue)
	itemData.setGlobalTag[tagname] = tagvalue
	return old.setGlobalTag(tagname, tagvalue)
end

function animatorOverrideFuncs.setPartTag(part, tagname, tagvalue)
	itemData.setPartTag[part] = itemData.setPartTag[part] or {}
	itemData.setPartTag[part][tagname] = tagvalue
	return old.setPartTag(part, tagname, tagvalue)
end

function globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if mcontroller.facingDirection() == -1 then pos[1] = -pos[1] end
	return pos
end

function activeItemOverrideFuncs.handPosition(offset)
	if armOffset and itemData.setArmAngle ~= nil then
		local angle = itemData.setArmAngle
		local position = vec2.add(vec2.sub(armOffset.handPosition, armOffset.rotationCenter), offset or { 0, 0 })
		local center = armOffset.rotationCenter
		if center[1] < 1 then
			center[1] = -center[1]
		end
		local rotated = vec2.add(vec2.mul(vec2.add(vec2.rotate(position, angle ), center), scale), {0, yOffset})
		if mcontroller.facingDirection() == -1 then rotated[1] = -rotated[1] end
		return rotated
	else
		return old.handPosition(offset)
	end
end

function activeItemOverrideFuncs.aimAngleAndDirection(aimVerticalOffset, targetPosition)
	if armOffset then
		local target = globalToLocal( targetPosition )
		local scaledCenter = vec2.mul(vec2.add(armOffset.rotationCenter, {0, aimVerticalOffset}), scale)
		local flipLine = math.min(0, scaledCenter[1])
		local direction = mcontroller.facingDirection()
		if target[1] < flipLine then
			direction = direction * -1
		end
		local center = vec2.add(scaledCenter, {0, yOffset})
		local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))
		return angle, direction
	else
		return old.aimAngleAndDirection(aimVerticalOffset, targetPosition)
	end
end
function activeItemOverrideFuncs.aimAngle(aimVerticalOffset, targetPosition)
	if armOffset then
		local target = world.distance( targetPosition, mcontroller.position() )
		local center = vec2.add(vec2.mul(vec2.add(armOffset.rotationCenter, { 0, aimVerticalOffset }), scale), { 0, yOffset })
		center[1] = center[1] * mcontroller.facingDirection()
		local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))
		return angle
	else
		return old.aimAngle(aimVerticalOffset, targetPosition)
	end
end
