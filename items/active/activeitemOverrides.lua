
local old = {
	init = init,
	uninit = uninit,
	update = update
}


function init()

	local entityType = world.entityType(entity.id())
	local slot = activeItem.hand()
	world.sendEntityMessage(entity.id(), "cleanAnimOverrideScriptItems")


	if old.init ~= nil then old.init() end
end
