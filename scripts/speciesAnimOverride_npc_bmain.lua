local oldinit = init

local setLockScriptFunctions
local old = {}
local speciesOverride = {}

function init()
	status.setStatusProperty("speciesAnimOverrideDirectives", nil)

	message.setHandler("animOverrideGetEquipsAndLounge", function(_, _)
		local nude = status.statPositive("nude")
		return {
			head = not nude and npc.getItemSlot("head"),
			chest = not nude and npc.getItemSlot("chest"),
			legs = not nude and npc.getItemSlot("legs"),
			back = not nude and npc.getItemSlot("back"),
			headCosmetic = not nude and npc.getItemSlot("headCosmetic"),
			chestCosmetic = not nude and npc.getItemSlot("chestCosmetic"),
			legsCosmetic = not nude and npc.getItemSlot("legsCosmetic"),
			backCosmetic = not nude and npc.getItemSlot("backCosmetic"),
			lounging = npc.loungingIn()
		}
	end)
	message.setHandler("animOverrideGetLounge", function(_,_)
		return {
			lounging = npc.loungingIn()
		}
	end)
	message.setHandler("applySpeciesAnimOverride", function ()
		local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData") or {}
		local effects = status.getPersistentEffects("speciesAnimOverride")
		if not effects[1] then
			status.setPersistentEffects("speciesAnimOverride", {  speciesAnimOverrideData.customAnimStatus or "speciesAnimOverride" })
		end
	end)

	if not status.statusProperty("speciesAnimOverrideData") then
		speciesFile = root.assetJson("/species/" .. (npc.species()) .. ".species") or {}
		local effect = speciesFile.customAnimStatus or "speciesAnimOverride"
		status.setStatusProperty("speciesAnimOverrideData", { customAnimStatus = effect, permanent = speciesFile.permanentAnimOverride })
		if speciesFile.permanentAnimOverride then
			status.setPersistentEffects("speciesAnimOverride", { effect })
		end
	end
	local scale = status.statusProperty("animOverrideScale") or 1
	if scale ~= 1 then
		local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData") or {}
		local effects = status.getPersistentEffects("speciesAnimOverride")
		if not effects[1] then
			status.setPersistentEffects("speciesAnimOverride", {  speciesAnimOverrideData.customAnimStatus or "speciesAnimOverride" })
		end
	end
	message.setHandler("giveHeldItemOverrideLockScript", function(_,_, itemDescriptor)
		giveHeldItemOverrideLockScript(itemDescriptor)
	end)

	if not setLockScriptFunctions then
		setLockScriptFunctions = true
		old.setItemSlot = npc.setItemSlot
		npc.setItemSlot = speciesOverride.setItemSlot
	end

	oldinit()
end

function giveHeldItemOverrideLockScript(itemDescriptor)
	old.setItemSlot("primary", returnLockScriptItemDescriptor(npc.getItemSlot("primary"), "/items/active/activeitemOverrides.lua"))
	old.setItemSlot("alt", returnLockScriptItemDescriptor(npc.getItemSlot("alt"), "/items/active/activeitemOverrides.lua"))
end

function speciesOverride.setItemSlot(slot, itemDescriptor)
	if (slot == "primary" or slot == "alt") and type(itemDescriptor) == "table" then
		local itemType = root.itemType(itemDescriptor.name)
		if (itemType == "activeitem") and not blacklistedOverrideItem(itemDescriptor.name) then
			old.setItemSlot(slot, returnLockScriptItemDescriptor(itemDescriptor, "/items/active/activeitemOverrides.lua"))
		else
			old.setItemSlot(slot, itemDescriptor)
		end
	else
		old.setItemSlot(slot, itemDescriptor)
	end
end

require("/scripts/speciesAnimOverride_addLockScript.lua")

require("/scripts/speciesAnimOverride_npc_species.lua")
