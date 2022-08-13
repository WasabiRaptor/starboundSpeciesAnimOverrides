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

	message.setHandler("applySpeciesAnimOverride", function ()
		local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData") or {}
		local effects = status.getPersistentEffects("speciesAnimOverride")
		if not effects[1] then
			status.setPersistentEffects("speciesAnimOverride", {  speciesAnimOverrideData.customAnimStatus or "speciesAnimOverride" })
		end
	end)

end

local essentialItems = {"beamaxe", "wiretool", "painttool", "inspectiontool"}

function giveHeldItemOverrideLockScript(itemDescriptor)
	local itemType = root.itemType(itemDescriptor.name)
	if (itemType == "activeitem") and not blacklistedOverrideItem(itemDescriptor.name) then
		local newItemDescriptor = reuturnLockScriptItemDescriptor(itemDescriptor, "/items/active/activeitemOverrides.lua" )

		if newItemDescriptor ~= nil then
			local itemDescriptorString = sb.printJson(itemDescriptor)
			if sb.printJson(player.swapSlotItem()) == itemDescriptorString then
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
	local newItemDescriptor = { parameters = {
		scripts = (itemDescriptor.parameters or {}).scripts or item.config.scripts or {},
		animationScripts = (itemDescriptor.parameters or {}).animationScripts or item.config.animationScripts
	} }
	table.insert(newItemDescriptor.parameters.scripts, script)
	if (itemDescriptor.parameters or {}).animationScripts or item.config.animationScripts then
		table.insert(newItemDescriptor.parameters.animationScripts, "/items/active/actievitemAnimationOverrides.lua")
	end
	newItemDescriptor.parameters.itemHasOverrideLockScript = true
	return sb.jsonMerge(itemDescriptor, newItemDescriptor)
end

require("/scripts/speciesAnimOverride_player_species.lua")
