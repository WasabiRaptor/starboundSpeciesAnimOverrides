
local hand
local locked
local old = {
	init = init,
	uninit = uninit,
	update = update
}

overrideFuncs = {}

function init()
	status.setStatusProperty(hand.."ItemOverrideData", {})

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
