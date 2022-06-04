local oldinit = init
local olduninit = uninit
local oldupdate = update

local _setParentDirectives
local _setParentHidden
local _controlParameters

local techUUID

local curDirectives = ""
local curHidden = ""

function init()
	if not _setParentDirectives then
		techUUID = sb.makeUuid()

		_setParentDirectives = tech.setParentDirectives
		tech.setParentDirectives = tech_setParentDirectives

		_setParentHidden = tech.setParentHidden
		tech.setParentHidden = tech_setParentHidden

		_controlParameters = mcontroller.controlParameters
		mcontroller.controlParameters = mcontroller_controlParameters
	end

	oldSetParentHidden = tech.setParentHidden
	tech.setParentHidden = tech_setParentHidden


	if oldinit ~= nil then oldinit() end
end

function update(args)
	status.setStatusProperty("speciesAnimOverrideAim", tech.aimPosition())
	if oldupdate ~= nil then oldupdate(args) end
end

function tech_setParentDirectives(string)
	curDirectives = string or ""
	setStatusPropertyDirectives()
	_setParentDirectives(string)
end

function mcontroller_controlParameters(data)
	if data.collisionPoly ~= nil then
		status.setStatusProperty("speciesAnimOverrideControlParams", true)
	end
	_controlParameters(data)
end

function tech_setParentHidden(bool)
	if bool then
		curHidden = "?crop;0;0;0;0"
	else
		curHidden = ""
	end

	setStatusPropertyDirectives()
	_setParentHidden(bool)
end

function setStatusPropertyDirectives()
	local directives = status.statusProperty("speciesAnimOverrideDirectives") or {}
	directives[techUUID] = curDirectives..curHidden
	status.setStatusProperty("speciesAnimOverrideDirectives", directives)
end

function uninit()
	if olduninit ~= nil then olduninit() end

	local directives = status.statusProperty("speciesAnimOverrideDirectives") or {}
	directives[techUUID] = nil
	status.setStatusProperty("speciesAnimOverrideDirectives", directives)
end
