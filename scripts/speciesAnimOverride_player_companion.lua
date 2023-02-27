local oldinit = init
local olduninit = uninit
local oldupdate = update
local cooldown = 0.5

function init()
	oldinit()
	message.setHandler("animOverrideGetEquipsAndLounge", function(_, _)
		local nude = status.statPositive("nude")
		return {
			head = not nude and player.equippedItem("head"),
			chest = not nude and player.equippedItem("chest"),
			legs = not nude and player.equippedItem("legs"),
			back = not nude and player.equippedItem("back"),
			headCosmetic = not nude and player.equippedItem("headCosmetic"),
			chestCosmetic = not nude and player.equippedItem("chestCosmetic"),
			legsCosmetic = not nude and player.equippedItem("legsCosmetic"),
			backCosmetic = not nude and player.equippedItem("backCosmetic"),
			lounging = player.loungingIn()
		}
	end)
	message.setHandler("animOverrideGetLounge", function(_,_)
		return {
			lounging = player.loungingIn()
		}
	end)

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
	if not status.statusProperty("speciesAnimOverrideData") then
		speciesFile = root.assetJson("/species/" .. (player.species()) .. ".species") or {}
		local effect = speciesFile.customAnimStatus or "speciesAnimOverride"
		status.setStatusProperty("speciesAnimOverrideData", { customAnimStatus = effect, permanent = speciesFile.permanentAnimOverride })
		if speciesFile.permanentAnimOverride then
			status.setPersistentEffects("speciesAnimOverride", { effect })
		end
	end
end
function update(dt, ...)
	oldupdate(dt, ...)
	cooldown = math.max(0, cooldown - dt)
end

function uninit()
	olduninit()
	status.setStatusProperty("speciesAnimOverrideDirectives", nil)
end

local essentialItems = { "beamaxe", "wiretool", "painttool", "inspectiontool" }


function giveHeldItemOverrideLockScript(itemDescriptor)
	if cooldown > 0 then return end
	player.cleanupItems()
	local itemType = root.itemType(itemDescriptor.name)
	if (itemType == "activeitem") and player.hasItem(itemDescriptor, true) and not blacklistedOverrideItem(itemDescriptor.name) then
		local count = player.hasCountOfItem(itemDescriptor, true)
		cooldown = 0.5
		local newItemDescriptor = returnLockScriptItemDescriptor(itemDescriptor, "/items/active/activeitemOverrides.lua" )

		if newItemDescriptor ~= nil then
			local itemDescriptorString = sb.printJson(itemDescriptor)
			if sb.printJson(player.swapSlotItem()) == itemDescriptorString then
				player.setSwapSlotItem(newItemDescriptor)
				return
			else
				local consumed = player.consumeItem(itemDescriptor, false, true)
				player.cleanupItems()
				local newCount = player.hasCountOfItem(itemDescriptor, true)
				if (consumed ~= nil) and (newCount < count) then
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

require("/scripts/speciesAnimOverride_addLockScript.lua")

require("/scripts/speciesAnimOverride_player_species.lua")
