
local hand
local locked
local old = {
	init = init,
	uninit = uninit,
	update = update
}

local activeItemOverrideFuncs = {}
local animatorOverrideFuncs = {}
local ItemOverrideData = {
	transformQueue = {{}},
	setGlobalTag = {},
	setPartTag = {}
}

function init()
	activeItem.setInstanceValue("itemHasOverrideLockScript", true)

	hand = activeItem.hand()

	for funcName, func in pairs(activeItemOverrideFuncs) do
		old[funcName] = activeItem[funcName]
		activeItem[funcName] = func
	end
	for funcName, func in pairs(animatorOverrideFuncs) do
		old[funcName] = animator[funcName]
		animator[funcName] = func
	end

	status.setStatusProperty(hand.."ItemOverrideData", ItemOverrideData)


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
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	itemData[funcName] = ...
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old[funcName](...)
end
function transformQueue(funcName, ...)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	table.insert(itemData.transformQueue, {funcName, ...})
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old[funcName](...)
end

function activeItemOverrideFuncs.setInventoryIcon(...)
	saveDataDoOld("setInventoryIcon", ...)
end

function activeItemOverrideFuncs.setHoldingItem(...)
	saveDataDoOld("setHoldingItem", ...)
end

function activeItemOverrideFuncs.setBackArmFrame(...)
	saveDataDoOld("setBackArmFrame", ...)
end

function activeItemOverrideFuncs.setFrontArmFrame(...)
	saveDataDoOld("setFrontArmFrame", ...)
end

function activeItemOverrideFuncs.setTwoHandedGrip(...)
	saveDataDoOld("setTwoHandedGrip", ...)
end

function activeItemOverrideFuncs.setOutsideOfHand(...)
	saveDataDoOld("setOutsideOfHand", ...)
end

function activeItemOverrideFuncs.setArmAngle(...)
	saveDataDoOld("setArmAngle", ...)
end

function animatorOverrideFuncs.rotateTransformationGroup(...)
	transformQueue("rotateTransformationGroup", ...)
end

function animatorOverrideFuncs.scaleTransformationGroup(...)
	transformQueue("scaleTransformationGroup", ...)
end

function animatorOverrideFuncs.transformTransformationGroup(...)
	transformQueue("transformTransformationGroup", ...)
end

function animatorOverrideFuncs.translateTransformationGroup(...)
	transformQueue("translateTransformationGroup", ...)
end

function animatorOverrideFuncs.resetTransformationGroup(...)
	transformQueue("resetTransformationGroup", ...)
end

--[[
function animatorOverrideFuncs.setAnimationState(...)
	animatorSaveDataDoOld("setAnimationState", ...)
end
]]

function animatorOverrideFuncs.setGlobalTag(tagname, tagvalue)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	itemData.setGlobalTag[tagname] = tagvalue
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old.setGlobalTag(tagname, tagvalue)
end

function animatorOverrideFuncs.setPartTag(part, tagname, tagvalue)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	itemData.setPartTag[part] = {tagname = tagname, tagvalue = tagvalue}
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old.setPartTag(part, tagname, tagvalue)
end
