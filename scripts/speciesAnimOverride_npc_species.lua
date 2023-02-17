local _init = init
speciesOverride = {}

function init()

	if type(speciesOverride.species) ~= "function" then
		speciesOverride.species = npc.species
		npc.species = speciesOverride._species

		speciesOverride.gender = npc.gender
		npc.gender = speciesOverride._gender
	end

	_init()
end

function speciesOverride._species()
	return (status.statusProperty("speciesAnimOverrideData") or {}).species or speciesOverride.species()
end

function speciesOverride._gender()
	return (status.statusProperty("speciesAnimOverrideData") or {}).gender or speciesOverride.gender()
end
