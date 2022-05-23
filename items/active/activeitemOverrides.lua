
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
	setAnimationState = {},
	setGlobalTag = {},
	setPartTag = {}
}

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
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	if #itemData.transformQueue < 30 then
		table.insert(itemData.transformQueue, {funcName, ...})
	end
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old[funcName](...)
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
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	itemData.setAnimationState[statetype] = {state, startNew or false, world.time()} -- time to differentiate repeat calls
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old.setAnimationState(statetype, state, startNew)
end

function animatorOverrideFuncs.setGlobalTag(tagname, tagvalue)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	itemData.setGlobalTag[tagname] = tagvalue
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old.setGlobalTag(tagname, tagvalue)
end

function animatorOverrideFuncs.setPartTag(part, tagname, tagvalue)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	itemData.setPartTag[part] = itemData.setPartTag[part] or {}
	itemData.setPartTag[part][tagname] = tagvalue
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old.setPartTag(part, tagname, tagvalue)
end
