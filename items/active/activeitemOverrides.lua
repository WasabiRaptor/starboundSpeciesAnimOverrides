
local hand
local locked
local old = {
	init = init,
	uninit = uninit,
	update = update
}

overrideFuncs = {}

function init()
	activeItem.setInstanceValue("itemHasOverrideLockScript", true)

	hand = activeItem.hand()

	status.setStatusProperty(hand.."ItemOverrideData", {})

	for funcName, func in pairs(overrideFuncs) do
		old[funcName] = activeItem[funcName]
		activeItem[funcName] = func
	end

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

local function saveDataDoOld(funcName, data)
	local itemData = status.statusProperty(hand.."ItemOverrideData") or {}
	itemData[funcName] = data
	status.setStatusProperty(hand.."ItemOverrideData", itemData)
	old[funcName](data)
end

function overrideFuncs.setHoldingItem(data)
	saveDataDoOld("setHoldingItem", data)
end

function overrideFuncs.setBackArmFrame(data)
	saveDataDoOld("setBackArmFrame", data)
end

function overrideFuncs.setFrontArmFrame(data)
	saveDataDoOld("setFrontArmFrame", data)
end

function overrideFuncs.setTwoHandedGrip(data)
	saveDataDoOld("setTwoHandedGrip", data)
end

function overrideFuncs.setOutsideOfHand(data)
	saveDataDoOld("setOutsideOfHand", data)
end

function overrideFuncs.setArmAngle(data)
	saveDataDoOld("setArmAngle", data)
end
