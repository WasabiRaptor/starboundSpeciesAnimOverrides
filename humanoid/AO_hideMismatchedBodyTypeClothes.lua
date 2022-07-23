
local _setCosmetic = {
	chest_addon = setCosmetic.chest_addon,
	legs_addon = setCosmetic.legs_addon,
	back_addon = setCosmetic.back_addon

}

function setCosmetic.chest_addon(cosmetic, item, images, directives)
	_setCosmetic.chest_addon(cosmetic, item, images, directives)
	if item.AObodyType ~= self.speciesData.bodyType then
		setCosmetic.chest_clear(cosmetic)
	end
end

function setCosmetic.legs_addon(cosmetic, item, images, directives)
	_setCosmetic.legs_addon(cosmetic, item, images, directives)
	if item.AObodyType ~= self.speciesData.bodyType then
		setCosmetic.legs_clear(cosmetic)
	end
end

function setCosmetic.back_addon(cosmetic, item, images, directives)
	_setCosmetic.back_addon(cosmetic, item, images, directives)
	if item.AObodyType ~= self.speciesData.bodyType then
		setCosmetic.back_clear(cosmetic)
	end
end
