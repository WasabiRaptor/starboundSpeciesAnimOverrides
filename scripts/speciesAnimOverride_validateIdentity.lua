
-- we need this to make sure the identity data is valid in some cases so we need this

local function checkGroup(identity, group)
	if identity[group.."Type"] == "" or type(identity[group.."Type"]) ~= "string" then
		identity[group.."Type"] = nil
	end
	if identity[group.."Group"] == "" or type(identity[group.."Group"]) ~= "string" then
		identity[group.."Group"] = nil
	end
end

function validateIdentity(identity)
	checkGroup(identity, "hair")
	checkGroup(identity, "facialHair")
	checkGroup(identity, "facialMask")
end
