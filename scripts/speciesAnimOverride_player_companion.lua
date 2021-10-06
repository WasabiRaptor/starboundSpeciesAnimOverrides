local oldinit = init
function init()
	oldinit()
	message.setHandler("animOverrideGetEquips", function(_,_)
		return {
			head = player.equippedItem("head"),
			chest = player.equippedItem("chest"),
			legs = player.equippedItem("legs"),
			back = player.equippedItem("back"),
			headCosmetic = player.equippedItem("headCosmetic"),
			chestCosmetic = player.equippedItem("chestCosmetic"),
			legsCosmetic = player.equippedItem("legsCosmetic"),
			backCosmetic = player.equippedItem("backCosmetic"),
		}
	end)

	message.setHandler("giveHeldItemOverrideLockScript", function(_,_, itemDescriptor)
		if root.itemType(itemDescriptor.name) == "activeitem" then
			local newItemDescriptor = reuturnLockScriptItemDescriptor(itemDescriptor)
			if newItemDescriptor ~= nil then
				if sb.printJson(player.swapSlotItem()) == sb.printJson(itemDescriptor) then
					player.setSwapSlotItem(newItemDescriptor)
				else
					local consumed = player.consumeItem(itemDescriptor, false, true)
					if consumed ~= nil then
						player.giveItem(newItemDescriptor)
					end
				end
			end
		end
	end)
end

function reuturnLockScriptItemDescriptor(itemDescriptor)
	local item = root.itemConfig(itemDescriptor)
	local newItemDescriptor = { parameters = { scripts = item.config.scripts or {} } }
	table.insert(newItemDescriptor.parameters.scripts, "/items/active/activeitemOverrides.lua")
	newItemDescriptor.parameters.itemHasOverrideLockScript = true
	return sb.jsonMerge(itemDescriptor, newItemDescriptor)
end
