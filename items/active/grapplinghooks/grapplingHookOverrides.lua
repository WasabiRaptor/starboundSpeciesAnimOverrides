local _updateOverrideScale = updateOverrideScale
local _init = init
function init()
	_init()
	updateOverrideScale(status.statusProperty("animOverridesCurrentScale") or 1, status.statusProperty("animOverridesGlobalScaleYOffset") or 0)
end
function updateOverrideScale(scale, yOffset)
	_updateOverrideScale(scale, yOffset)
	self.reelInDistance = config.getParameter("reelInDistance") * scale
	self.reelOutLength = config.getParameter("reelOutLength") * scale
	self.breakLength = config.getParameter("breakLength") * scale
	self.minSwingDistance = config.getParameter("minSwingDistance") * scale
	self.reelSpeed = config.getParameter("reelSpeed") * scale
end
