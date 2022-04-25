local oldinit = init
local olduninit = uninit

local _setParentDirectives
local _controlParameters
local effectUUID


function init()
	effectUUID = sb.makeUuid()
	_setParentDirectives = effect.setParentDirectives
	effect.setParentDirectives = effect_setParentDirectives
	_controlParameters = mcontroller.controlParameters
	mcontroller.controlParameters = mcontroller_controlParameters

	if oldinit ~= nil then oldinit() end
end

function effect_setParentDirectives(string)
	local directives = status.statusProperty("speciesAnimOverrideDirectives") or {}
	directives[effectUUID] = string
	status.setStatusProperty("speciesAnimOverrideDirectives", directives)
	_setParentDirectives(string)
end

function mcontroller_controlParameters(...)
	status.setStatusProperty("speciesAnimOverrideControlParams", true)
	mcontroller.controlParameters(...)
	_controlParameters(...)
end

function uninit()
	if olduninit ~= nil then olduninit() end

	local directives = status.statusProperty("speciesAnimOverrideDirectives") or {}
	directives[effectUUID] = nil
	status.setStatusProperty("speciesAnimOverrideDirectives", directives)
end
