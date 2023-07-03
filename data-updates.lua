for _, prototypes in pairs(MOBA_ZO_data.entities_to_items) do
	for _, prototype in pairs(prototypes) do
		prototype.minable = prototype.minable or {
			mining_time = 1, result = prototype.name, count = 1
		}
		MOBA_ZO_data.entity_to_item(prototype)
	end
end
