local oldinit = init
function init()
	oldinit()
	message.setHandler("animOverrideGetEquipsAndLounge", function(_,_)
		return {
			head = player.equippedItem("head"),
			chest = player.equippedItem("chest"),
			legs = player.equippedItem("legs"),
			back = player.equippedItem("back"),
			headCosmetic = player.equippedItem("headCosmetic"),
			chestCosmetic = player.equippedItem("chestCosmetic"),
			legsCosmetic = player.equippedItem("legsCosmetic"),
			backCosmetic = player.equippedItem("backCosmetic"),
			lounging = player.loungingIn()
		}
	end)

	message.setHandler("giveHeldItemOverrideLockScript", function(_,_, itemDescriptor)
		giveHeldItemOverrideLockScript(itemDescriptor)
	end)
end

function giveHeldItemOverrideLockScript(itemDescriptor)
	if root.itemType(itemDescriptor.name) == "activeitem" and not blacklistedOverrideItem(itemDescriptor.name) then
		local newItemDescriptor = reuturnLockScriptItemDescriptor(itemDescriptor)
		if newItemDescriptor ~= nil then
			if sb.printJson(player.swapSlotItem()) == sb.printJson(itemDescriptor) then
				player.setSwapSlotItem(newItemDescriptor)
				return
			else
				local consumed = player.consumeItem(itemDescriptor, false, true)
				if consumed ~= nil then
					player.giveItem(newItemDescriptor)
					return
				end
			end
		end
	end
end

function blacklistedOverrideItem(itemName)
	local blacklist = root.assetJson("/itemScriptBlacklist.config")
	return blacklist[itemName]
end

function reuturnLockScriptItemDescriptor(itemDescriptor)
	local item = root.itemConfig(itemDescriptor)
	local newItemDescriptor = { parameters = { scripts = item.config.scripts or {} } }
	table.insert(newItemDescriptor.parameters.scripts, "/items/active/activeitemOverrides.lua")
	newItemDescriptor.parameters.itemHasOverrideLockScript = true
	return sb.jsonMerge(itemDescriptor, newItemDescriptor)
end
