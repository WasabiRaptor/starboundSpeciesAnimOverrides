local oldinit = init
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
end

require("/scripts/speciesAnimOverride_npc_species.lua")
