local oldinit = init
local olduninit = uninit
local oldupdate = update

local oldSetParentDirectives
local oldSetParentHidden

local techUUID

local curDirectives = ""
local curHidden = ""

function init()
	techUUID = sb.makeUuid()
	oldSetParentDirectives = tech.setParentDirectives
	tech.setParentDirectives = tech_setParentDirectives

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
	oldSetParentDirectives(string)
end

function tech_setParentHidden(bool)
	if bool then
		curHidden = "?crop;0;0;0;0"
	else
		curHidden = ""
	end

	setStatusPropertyDirectives()
	oldSetParentHidden(bool)
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
