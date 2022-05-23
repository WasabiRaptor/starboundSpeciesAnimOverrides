local _init = init
local speciesOverride = {}

function init()

	if type(speciesOverride.species) ~= "function" then
		speciesOverride.species = player.species
		player.species = speciesOverride._species

		speciesOverride.gender = player.species
		player.gender = speciesOverride._gender
	end

	_init()
end

function speciesOverride._species()
	return (status.statusProperty("speciesAnimOverrideData") or {}).species or speciesOverride.species()
end

function speciesOverride._gender()
	return (status.statusProperty("speciesAnimOverrideData") or {}).gender or speciesOverride.gender()
end
