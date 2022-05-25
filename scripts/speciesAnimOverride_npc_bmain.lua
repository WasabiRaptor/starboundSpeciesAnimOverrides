local oldinit = init
function init()
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

	status.setStatusProperty("speciesAnimOverrideDirectives", nil)

	local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData")
	if type(speciesAnimOverrideData) == "table" then
		status.setPersistentEffects("speciesAnimOverride", { speciesAnimOverrideData.customAnimStatus or "speciesAnimOverride"})
	end
end

require("/scripts/speciesAnimOverride_npc_species.lua")
