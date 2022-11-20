local oldinit = init

local setLockScriptFunctions
local old = {}
local speciesOverride = {}

function init()
	status.setStatusProperty("speciesAnimOverrideDirectives", nil)

	oldinit()
	message.setHandler("animOverrideGetEquipsAndLounge", function(_,_)
		return {
			head = npc.getItemSlot("head"),
			chest = npc.getItemSlot("chest"),
			legs = npc.getItemSlot("legs"),
			back = npc.getItemSlot("back"),
			headCosmetic = npc.getItemSlot("headCosmetic"),
			chestCosmetic = npc.getItemSlot("chestCosmetic"),
			legsCosmetic = npc.getItemSlot("legsCosmetic"),
			backCosmetic = npc.getItemSlot("backCosmetic"),
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
	message.setHandler("giveHeldItemOverrideLockScript", function(_,_, itemDescriptor)
		giveHeldItemOverrideLockScript(itemDescriptor)
	end)

	if not setLockScriptFunctions then
		setLockScriptFunctions = true
		old.setItemSlot = npc.setItemSlot
		npc.setItemSlot = speciesOverride.setItemSlot
	end
end

function giveHeldItemOverrideLockScript(itemDescriptor)
	old.setItemSlot("primary", reuturnLockScriptItemDescriptor(npc.getItemSlot("primary"), "/items/active/activeitemOverrides.lua"))
	old.setItemSlot("alt", reuturnLockScriptItemDescriptor(npc.getItemSlot("alt"), "/items/active/activeitemOverrides.lua"))
end

function speciesOverride.setItemSlot(slot, itemDescriptor)
	if slot == "primary" or slot == "alt" and type(itemDescriptor == "table") then
		local itemType = root.itemType(itemDescriptor.name)
		if (itemType == "activeitem") and not blacklistedOverrideItem(itemDescriptor.name) then
			old.setItemSlot(slot, reuturnLockScriptItemDescriptor(itemDescriptor, "/items/active/activeitemOverrides.lua"))
		else
			old.setItemSlot(slot, itemDescriptor)
		end
	else
		old.setItemSlot(slot, itemDescriptor)
	end
end

require("/scripts/speciesAnimOverride_addLockScript.lua")

require("/scripts/speciesAnimOverride_npc_species.lua")
