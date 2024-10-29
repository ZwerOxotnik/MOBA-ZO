local choices = {
	{{name = "power-armor", count = 1}},
	{
		{name = "flamethrower", count = 1},
		{name = "flamethrower-ammo", count = 50},
	},
	{{name = "repair-pack", count = 100}},
	{
		{name = "stone-wall", count = 190},
		{name = "gate", count = 10},
	},
	{{name="construction-robot", count = 20}},
	{{name="defender-capsule", count = 20}},
	{{name="distractor-capsule", count = 9}},
	{{name="destroyer-capsule",  count = 3}},
	{{name="cannon-shell", count = 10}},
	{{name="explosive-cannon-shell", count = 5}},
	{{name="piercing-shotgun-shell", count = 10}},
	{{name="piercing-rounds-magazine", count = 200}},
	{{name="tank", count = 1}},
	{{name="car",  count = 1}},
	{{name="behemoth-biter", count = 1}},
	{{name="big-biter", count = 5}},
	{{name="big-spitter", count = 5}},
	{{name="big-worm-turret",  count = 4}},
	{{name="slowdown-capsule", count = 10}},
	{{name="poison-capsule", count = 10}},
	{{name="grenade", count = 20}},
	{{name="cluster-grenade", count = 5}},
	{{name="land-mine", count = 20}},
	{{name="laser-turret", count = 2}},
	{{name = "gun-turret", count = 10}},
	{
		{name="rocket-launcher", count = 1},
		{name="rocket", count = 1},
	},
	{
		{name="combat-shotgun", count = 1},
		{name="shotgun-shell",  count = 20},
	},
	{
		{name="flamethrower-turret", count = 1},
		{name="pipe", count = 100},
		{name="pipe-to-ground", count = 50},
		{name="storage-tank", count = 1},
		{name="storage-tank", count = 1},
		{name="pumpjack", count = 1},
	},
	{
		{name="roboport", count = 1},
		{name="fast-inserter", count = 20},
		{name="requester-chest", count = 50},
		{name="storage-chest", count = 10},
		{name="logistic-robot", count = 50},
		{name="construction-robot", count = 100},
	},
	{{name="rocket", count = 5}},
	{{name="explosive-rocket", count = 1}},
}

