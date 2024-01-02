local oldinit = init
local olduninit = uninit
local oldupdate = update

function init()
	oldinit()
	message.setHandler("cleanAnimOverrideScriptItems", function(_,_)
		cleanAnimOverrideScriptItems()
	end)
	cleanAnimOverrideScriptItems()
end

function cleanAnimOverrideScriptItems()
	player.makeTechUnavailable("storeDirectivesEmpty")

	local clean
	while clean ~= true do

		clean = true
		local lockedItemList = player.getProperty("sbqLockedItems")
		for i, lockedItemData in pairs(lockedItemList or {}) do
			player.giveItem(lockedItemData)
			table.remove(lockedItemList, i)
			clean = false
		end

		player.setProperty("sbqLockedItems", lockedItemList)

		if clean then
			for slotname, itemDescriptor in pairs(storage.lockedEssentialItems or {}) do
				player.giveEssentialItem(slotname, itemDescriptor)
			end
		end
	end

	local hasOverrideItem = true
	while hasOverrideItem do
		item = player.getItemWithParameter("itemHasOverrideLockScript", true)
		if item then
			consumed = player.consumeItem(item, false, true)
			if consumed then
				consumed.parameters.scripts = nil
				consumed.parameters.animationScripts = nil
				consumed.parameters.itemHasOverrideLockScript = nil
				player.giveItem(consumed)
			end
		else
			hasOverrideItem = false
		end
	end
end
