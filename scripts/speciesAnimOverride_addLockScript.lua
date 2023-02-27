function blacklistedOverrideItem(itemName)
	local blacklist = root.assetJson("/itemScriptBlacklist.config")
	return blacklist[itemName]
end

function returnLockScriptItemDescriptor(itemDescriptor, script)
	if not itemDescriptor then return end
	local item = root.itemConfig(itemDescriptor)
	local newItemDescriptor = { parameters = {
		scripts = (itemDescriptor.parameters or {}).scripts or item.config.scripts or {},
		animationScripts = (itemDescriptor.parameters or {}).animationScripts or item.config.animationScripts
	} }

	local addScript = true
	for i, itemScript in ipairs(newItemDescriptor.parameters.scripts) do
		if itemScript == script then
			addScript = false
			break
		end
	end
	if addScript then table.insert(newItemDescriptor.parameters.scripts, script) end

	if (itemDescriptor.parameters or {}).animationScripts or item.config.animationScripts then
		local addScript = true
		local script = "/items/active/actievitemAnimationOverrides.lua"
		for i, itemScript in ipairs(newItemDescriptor.parameters.animationScripts) do
			if itemScript == script then
				addScript = false
				break
			end
		end
		if addScript then table.insert(newItemDescriptor.parameters.animationScripts, script) end
	end
	newItemDescriptor.parameters.itemHasOverrideLockScript = true
	return sb.jsonMerge(itemDescriptor, newItemDescriptor)
end