if script.active_mods.IndustrialRevolution3 then
	choices[#choices+1] = {{name="scatterbot-capsule", count = 1}}
	choices[#choices+1] = {{name="steel-plate-wall", count = 100}}
	choices[#choices+1] = {{name="arc-turret", count = 1}}
	choices[#choices+1] = {{name="photon-turret", count = 1}}
	choices[#choices+1] = {{name="scattergun-turret",  count = 5}}
	choices[#choices+1] = {{name="medical-pack", count = 4}}
	choices[#choices+1] = {{name="bronze-cartridge", count = 10}}
end

if script.active_mods.Repair_Turret then
	choices[#choices+1] = {{name="repair-turret", count = 3}}
end

if script.active_mods["shield-projector"] then
	choices[#choices+1] = {{name="shield-projector", count = 1}}
end

if script.active_mods.stasis_mine then
	choices[#choices+1] = {{name="stasis-land-mine", count = 1}}
end

if script.active_mods.laserfence then
	choices[#choices+1] = {
		{name="laserfence-connector", count = 20},
		{name="laserfence-connector-cage", count = 10}
	}
end

if script.active_mods.bobwarfare then
	choices[#choices+1] = {
		{name="reinforced-wall", count = 90},
		{name="reinforced-gate", count = 10}
	}
	choices[#choices+1] = {{name="distractor-mine", count = 3}}
	choices[#choices+1] = {{name="poison-mine",   count = 6}}
	choices[#choices+1] = {{name="slowdown-mine", count = 12}}
end

if script.active_mods.Kombat_Drones then
	choices[#choices+1] = {{name="infantry-depot", count = 1}}
	choices[#choices+1] = {{name="basic-infantry", count = 10}}
	choices[#choices+1] = {{name="heavy-infantry", count = 10}}
	choices[#choices+1] = {{name="power-infantry", count = 1}}
end

if script.active_mods.ArmouredBiters then
	choices[#choices+1] = {{name="big-armoured-biter", count = 3}}
end

if script.active_mods.Cold_biters then
	choices[#choices+1] = {{name="big-cold-biter",   count = 5}}
	choices[#choices+1] = {{name="big-cold-spitter", count = 5}}
end

if script.active_mods.Explosive_biters then
	choices[#choices+1] = {{name="big-explosive-biter",   count = 2}}
	choices[#choices+1] = {{name="big-explosive-spitter", count = 2}}
end

if script.active_mods.bobenemies then
	choices[#choices+1] = {{name="bob-big-piercing-biter", count = 5}}
	choices[#choices+1] = {{name="bob-huge-acid-biter",    count = 5}}
	choices[#choices+1] = {{name="bob-huge-acid-spitter",  count = 5}}
	choices[#choices+1] = {{name="bob-huge-explosive-biter",  count = 2}}
	choices[#choices+1] = {{name="bob-huge-electric-spitter", count = 4}}
	choices[#choices+1] = {{name="bob-huge-explosive-spitter", count = 2}}
	-- choices[#choices+1] = {{name="bob-giant-poison-spitter", count = 1}}
	-- choices[#choices+1] = {{name="bob-giant-fire-spitter", count = 1}}
	-- choices[#choices+1] = {{name="bob-giant-acid-biter", count = 1}}
	-- choices[#choices+1] = {{name="bob-giant-fire-biter", count = 1}}
	-- choices[#choices+1] = {{name="bob-giant-poison-biter", count = 1}}
	-- choices[#choices+1] = {{name="bob-giant-explosive-biter", count = 1}}
end

if script.active_mods["baron-turrets"] then
	choices[#choices+1] = {
		{name="curtain-turret", count = 1},
		{name="sulfuric-acid-barrel", count = 10},
		{name="assembling-machine-2", count = 1},
	}
	choices[#choices+1] = {
		{name="cannon-turret", count = 2},
		{name="grenade-belt", count = 40},
	}
end

if script.active_mods["Reinforced-Walls"] then
	choices[#choices+1] = {
		{name="reinforced-wall", count = 90},
		{name="reinforced-gate", count = 10}
	}
	choices[#choices+1] = {
		{name="acid-resist-wall", count = 60},
		{name="acid-resist-gate", count = 10}
	}
	choices[#choices+1] = {
		{name="damage-reflect-wall", count = 40},
		{name="damage-reflect-gate", count = 10}
	}
end

if script.active_mods["Additional-Turret-updated"] then
	choices[#choices+1] = {{name="at_LC_b", count = 3}}
	choices[#choices+1] = {{name="at-cannon-turret-mk1", count = 3}}
end

if script.active_mods.Krastorio2 then
	choices[#choices+1] = {{name="kr-biter-virus", count = 3}}
	choices[#choices+1] = {{name="kr-creep-virus", count = 3}}
end

if script.active_mods.RampantArsenal then
	choices[#choices+1] = {{name="incendiary-landmine-rampant-arsenal", count = 6}}
	choices[#choices+1] = {{name="bio-landmine-rampant-arsenal", count = 3}}
	choices[#choices+1] = {{name="he-landmine-rampant-arsenal",  count = 1}}
	choices[#choices+1] = {{name="bio-grenade-capsule-rampant-arsenal", count = 1}}
	choices[#choices+1] = {{name="incendiary-grenade-capsule-rampant-arsenal", count = 1}}
	choices[#choices+1] = {{name="toxic-capsule-rampant-arsenal", count = 1}}
	choices[#choices+1] = {{name="paralysis-capsule-rampant-arsenal", count = 1}}
	choices[#choices+1] = {{name="repair-capsule-rampant-arsenal",  count = 2}}
	choices[#choices+1] = {{name="healing-capsule-rampant-arsenal", count = 1}}
	choices[#choices+1] = {{name="speed-capsule-rampant-arsenal", count = 1}}
	choices[#choices+1] = {{name="mending-wall-rampant-arsenal",  count = 100}}
	choices[#choices+1] = {{name="reinforced-wall-rampant-arsenal", count = 50}}
	choices[#choices+1] = {{name="shotgun-ammo-turret-rampant-arsenal", count = 4}}
	choices[#choices+1] = {{name="cannon-ammo-turret-rampant-arsenal",  count = 1}}
	choices[#choices+1] = {
		{name="medic-ammo-turret-rampant-arsenal", count = 1},
		{name="self-repair-capsule-ammo-rampant-arsenal", count = 2},
	}
	choices[#choices+1] = {{name="lightning-electric-turret-rampant-arsenal", count = 1}}
	choices[#choices+1] = {{name="capsule-ammo-turret-rampant-arsenal", count = 2}}
end


return choices
