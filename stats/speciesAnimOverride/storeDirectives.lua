local oldinit = init
local olduninit = uninit

local oldSetParentDirectives
local effectUUID


function init()
	effectUUID = sb.makeUuid()
	oldSetParentDirectives = effect.setParentDirectives
	effect.setParentDirectives = effect_setParentDirectives

	if oldinit ~= nil then oldinit() end
end

function effect_setParentDirectives(string)
	local directives = status.statusProperty("speciesAnimOverrideDirectives") or {}
	directives[effectUUID] = string
	status.setStatusProperty("speciesAnimOverrideDirectives", directives)
	oldSetParentDirectives(string)
end

function uninit()
	if olduninit ~= nil then olduninit() end

	local directives = status.statusProperty("speciesAnimOverrideDirectives") or {}
	directives[effectUUID] = nil
	status.setStatusProperty("speciesAnimOverrideDirectives", directives)
end
