
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
	itemData.setAnimationState[statetype] = {state, startNew or false, world.time()} -- time to differentiate repeat calls
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	return old.setAnimationState(statetype, state, startNew)
end

function animatorOverrideFuncs.setGlobalTag(tagname, tagvalue)
	itemData.setGlobalTag[tagname] = tagvalue
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	return old.setGlobalTag(tagname, tagvalue)
end

function animatorOverrideFuncs.setPartTag(part, tagname, tagvalue)
	itemData.setPartTag[part] = itemData.setPartTag[part] or {}
	itemData.setPartTag[part][tagname] = tagvalue
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	return old.setPartTag(part, tagname, tagvalue)
end

local handTable = {
	primary = {"back","","front"},
	alt = {"front","","back"}
}

function activeItemOverrideFuncs.handPosition(offset)
	local arm = handTable[hand][mcontroller.facingDirection()+2]
	local armOffset = status.statusProperty(arm.."armAnimOverrideArmOffset")
	if armOffset and itemData.setArmAngle ~= nil then
		local scale = status.statusProperty("animOverridesCurrentScale") or 1
		local yOffset = status.statusProperty("animOverridesGlobalScaleYOffset") or 0
		return vec2.mul({mcontroller.facingDirection(), 1},vec2.add(vec2.rotate(vec2.mul(vec2.add(armOffset.handPosition, offset), scale), itemData.setArmAngle), vec2.add(vec2.mul(armOffset.rotationCenter, scale), {0, yOffset})))
	else
		return old.handPosition(offset)
	end
end
function activeItemOverrideFuncs.aimAngleAndDirection(aimVerticalOffset, targetPosition)
	local arm = handTable[hand][mcontroller.facingDirection()+2]
	local armOffset = status.statusProperty(arm.."armAnimOverrideArmOffset")
	if armOffset then
		local offset = vec2.add(world.distance( mcontroller.position(), targetPosition ), {0,aimVerticalOffset})
		local direction = 1
		if offset[1] > 0 then
			direction = -1
		end
		local yOffset = status.statusProperty("animOverridesGlobalScaleYOffset") or 0
		return vec2.angle(vec2.mul(vec2.add(vec2.add(armOffset.rotationCenter, {0, yOffset}), vec2.mul({mcontroller.facingDirection(), 1}, offset)),-1)), direction
	else
		return old.aimAngleAndDirection(aimVerticalOffset, targetPosition)
	end
end
function activeItemOverrideFuncs.aimAngle(aimVerticalOffset, targetPosition)
	local arm = handTable[hand][mcontroller.facingDirection()+2]
	local armOffset = status.statusProperty(arm.."armAnimOverrideArmOffset")
	if armOffset then
		local offset = vec2.add(world.distance( mcontroller.position(), targetPosition ), {0,aimVerticalOffset})
		local yOffset = status.statusProperty("animOverridesGlobalScaleYOffset") or 0
		return vec2.angle(vec2.mul(vec2.add(vec2.add(armOffset.rotationCenter, {0, yOffset}), vec2.mul({mcontroller.facingDirection(), 1}, offset)),-1))
	else
		return old.aimAngle(aimVerticalOffset, targetPosition)
	end
end
