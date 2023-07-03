MOBA_ZO_data = {
	entities_to_items = {
		data.raw.unit,
		data.raw.turret,
	},
	entity_to_item = function(_data)
		local item = {
			type = "item",
			name = _data.name,
			icon = _data.icon,
			icons = _data.icons,
			icon_size = _data.icon_size or 64,
			icon_mipmaps = _data.icon_mipmaps,
			order = "a",
			place_result = _data.name,
			stack_size = 10,
			flags = {"hidden"}
		}
		data:extend({item})
	end,
}
MOBA_ZO_data._entity_to_item = MOBA_ZO_data.entity_to_item
