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

	for i, slot in ipairs({"primary", "alt"}) do
		item = npc.getItemSlot(slot)
		if item and item.parameters and item.parameters.itemHasOverrideLockScript then
			item.parameters.scripts = nil
			item.parameters.animationScripts = nil
			item.parameters.itemHasOverrideLockScript = nil
		end
		npc.setItemSlot(slot, item)
	end

end
