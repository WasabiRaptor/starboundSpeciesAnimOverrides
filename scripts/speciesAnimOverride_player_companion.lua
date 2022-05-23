local oldinit = init
require("/scripts/speciesAnimOverride_player_species.lua")
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

	status.setStatusProperty("speciesAnimOverrideDirectives", nil)

	message.setHandler("giveHeldItemOverrideLockScript", function(_,_, itemDescriptor)
		giveHeldItemOverrideLockScript(itemDescriptor)
	end)

	message.setHandler("giveAnimOverrideAimTech", function(_,_)
		local headTech = player.equippedTech("head")
		if not headTech then
			player.makeTechAvailable("storeDirectivesEmpty")
			player.enableTech("storeDirectivesEmpty")
			player.equipTech("storeDirectivesEmpty")
		elseif headTech ~= "storeDirectivesEmpty" then
			player.makeTechUnavailable("storeDirectivesEmpty")
		end
	end)
	message.setHandler("removeAnimOverrideAimTech", function(_,_)
		player.makeTechUnavailable("storeDirectivesEmpty")
	end)

end

local essentialItems = {"beamaxe", "wiretool", "painttool", "inspectiontool"}

function giveHeldItemOverrideLockScript(itemDescriptor)
	local itemType = root.itemType(itemDescriptor.name)
	if (itemType == "activeitem" or itemType == "beamminingtool")
	and not blacklistedOverrideItem(itemDescriptor.name) then
		local newItemDescriptor
		if itemType == "activeitem" then
			newItemDescriptor = reuturnLockScriptItemDescriptor(itemDescriptor, "/items/active/activeitemOverrides.lua" )
		elseif itemType == "beamminingtool" then
			newItemDescriptor = reuturnLockScriptItemDescriptor(itemDescriptor, "/items/active/toolItemOverrides.lua")
		end
		if newItemDescriptor ~= nil then
			if sb.printJson(player.swapSlotItem()) == sb.printJson(itemDescriptor) then
				player.setSwapSlotItem(newItemDescriptor)
				return
			else
				local consumed = player.consumeItem(itemDescriptor, false, true)
				if consumed ~= nil then
					player.giveItem(newItemDescriptor)
					return
				else
					for i, item in ipairs(essentialItems) do
						local essentialItem = player.essentialItem(item)
						if essentialItem then
							if (essentialItem.name == itemDescriptor.name) then
								player.giveEssentialItem(item, newItemDescriptor)
								return
							end
						end
					end
				end
			end
		end
	end
end

function blacklistedOverrideItem(itemName)
	local blacklist = root.assetJson("/itemScriptBlacklist.config")
	return blacklist[itemName]
end

function reuturnLockScriptItemDescriptor(itemDescriptor, script)
	local item = root.itemConfig(itemDescriptor)
	local newItemDescriptor = { parameters = { scripts = (itemDescriptor.parameters or {}).scripts or item.config.scripts or {} } }
	table.insert(newItemDescriptor.parameters.scripts, script)
	newItemDescriptor.parameters.itemHasOverrideLockScript = true
	return sb.jsonMerge(itemDescriptor, newItemDescriptor)
end
