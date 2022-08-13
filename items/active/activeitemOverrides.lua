
local hand
local locked
local old = {
	init = init,
	uninit = uninit,
	update = update
}

local activeItemOverrideFuncs = {}
local animatorOverrideFuncs = {}
local itemData = {
	transformQueue = {{}},
	setAnimationState = {},
	setGlobalTag = {},
	setPartTag = {}
}

require("/scripts/vec2.lua")

function init()
	activeItem.setInstanceValue("itemHasOverrideLockScript", true)

	hand = activeItem.hand()

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

	status.setStatusProperty(hand.."ItemOverrideData", itemData)


	message.setHandler( hand.."ItemLock", function(_,_, lock)
		lockItem(lock)
	end)

	message.setHandler( item.name().."Lock", function(_,_, lock)
		lockItem(lock)
	end)


	if old.init ~= nil then old.init() end
end

function update(dt, fireMode, shiftHeld, moves)
	if old.update ~= nil then
		if locked then
			old.update(dt, "none", false, {})
		else
			old.update(dt, fireMode, shiftHeld, moves)
		end
	end
end

function lockItem(lock)
	if not locked and lock then
		if old.uninit ~= nil then old.uninit() end
	end
	if locked and not lock then
		if old.init ~= nil then old.init() end
	end
	locked = lock
end

function uninit()
	if old.uninit ~= nil then old.uninit() end
end

function saveDataDoOld(funcName, ...)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or itemData
	itemData[funcName] = ...
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
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

function transformQueue(funcName, ...)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or itemData
	if #itemData.transformQueue < 30 then
		table.insert(itemData.transformQueue, {funcName, ...})
	end
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	return old[funcName](...)
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
interceptTransform("resetTransformationGroup")

function animatorOverrideFuncs.setAnimationState(statetype, state, startNew)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or itemData
	itemData.setAnimationState[statetype] = {state, startNew or false, world.time()} -- time to differentiate repeat calls
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	return old.setAnimationState(statetype, state, startNew)
end

function animatorOverrideFuncs.setGlobalTag(tagname, tagvalue)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or itemData
	itemData.setGlobalTag[tagname] = tagvalue
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	return old.setGlobalTag(tagname, tagvalue)
end

function animatorOverrideFuncs.setPartTag(part, tagname, tagvalue)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or itemData
	itemData.setPartTag[part] = itemData.setPartTag[part] or {}
	itemData.setPartTag[part][tagname] = tagvalue
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	return old.setPartTag(part, tagname, tagvalue)
end

local handTable = {
	primary = {"back","","front"},
	alt = {"front","","back"}
}

function globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if mcontroller.facingDirection() == -1 then pos[1] = -pos[1] end
	return pos
end

function activeItemOverrideFuncs.handPosition(offset)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or itemData
	local arm = handTable[hand][mcontroller.facingDirection()+2]
	local armOffset = status.statusProperty(arm.."armAnimOverrideArmOffset")
	if armOffset and itemData.setArmAngle ~= nil then
		local scale = status.statusProperty("animOverridesCurrentScale") or 1
		local yOffset = status.statusProperty("animOverridesGlobalScaleYOffset") or 0
		local position = vec2.mul(vec2.sub(vec2.add(armOffset.handPosition, offset), armOffset.rotationCenter), scale)
		local rotated = vec2.add(vec2.rotate(position, itemData.setArmAngle), vec2.add(vec2.mul(armOffset.rotationCenter, scale), {0, yOffset}))
		if mcontroller.facingDirection() == -1 then rotated[1] = -rotated[1] end
		return rotated
	else
		return old.handPosition(offset)
	end
end
function activeItemOverrideFuncs.aimAngleAndDirection(aimVerticalOffset, targetPosition)
	local arm = handTable[hand][mcontroller.facingDirection()+2]
	local armOffset = status.statusProperty(arm.."armAnimOverrideArmOffset")
	if armOffset then
		local target = world.distance( targetPosition, mcontroller.position() )
		local scale = status.statusProperty("animOverridesCurrentScale") or 1
		local scaledCenter = vec2.mul(vec2.add(armOffset.rotationCenter, {0, aimVerticalOffset}), scale)
		local flipLine = math.min(0, scaledCenter[1])
		local direction = 1
		if target[1] < flipLine then
			direction = -1
		end
		if mcontroller.facingDirection() == -1 then target[1] = -target[1] end
		local yOffset = status.statusProperty("animOverridesGlobalScaleYOffset") or 0
		local center = vec2.add(scaledCenter, {0, yOffset})
		local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))
		return angle, direction
	else
		return old.aimAngleAndDirection(aimVerticalOffset, targetPosition)
	end
end
function activeItemOverrideFuncs.aimAngle(aimVerticalOffset, targetPosition)
	local arm = handTable[hand][mcontroller.facingDirection()+2]
	local armOffset = status.statusProperty(arm.."armAnimOverrideArmOffset")
	if armOffset then
		local target = world.distance( targetPosition, mcontroller.position() )
		if mcontroller.facingDirection() == -1 then target[1] = -target[1] end
		local scale = status.statusProperty("animOverridesCurrentScale") or 1
		local yOffset = status.statusProperty("animOverridesGlobalScaleYOffset") or 0
		local center = vec2.add(vec2.mul(vec2.add(armOffset.rotationCenter, {0, aimVerticalOffset}), scale), {0, yOffset})
		local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))
		return angle
	else
		return old.aimAngle(aimVerticalOffset, targetPosition)
	end
end
