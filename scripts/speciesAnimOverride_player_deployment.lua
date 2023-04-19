local oldinit = init
local olduninit = uninit
local oldupdate = update

function init()
	oldinit()
end
function update(dt, ...)
	oldupdate(dt, ...)
end

function uninit()
	olduninit()
end

require("/scripts/speciesAnimOverride_player_species.lua")
