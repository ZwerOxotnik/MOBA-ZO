local techs = {
	"military",
	"logistics",
	"stone-wall",
	"gate",
	"gun-turret",
	"laser-turret",
	"logistic-robotics",
	"logistic-system",
	"heavy-armor",
	"construction-robotics",
	"optics",
	"optics-2", -- From another mod
	"optics-3", -- From another mod
	"cclp", -- From Color_Combinator_Lamp_Posts mod
	"automation",
	"electronics",
	"fast-inserter",
	"automation-2",
	"electric-energy-distribution-1",
	"steel-processing",
	"steel-axe",
	"textplates-steel", -- From textplates mod
	"engine",
	"railway",
	"automated-rail-signals",
	"automated-rail-transportation",
	"trainassembly-automated-train-assembling", -- From trainConstructionSite mod
	"trainfuel-2", -- From trainConstructionSite mod
	"rail-signals",
	"logistic-science-pack",
	"circuit-network",
}

if script.active_mods.Kombat_Drones then
	techs[#techs+1] = "infantry-depot"
end

if script.active_mods.Krastorio2 then
	techs[#techs+1] = "kr-greenhouse"
	techs[#techs+1] = "kr-stone-processing"
	techs[#techs+1] = "kr-crusher"
	techs[#techs+1] = "kr-automation-core"
	techs[#techs+1] = "kr-steam-engine"
	techs[#techs+1] = "kr-electric-mining-drill"
	techs[#techs+1] = "kr-fluids-chemistry"
	techs[#techs+1] = "kr-silicon-processing"
end

if script.active_mods.IndustrialRevolution3 then
	techs[#techs+1] = "ir-charcoal"
	techs[#techs+1] = "ir-grinding"
	techs[#techs+1] = "ir-grinding-2"
	techs[#techs+1] = "ir-steambot"
	techs[#techs+1] = "ir-bronze-furnace"
	techs[#techs+1] = "ir-bronze-forestry"
	techs[#techs+1] = "ir-iron-forestry"
	techs[#techs+1] = "ir-research-1"
	techs[#techs+1] = "ir-gold-milestone"
	techs[#techs+1] = "ir-iron-milestone"
	techs[#techs+1] = "ir-steel-milestone"
	techs[#techs+1] = "ir-crude-oil-processing"
	techs[#techs+1] = "ir-light-oil-processing"
	techs[#techs+1] = "ir-heavy-oil-processing"
	techs[#techs+1] = "ir-lampbot"
	techs[#techs+1] = "ir-graphite"
	techs[#techs+1] = "ir-silicon"
	techs[#techs+1] = "ir-steam-power"
	techs[#techs+1] = "ir-petro-generator"
	techs[#techs+1] = "ir-electronics-1"
	techs[#techs+1] = "ir-iron-motor"
	techs[#techs+1] = "ir-coking"
end


return techs
