local hand
local old = {
	init = init,
	update = update
}

local activeItemAnimationOverrideFuncs = {}

local handTable = {
	primary = {"back","","front"},
	alt = {"front","","back"}
}

require("/scripts/vec2.lua")
local itemData = {
	transformQueue = {{}},
	setAnimationState = {},
	setGlobalTag = {},
	setPartTag = {}
}
local arm
local armOffset
local scale
local yOffset

function init()
	hand = animationConfig.animationParameter("animOverridesHand")
	for funcName, func in pairs(activeItemAnimationOverrideFuncs) do
		if type(old[funcName]) ~= "function" then
			old[funcName] = activeItemAnimation[funcName]
			activeItemAnimation[funcName] = func
		end
	end
	if old.init ~= nil then old.init() end
end

function update()
	arm = handTable[hand][activeItemAnimation.ownerFacingDirection()+2]
	armOffset = animationConfig.animationParameter(arm .. "armAnimOverrideArmOffset")
	scale = animationConfig.animationParameter("animOverridesCurrentScale") or 1
	yOffset = (animationConfig.animationParameter("animOverridesGlobalScaleYOffset") or 0) + (animationConfig.animationParameter("animOverridesDuckOffset") or 0)

	if old.update ~= nil then old.update() end
end


function activeItemAnimationOverrideFuncs.handPosition(offset)
	if armOffset then
		local angle = activeItemAnimation.ownerArmAngle()
		local position = vec2.add(vec2.sub(armOffset.handPosition, armOffset.rotationCenter), offset or { 0, 0 })
		local center = armOffset.rotationCenter
		if center[1] < 1 then
			center[1] = -center[1]
		end
		local rotated = vec2.add(vec2.mul(vec2.add(vec2.rotate(position, angle ), center), scale), {0, yOffset})
		if activeItemAnimation.ownerFacingDirection() == -1 then rotated[1] = -rotated[1] end
		return rotated
	else
		return old.handPosition(offset)
	end
end
