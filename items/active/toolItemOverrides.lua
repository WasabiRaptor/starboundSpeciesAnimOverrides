
local old = {
	init = init,
	uninit = uninit,
	update = update
}


function init()

	if old.init ~= nil then old.init() end
end
