---@class MOBA_ZO : module
local M = {}


local player_util = require("static-lib/lualibs/LuaPlayer")
local time_util = require("static-lib/lualibs/time-util")


--#region Global game data
local mod_data
local player_HUD_data
--#endregion


local DESTROY_PARAM = {raise_destroy = true}
local COLON = {"colon"}
local LABEL = {type = "label"}
local FLOW = {type = "flow"}
local VERTICAL_FLOW = {type = "flow", direction = "vertical"}
local EMPTY_WIDGET = {type = "empty-widget"}
local SCROLL_PANE = {
	type = "scroll-pane",
	name = "scroll-pane",
	horizontal_scroll_policy = "never"
}
local YELLOW_COLOR = {1, 1, 0}
local CHECK_BUTTON = {
	type = "sprite-button",
	style = "item_and_count_select_confirm",
	sprite = "utility/check_mark"
}
local is_ok, START_PLAYER_ITEMS = pcall(require, "start_player_items")
if not is_ok then
	START_PLAYER_ITEMS = require("__MOBA-ZO__/scenarios/MOBA-ZO/start_player_items")
end
local is_ok, BONUS_CHOICES = pcall(require, "bonus_choices")
if not is_ok then
	BONUS_CHOICES = require("__MOBA-ZO__/scenarios/MOBA-ZO/bonus_choices")
end
local is_ok, START_TECHS = pcall(require, "start_techs")
if not is_ok then
	START_TECHS = require("__MOBA-ZO__/scenarios/MOBA-ZO/start_techs")
end


--#region Util

---@param player_index uint
function delete_reserved_player_character(player_index)
	local  reserved_characters = mod_data.reserved_characters
	local entity = reserved_characters[player_index]
	if not entity then return end
	if entity.valid then
		entity.destroy(DESTROY_PARAM)
	end
	reserved_characters[player_index] = nil
end


---@param player LuaPlayer
function set_player_spectate(player)
	delete_reserved_player_character(player.index)

	local surface = game.get_surface(1)
	player.teleport({0,0}, surface)
	local character = player.character
	if character and character.valid then
		character.destroy(DESTROY_PARAM)
	end

	player.force = "player"
	player.set_controller({
		type = defines.controllers.spectator
	})
	player.spectator = true
end


---@param player LuaPlayer
---@param force LuaForce
function set_team(player, force)
	if player.force == force then
		return
	end

	delete_bonus_GUI(player)
	delete_reserved_player_character(player.index)
	player.force = force
	player_util.create_new_character(player)

	if mod_data.is_battle then
		teleport_to_battle(player)
	else
		teleport_to_preparation_zone(player)
	end
	insert_start_items(player)

	if #force.connected_players == 1 then
		local all_teams_have_players = true
		for _, team_data in pairs(mod_data.teams) do
			if #team_data.force.connected_players == 0 then
				all_teams_have_players = false
				break
			end
		end
		if all_teams_have_players then
			start_round()
		end
	end
end


---@param player LuaPlayer
---@return boolean
function teleport_to_preparation_zone(player)
	local force = player.force
	local force_name = force.name
	local team_data = mod_data.teams[force_name]
	if not team_data then return false end

	local surface = game.get_surface(force_name)
	player_util.delete_character(player)

	-- Set reserved character
	local reserved_character = mod_data.reserved_characters[player.index]
	if reserved_character and reserved_character.valid then
		player.teleport(reserved_character.position, reserved_character.surface)
		player.character = reserved_character
		reserved_character.active = true
	else
		player_util.create_new_character(player)
	end

	player_util.teleport_safely(player, surface, force.get_spawn_position(surface))

	return true
end


---@param force LuaForce
function teleport_force_to_preparation_zone(force)
	for _, player in pairs(force.connected_players) do
		if player.valid then
			teleport_to_preparation_zone(player)
		end
	end
end


---@param player LuaPlayer
---@return boolean
function teleport_to_battle(player)
	local force = player.force
	local force_name = force.name
	local team_data = mod_data.teams[force_name]
	if not team_data then return false end

	local surface = game.get_surface(1)
	local character = player.character
	if character and character.valid and player.surface ~= surface then
		local new_character = character.clone({position=player.position, force=player.force})
		new_character.active = false
		if new_character and new_character.valid then
			mod_data.reserved_characters[player.index] = new_character
		end
	end

	player_util.teleport_safely(player, surface, force.get_spawn_position(surface))

	return true
end


---@param force LuaForce
function teleport_force_to_battle(force)
	for _, player in pairs(force.connected_players) do
		if player.valid then
			teleport_to_battle(player)
		end
	end
end


---@param main_teleport table
---@param teleport_entities table
---@param player LuaPlayer
---@param target_branch number?
---@param original_branch number?
---@return boolean
function teleport_to_branch(main_teleport, teleport_entities, player, target_branch, original_branch)
	if target_branch == nil then
		if original_branch == 1 then
			target_branch = #teleport_entities
		else
			target_branch = original_branch-1
		end
	end

	for _ = 1, #teleport_entities-1 do
		local teleports = teleport_entities[target_branch]
		for j = #teleports, 1, -1 do
			local teleport = teleports[j]
			if teleport and teleport.valid then
				return player_util.teleport_safely(player, teleport.surface, teleport.position)
			end
		end

		if target_branch == 1 then
			target_branch = #teleport_entities
		else
			target_branch = original_branch-1
		end
	end

	if main_teleport and main_teleport.valid then
		return player_util.teleport_safely(player, main_teleport.surface, main_teleport.position)
	end

	return false
end


---@param entity LuaEntity
---@param player LuaPlayer
---@return boolean
function use_teleport(entity, player)
	local force_name = entity.force.name
	local team_data = mod_data.teams[force_name]
	local teleport_entities = team_data.teleport_entities
	local main_teleport = team_data.main_teleport

	for iter = 1, 2 do
		if iter == 2 then
			teleport_entities = team_data.safe_teleport_entities
			main_teleport = team_data.safe_main_teleport
		end

		local teleport = main_teleport
		if teleport and teleport.valid and entity == teleport then
			return teleport_to_branch(main_teleport, teleport_entities, player, math.random(1, #teleport_entities))
		end

		for i = 1, #teleport_entities do
			local teleports = teleport_entities[i]
			for j = 1, #teleports do
				local teleport = teleports[j]
				if teleport and teleport.valid and entity == teleport then
					return teleport_to_branch(main_teleport, teleport_entities, player, nil, i)
				end
			end
		end
	end

	return false
end


function start_round()
	if mod_data.is_battle then
		return
	end
	mod_data.is_battle = true
	mod_data.is_preparation_state = false
	mod_data.end_preparation_tick = nil
	mod_data.end_round_tick = game.tick + 60 * game.speed * 60 * 10
	for _, player in pairs(game.connected_players) do
		if player.valid then
			hide_preparation_HUD(player)
			show_round_HUD(player)
		end
	end

	for _, team_data in ipairs(mod_data.teams) do
		for _, player in pairs(team_data.force.connected_players) do
			delete_bonus_GUI(player)
		end
	end

	local scenario_lobby = game.get_surface("scenario_lobby")
	local surface = game.get_surface(1)
	local clone_data = {destination_surface=surface, clone_entities=true, clone_tiles=false}
	for i = 1, mod_data.count_teams do
		local team_data = mod_data.teams["team" .. i]
		teleport_players(team_data.force, scenario_lobby)
	end

	for i = 1, mod_data.count_teams do
		local team_data = mod_data.teams["team" .. i]
		clone_data.source_area      = team_data.territory
		clone_data.destination_area = team_data.territory
		team_data.safe_surface.clone_area(clone_data)

		local entity = team_data.safe_main_teleport
		entity = surface.find_entity("rocket-silo", entity.position)
		mod_data.end_trigger_entities[script.register_on_entity_destroyed(entity)] = i
		team_data.force.set_spawn_position(entity.position, surface)
		team_data.main_teleport = entity
		entity.destructible = true
		entity.rotatable = false
		entity.minable   = false

		for i2 = 1, #team_data.safe_teleport_entities do
			local branch = team_data.safe_teleport_entities[i2]
			for j2 = 1, #branch do
				local entity = branch[j2]
				entity = surface.find_entity("rocket-silo", entity.position)
				team_data.teleport_entities[i2][j2] = entity
				entity.destructible = true
				entity.rotatable = false
				entity.minable   = false
			end
		end
	end

	local entities = surface.find_entities()
	for i = 1, #entities do
		entities[i].active = true
	end

	for i = 1, mod_data.count_teams do
		local team_data = mod_data.teams["team" .. i]
		teleport_force_to_battle(team_data.force)
	end

	game.print("New round starts") -- TODO: add localization
end


function end_round()
	if not mod_data.is_battle then return end
	mod_data.is_battle = false
	mod_data.is_preparation_state = true
	mod_data.current_round = mod_data.current_round + 1
	mod_data.end_round_tick = nil
	mod_data.end_preparation_tick = game.tick + 60 * game.speed * 60 * 2
	update_player_wave_HUD()

	local is_valid_amount_of_players = true
	for _, team_data in ipairs(mod_data.teams) do
		if #team_data.force.connected_players == 0 then
			is_valid_amount_of_players = false
			break
		end
	end

	if is_valid_amount_of_players then
		for _, player in pairs(game.connected_players) do
			if player.valid then
				show_preparation_HUD(player)
				hide_round_HUD(player)
			end
		end
	else
		not_enough_players()
	end

	for i = 1, mod_data.count_teams do
		local mod_data = mod_data.teams["team" .. i]
		teleport_force_to_preparation_zone(mod_data.force)
	end

	local average_player_count = 0
	for _, team_data in ipairs(mod_data.teams) do
		average_player_count = average_player_count + #team_data.force.connected_players
	end
	average_player_count = average_player_count / #mod_data.teams

	local loser_team
	for _, team_data in ipairs(mod_data.teams) do
		local main_teleport = team_data.main_teleport
		if not (main_teleport and main_teleport.valid) then
			loser_team = team_data.force
		end
	end

	if not loser_team then
		local prev_max_count = 0
		for _, team_data in ipairs(mod_data.teams) do
			local destroyed_teleports = 0
			for _, teleports in ipairs(team_data.teleport_entities) do
				for _, teleport in ipairs(teleports) do
					if not (teleport and teleport.valid) then
						destroyed_teleports = destroyed_teleports + 1
					end
				end
			end
			if destroyed_teleports > prev_max_count then
				loser_team = team_data.force
				prev_max_count = destroyed_teleports
			elseif destroyed_teleports == prev_max_count then
				loser_team = nil
			end
		end
	end

	if loser_team then
		-- give bonus to loser team
		local multiplier = average_player_count / #loser_team.connected_players
		local count = math.max(math.floor(3 * multiplier), 1)
		for _, player in pairs(loser_team.connected_players) do
			if count == 1 then
				give_bonus(player, nil, multiplier)
			else
				create_pick_bonus_GUI(player, count, multiplier)
			end
		end
		loser_team.print("Your team got bonuses") -- TODO: add localization
	else
		-- give bonus to all teams
		for _, team_data in ipairs(mod_data.teams) do
			local force = team_data.force
			local multiplier = average_player_count / #force.connected_players
			local count = math.max(math.floor(3 * multiplier), 1)
			for _, player in pairs(force.connected_players) do
				if count == 1 then
					give_bonus(player, nil, multiplier)
				else
					create_pick_bonus_GUI(player, count, multiplier)
				end
			end
			force.print("Your team got bonuses") -- TODO: add localization
		end
	end

	local surface = game.get_surface(1)
	local entities = surface.find_entities()
	for i = 1, #entities do
		entities[i].destroy(DESTROY_PARAM)
	end
end


function reset_forces_data()
	for _, force in pairs(game.forces) do
		local team_data = mod_data.teams[force.name]
		force.reset()
		force.reset_evolution() -- is this useful?
		force.friendly_fire = false

		-- set bonuses
		force.manual_mining_speed_modifier = 10
		force.manual_crafting_speed_modifier = mod_data.manual_crafting_speed_modifier
		force.laboratory_speed_modifier = 4
		force.worker_robots_speed_modifier = 2
		force.character_item_pickup_distance_bonus = 2
		force.character_inventory_slots_bonus = 50
		-- force.mining_drill_productivity_bonus = 100
		force.character_health_bonus = 200
		force.set_ammo_damage_modifier("flamethrower", -0.9)

		-- research technologies
		local technologies = force.technologies
		for _, tech_name in pairs(M.start_techs or START_TECHS) do
			local tech = technologies[tech_name]
			if tech then
				tech.researched = true
			end
		end

		if team_data then
			force.chart_all(team_data.safe_surface)
		end
	end
end


function not_enough_players()
	mod_data.end_preparation_tick = nil
	for _, _player in pairs(game.connected_players) do
		if _player.valid then
			hide_preparation_HUD(_player)
			hide_round_HUD(_player)
		end
	end
	game.print("One of team doesn't have players", YELLOW_COLOR) -- TODO: add localization
end


---@param teams_table LuaGuiElement
---@param player LuaPlayer
function update_teams_table(teams_table, player)
	teams_table.clear()

	for i=1, mod_data.count_teams do
		teams_table.add(LABEL).caption = {"MOBA-ZO-HUD.team" .. i}
	end
	teams_table.add(LABEL).caption = {"spectators"}

	local scroll_panel1 = teams_table.add(SCROLL_PANE)
	scroll_panel1.name = scroll_panel1.name .. "1"
	scroll_panel1.style.maximal_height = 145
	local scroll_panel2 = teams_table.add(SCROLL_PANE)
	scroll_panel2.name = scroll_panel2.name .. "2"
	scroll_panel2.style.maximal_height = 145
	local scroll_panel3 = teams_table.add(SCROLL_PANE)
	scroll_panel3.name = scroll_panel3.name .. "3"
	scroll_panel3.style.maximal_height = 145

	local team1_frame = scroll_panel1.add{type = "frame", name = "team1_frame", style = "deep_frame_in_shallow_frame", direction = "vertical"}
	team1_frame.style.left_padding  = 8
	team1_frame.style.right_padding = 8
	local team1_table = team1_frame.add{type = "table", name = "team1_table", column_count = 1}
	team1_table.style.horizontally_stretchable = true
	team1_table.style.vertically_stretchable = true
	team1_table.style.column_alignments[1] = "center"

	local team2_frame = scroll_panel2.add{type = "frame", name = "team2_frame", style = "deep_frame_in_shallow_frame", direction = "vertical"}
	team2_frame.style.left_padding  = 8
	team2_frame.style.right_padding = 8
	local team2_table = team2_frame.add{type = "table", name = "team2_table", column_count = 1}
	team2_table.style.horizontally_stretchable = true
	team2_table.style.vertically_stretchable = true
	team2_table.style.column_alignments[1] = "center"

	local spectators_frame = scroll_panel3.add{type = "frame", name = "spectators_frame", style = "deep_frame_in_shallow_frame", direction = "vertical"}
	spectators_frame.style.left_padding  = 8
	spectators_frame.style.right_padding = 8
	local spectators_table = spectators_frame.add{type = "table", name = "spectators_table", column_count = 1}
	spectators_table.style.horizontally_stretchable = true
	spectators_table.style.vertically_stretchable = true
	spectators_table.style.column_alignments[1] = "center"

	for _, _player in pairs(game.forces.team1.connected_players) do
		if _player.valid then
			team1_table.add(LABEL).caption = _player.name
		end
	end

	for _, _player in pairs(game.forces.team2.connected_players) do
		if _player.valid then
			team2_table.add(LABEL).caption = _player.name
		end
	end

	for _, _player in pairs(game.forces.player.connected_players) do
		if _player.valid then
			spectators_table.add(LABEL).caption = _player.name
		end
	end

	local button
	if player.force.name == "team1" then
		teams_table.add(EMPTY_WIDGET)
	else
		button = teams_table.add(CHECK_BUTTON)
		button.name = "MOBA_ZO_pick_team1"
		button.tooltip = {"join-team"}
	end

	if player.force.name == "team2" then
		teams_table.add(EMPTY_WIDGET)
	else
		button = teams_table.add(CHECK_BUTTON)
		button.name = "MOBA_ZO_pick_team2"
		button.tooltip = {"join-team"}
	end

	if player.force.name == "player" then
		teams_table.add(EMPTY_WIDGET)
	else
		button = teams_table.add(CHECK_BUTTON)
		button.name = "MOBA_ZO_pick_spectators"
		button.tooltip = {"join-spectator"}
	end
end


---@param bonus_table LuaGuiElement
---@param choices_count integer
---@param multiplier number
function update_bonus_table(bonus_table, choices_count, multiplier)
	bonus_table.clear()

	local bonuses_for_selection = {}
	local bonuses = mod_data.bonuses
	local deep_frame = {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical"}
	local elem_button = {type = "choose-elem-button", elem_type = "item", item = ""}
	while true do
		local r_number = math.random(1, #bonuses)
		if bonuses_for_selection[r_number] then
			goto continue
		end
		local bonus = bonuses[r_number]
		bonuses_for_selection[r_number] = bonus
		choices_count = choices_count - 1

		local vertical_flow = bonus_table.add(VERTICAL_FLOW)
		vertical_flow.style.horizontal_align = "center"
		local _deep_frame = vertical_flow.add(deep_frame)
		_deep_frame.style.vertically_stretchable = true
		_deep_frame.style.right_padding = 8
		for i = 1, #bonus do
			local item = bonus[i]
			elem_button.item = item.name
			local count = math.floor(item.count * multiplier)
			if count <= 1 then
				_deep_frame.add(elem_button).locked = true
				goto continue
			end
			local flow = _deep_frame.add(FLOW)
			flow.add(elem_button).locked = true
			flow.add(LABEL).caption = "x " .. count
			:: continue ::
		end

		vertical_flow.name = tostring(bonus.id)
		button = vertical_flow.add(CHECK_BUTTON)
		button.name = "MOBA_ZO_pick_bonus"
		button.tooltip = {"MOBA-ZO-HUD.pick-bonus"}

		if choices_count == 0 then
			break
		end
		:: continue ::
	end
end


function check_player_data()
	for player_index in pairs(mod_data.player_HUD_data) do
		local player = game.get_player(player_index)
		if not (player and player.valid and player.connected) then
			player_HUD_data[player_index] = nil
		end
	end

	for player_index, entity in pairs(mod_data.reserved_characters) do
		local player = game.get_player(player_index)
		if not (player and player.valid and player.connected and entity and entity.valid) then
			if entity and entity.valid then
				entity.destroy(DESTROY_PARAM)
			end
			mod_data.reserved_characters[player_index] = nil
		end
	end
end


function update_player_wave_HUD()
	local next_round = tostring(mod_data.current_round + 1)
	for _, HUDs in pairs(player_HUD_data) do
		HUDs[1].caption = next_round
	end
end


function insert_start_items(player)
	local item_prototypes = game.item_prototypes
	for _, item_data in ipairs(M.start_player_items or START_PLAYER_ITEMS) do
		if item_prototypes[item_data.name] then
			player.insert(item_data)
		else
			log(item_data.name .. " is invalid")
		end
	end
end


function delete_settings_gui()
	for _, player in pairs(game.players) do
		if player.valid then
			local frame = player.gui.center.MOBA_ZO_scenario_settings_frame
			if frame and frame.valid then
				frame.destroy()
			end
		end
	end
end


---@param force LuaForce
---@param surface LuaSurface
function teleport_players_safely(force, surface)
	local target_position = force.get_spawn_position(surface)
	return player_util.teleport_players_safely(force.connected_players, surface, target_position)
end


---@param force LuaForce
---@param surface LuaSurface
function teleport_players(force, surface)
	local target_position = force.get_spawn_position(surface)
	return player_util.teleport_players(force.connected_players, surface, target_position)
end


function set_game_rules_by_settings()
	local surface = game.get_surface(1)

	local player_force = game.forces.player
	player_force.chart_all(surface)
end

--#endregion


--#region Functions of events

---@param player LuaPlayer
function hide_preparation_HUD(player)
	player.gui.screen.MOBA_ZO_preparation_HUD.visible = false
end


---@param player LuaPlayer
function show_preparation_HUD(player)
	player.gui.screen.MOBA_ZO_preparation_HUD.visible = true
end


---@param player LuaPlayer
function create_preparation_HUD(player)
	local screen = player.gui.screen
	local prev_location
	if screen.MOBA_ZO_preparation_HUD then
		prev_location = screen.MOBA_ZO_preparation_HUD.location
		screen.MOBA_ZO_preparation_HUD.destroy()
	end

	local main_frame = screen.add{type = "frame", name = "MOBA_ZO_preparation_HUD", direction = "horizontal"}
	main_frame.location = prev_location or {x = 50, y = 50}
	main_frame.style.padding = 0
	if mod_data.end_round_tick then
		main_frame.visible = true
	else
		main_frame.visible = false
	end
	local draggable_space = main_frame.add({type = "empty-widget", style = "draggable_space"})
	draggable_space.style.width = 15
	draggable_space.style.height = 20
	draggable_space.style.margin = 0
	draggable_space.drag_target = main_frame

	main_frame.add(LABEL).caption = {"MOBA-ZO-HUD.Round"}
	local wave_label = main_frame.add(LABEL)
	wave_label.caption = tostring(mod_data.current_round)
	main_frame.add(LABEL).caption = {"MOBA-ZO-HUD.in"}
	local time_label = main_frame.add(LABEL)
	if mod_data.end_round_tick then
		time_label.caption = time_util.ticks_to_game_mm_ss(mod_data.end_round_tick - game.tick)
	else
		time_label.caption = "00:00"
	end

	player_HUD_data[player.index] = player_HUD_data[player.index] or {}
	local _player_HUD_data = player_HUD_data[player.index]
	_player_HUD_data[1] = wave_label
	_player_HUD_data[2] = time_label
end


---@param player LuaPlayer
function hide_round_HUD(player)
	player.gui.screen.MOBA_ZO_round_HUD.visible = false
end


---@param player LuaPlayer
function show_round_HUD(player)
	player.gui.screen.MOBA_ZO_round_HUD.visible = true
end


---@param player LuaPlayer
function create_round_HUD(player)
	local screen = player.gui.screen
	local prev_location
	if screen.MOBA_ZO_round_HUD then
		prev_location = screen.MOBA_ZO_round_HUD.location
		screen.MOBA_ZO_round_HUD.destroy()
	end

	local main_frame = screen.add{type = "frame", name = "MOBA_ZO_round_HUD", direction = "horizontal"}
	main_frame.location = prev_location or {x = 70, y = 50}
	main_frame.style.padding = 0
	if mod_data.end_preparation_tick then
		main_frame.visible = true
	else
		main_frame.visible = false
	end
	local draggable_space = main_frame.add({type = "empty-widget", style = "draggable_space"})
	draggable_space.style.width = 15
	draggable_space.style.height = 20
	draggable_space.style.margin = 0
	draggable_space.drag_target = main_frame

	main_frame.add(LABEL).caption = {"", {"time_left"}, {"colon"}}
	local time_label = main_frame.add(LABEL)
	if mod_data.end_preparation_tick then
		time_label.caption = time_util.ticks_to_game_mm_ss(mod_data.end_preparation_tick - game.tick)
	else
		time_label.caption = "00:00"
	end

	player_HUD_data[player.index] = player_HUD_data[player.index] or {}
	local _player_HUD_data = player_HUD_data[player.index]
	_player_HUD_data[3] = time_label
end

---@param player LuaPlayer
function delete_pick_team_GUI(player)
	local screen = player.gui.screen
	local frame = screen.MOBA_ZO_pick_team_frame
	if frame and frame.valid then
		frame.destroy()
	end
end

---@param player LuaPlayer
function delete_bonus_GUI(player)
	local screen = player.gui.screen
	local frame = screen.MOBA_ZO_pick_bonus_frame
	if frame and frame.valid then
		frame.destroy()
	end
end

---@param player LuaPlayer
---@param bonus_id integer?
---@param multiplier number
---@return boolean
function give_bonus(player, bonus_id, multiplier)
	local bonus
	if bonus_id then
		local bonuses = mod_data.bonuses
		for i=1, #bonuses do
			local _bonus = bonuses[i]
			if _bonus.id == bonus_id then
				bonus = _bonus
				break
			end
		end

		if not bonus then
			return false
		end
	else
		bonus = mod_data.bonuses[math.random(1, #mod_data.bonuses)]
	end


	local stack = {name="", count=1}
	for i = 1, #bonus do
		local item = bonus[i]
		stack.name = item.name
		local count = math.floor(item.count * multiplier)
		if count < 1 then
			stack.count = 1
		else
			stack.count = count
		end
		player.insert(stack)
	end

	return true
end


---@param player LuaPlayer
function create_pick_team_GUI(player)
	local screen = player.gui.screen
	local prev_location
	if screen.MOBA_ZO_pick_team_frame then
		prev_location = screen.MOBA_ZO_pick_team_frame.location
		screen.MOBA_ZO_pick_team_frame.destroy()
	end

	local main_frame = screen.add{type = "frame", name = "MOBA_ZO_pick_team_frame", direction = "vertical"}
	-- main_frame.style.horizontal_spacing = 0 -- it doesn't work
	main_frame.style.padding = 4

	local top_flow = main_frame.add{type = "flow"}
	top_flow.style.horizontal_spacing = 0
	-- top_flow.add{
	-- 	type = "label",
	-- 	style = "frame_title",
	-- 	caption = {""},
	-- 	ignored_by_interaction = true
	-- }
	local drag_handler = top_flow.add{type = "empty-widget", name = "drag_handler", style = "draggable_space"}
	drag_handler.drag_target = main_frame
	drag_handler.style.horizontally_stretchable = true
	drag_handler.style.vertically_stretchable   = true
	drag_handler.style.margin = 0
	top_flow.add{
		hovered_sprite = "utility/close_black",
		clicked_sprite = "utility/close_black",
		sprite = "utility/close_white",
		style = "frame_action_button",
		type = "sprite-button",
		name = "MOBA_ZO_close"
	}

	local shallow_frame = main_frame.add{type = "frame", name = "shallow_frame", style = "inside_shallow_frame"}
	shallow_frame.style.padding = 8
	local teams_table = shallow_frame.add{type = "table", name = "teams_table", column_count = 3}
	teams_table.style.horizontal_spacing = 6
	teams_table.style.horizontally_stretchable = true
	teams_table.style.vertically_stretchable = true
	teams_table.style.column_alignments[1] = "center"
	teams_table.style.column_alignments[2] = "center"
	teams_table.style.column_alignments[3] = "center"
	-- teams_table.draw_horizontal_lines = true
	-- teams_table.draw_vertical_lines = true
	teams_table.visible = true

	update_teams_table(teams_table, player)

	if prev_location then
		main_frame.location = prev_location
	else
		main_frame.force_auto_center()
	end
end


---@param player LuaPlayer
---@param choices_count integer
---@param multiplier number? # 1 dy default
function create_pick_bonus_GUI(player, choices_count, multiplier)
	multiplier = multiplier or 1
	local screen = player.gui.screen
	local prev_location
	if screen.MOBA_ZO_pick_bonus_frame then
		prev_location = screen.MOBA_ZO_pick_bonus_frame.location
		screen.MOBA_ZO_pick_bonus_frame.destroy()
	end

	local main_frame = screen.add{type = "frame", name = "MOBA_ZO_pick_bonus_frame", direction = "vertical"}
	main_frame.style.padding = 4

	local top_flow = main_frame.add{type = "flow"}
	top_flow.style.horizontal_spacing = 0
	top_flow.add{
		type = "label",
		style = "frame_title",
		caption = {"MOBA-ZO-HUD.Bonuses"},
		ignored_by_interaction = true
	}
	local drag_handler = top_flow.add{type = "empty-widget", name = "drag_handler", style = "draggable_space"}
	drag_handler.drag_target = main_frame
	drag_handler.style.horizontally_stretchable = true
	drag_handler.style.vertically_stretchable   = true
	drag_handler.style.margin = 0

	local shallow_frame = main_frame.add{type = "frame", name = "shallow_frame", style = "inside_shallow_frame"}
	shallow_frame.style.padding = 8
	local bonus_table = shallow_frame.add{type = "table", name = "bonus_table", column_count = choices_count}
	bonus_table.style.horizontal_spacing = 6
	bonus_table.style.horizontally_stretchable = true
	bonus_table.style.vertically_stretchable = true
	for i = 1, choices_count do
		bonus_table.style.column_alignments[i] = "center"
	end
	-- teams_table.draw_horizontal_lines = true
	-- teams_table.draw_vertical_lines = true
	bonus_table.visible = true

	update_bonus_table(bonus_table, choices_count, multiplier)

	if prev_location then
		main_frame.location = prev_location
	else
		main_frame.force_auto_center()
	end
end

local function create_lobby_settings_GUI(player)
	local center = player.gui.center
	if center.MOBA_ZO_scenario_settings_frame then
		return
	end

	local main_frame = center.add{type = "frame", name = "MOBA_ZO_scenario_settings_frame", direction = "vertical"}

	local textfield_content = main_frame.add{type = "table", name = "MOBA_ZO_textfield_content", column_count = 2}

	textfield_content.add(LABEL).caption = {'', "Manual crafting speed modifier", COLON} -- TODO: FIX locale
	textfield_content.add{type = "textfield", name = "MOBA_ZO_manual_crafting_speed_modifier_textfield", text = mod_data.manual_crafting_speed_modifier or 5, numeric = true, allow_decimal = true, allow_negative = false}.style.maximal_width = 70

	local content3 = main_frame.add{type = "table", name = "MOBA_ZO_content3", column_count = 3}

	local empty = content3.add(EMPTY_WIDGET)
	empty.style.right_margin = 0
	empty.style.horizontally_stretchable = true

	local confirm_button = content3.add{type = "button", caption = {"gui.confirm"}}
	confirm_button.name = "MOBA_ZO_update_settings"
	local empty = content3.add(EMPTY_WIDGET)
	empty.style.right_margin = 0
	empty.style.horizontally_stretchable = true
end

local function on_player_joined_game(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	if #game.connected_players == 1 then
		check_player_data()
	end

	create_pick_team_GUI(player)
	create_round_HUD(player)
	create_preparation_HUD(player)
end

local function on_player_left_game(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	mod_data.player_HUD_data[player_index] = nil

	local team_data = mod_data.teams[player.force.name]
	if team_data and #player.force.connected_players == 0 and mod_data.is_preparation_state then
		not_enough_players()
	end

	set_player_spectate(player)
end

local function on_gui_opened(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end
	if entity.name ~= "rocket-silo"  then return end

	use_teleport(entity, player)
end

local function on_player_created(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	player.print({"MOBA-ZO.wip_message"}, YELLOW_COLOR)

	set_player_spectate(player)
end

local function on_player_removed(event)
	local player_index = event.player_index
	player_HUD_data[player_index] = nil
	delete_reserved_player_character(player_index)
end

local function on_built_entity(event)
	local entity = event.created_entity or event.entity
	if not entity.valid then return end
	local surface = entity.surface
	if surface.index == 1 then return end

	entity.active = false
end

local function on_game_created_from_scenario()
	local surface = game.get_surface(1)

	mod_data.last_round_tick = game.tick
	mod_data.generate_new_round = false

	reset_forces_data()

	delete_settings_gui()
	for _, player in pairs(game.players) do
		if player.valid then
			create_lobby_settings_GUI(player)
		end
	end

	for i, team_data in ipairs(mod_data.teams) do
		if team_data.safe_main_teleport == nil then
			local entity
			entity = game.get_entity_by_tag("R1-" .. i)
			team_data.force.set_spawn_position(entity.position, entity.surface)
			team_data.force.chart_all(surface)
			entity.destructible = false
			entity.rotatable = false
			entity.minable   = false
			team_data.safe_main_teleport = entity
			entity = entity.surface.create_entity{
				name = "electric-energy-interface", force = entity.force,
				position = entity.position
			}
			entity.minable = false
			entity.operable = false
			entity.destructible = true
			entity.power_production = 5000000
			entity.electric_buffer_size = 5000000
			entity.power_usage = 0

			for i2 = 1, 2 do
				for j2 = 1, 2 do
					entity = game.get_entity_by_tag("R" .. i2 .. "." .. j2 .. "-".. i)
					entity.destructible = false
					entity.rotatable = false
					entity.minable   = false
					team_data.safe_teleport_entities[i2][j2] = entity

					entity = entity.surface.create_entity{
						name = "electric-energy-interface", force = entity.force,
						position = entity.position
					}
					entity.minable = false
					entity.operable = false
					entity.destructible = true
					entity.power_production = 5000000
					entity.electric_buffer_size = 5000000
					entity.power_usage = 0
				end
			end
		end
	end

	mod_data.is_new_map_changes = false
end


local function on_entity_destroyed(event)
	if not mod_data.is_battle then return end
	if not mod_data.end_trigger_entities[event.registration_number] then
		return
	end

	end_round()
end


local GUIS = {
	MOBA_ZO_close = function(element)
		element.parent.parent.destroy()
	end,
	MOBA_ZO_update_settings = function(element, player, event)
		if player.admin then
			local main_frame = player.gui.center.MOBA_ZO_scenario_settings_frame
			local textfield_content = main_frame.MOBA_ZO_textfield_content
			local manual_crafting_speed_modifier_textfield = textfield_content.MOBA_ZO_manual_crafting_speed_modifier_textfield

			local manual_crafting_speed_modifier = tonumber(manual_crafting_speed_modifier_textfield.text) or 0
			if manual_crafting_speed_modifier < 0.001 then
				manual_crafting_speed_modifier = 0.001
			elseif manual_crafting_speed_modifier > 1000 then
				manual_crafting_speed_modifier = 1000
			end
			mod_data.manual_crafting_speed_modifier = manual_crafting_speed_modifier
			for _, force in pairs(game.forces) do
				force.manual_crafting_speed_modifier = manual_crafting_speed_modifier
			end
		end

		local frame = player.gui.center.MOBA_ZO_scenario_settings_frame
		if frame and frame.valid then
			frame.destroy()
		end
	end,
	MOBA_ZO_pick_team1 = function(element, player, event)
		delete_pick_team_GUI(player)
		set_team(player, game.forces.team1)
	end,
	MOBA_ZO_pick_team2 = function(element, player, event)
		delete_pick_team_GUI(player)
		set_team(player, game.forces.team2)
	end,
	MOBA_ZO_pick_spectators = function(element, player, event)
		delete_pick_team_GUI(player)
		set_player_spectate(player)
	end,
	MOBA_ZO_pick_bonus = function(element, player, event)
		local bonus_id = tonumber(element.parent.name)
		delete_bonus_GUI(player)
		give_bonus(player, bonus_id, 1)
	end,
}
local function on_gui_click(event)
	local element = event.element
	if not (element and element.valid) then return end
	local player = game.get_player(event.player_index)

	local f = GUIS[element.name]
	if f then
		f(element, player, event)
	end
end

--#endregion


commands.add_command("change-settings", {"MOBA-ZO-commands.change-settings"}, function(cmd)
	if cmd.player_index == 0 then -- server
		return
	end

	local player = game.get_player(cmd.player_index)
	if not (player and player.valid) then return end
	if player.admin == false then
		player.print({"command-output.parameters-require-admin"}, {1, 0, 0})
		return
	end

	create_lobby_settings_GUI(player)
end)

commands.add_command("start-round", {"MOBA-ZO-commands.start-round"}, function(cmd)
	if cmd.player_index == 0 then -- server
		start_round()
		return
	end

	local player = game.get_player(cmd.player_index)
	if not (player and player.valid) then return end
	if player.admin == false then
		player.print({"command-output.parameters-require-admin"}, {1, 0, 0})
		return
	end

	start_round()
end)

commands.add_command("end-round", {"MOBA-ZO-commands.end-round"}, function(cmd)
	if cmd.player_index == 0 then -- server
		end_round()
		return
	end

	local player = game.get_player(cmd.player_index)
	if not (player and player.valid) then return end
	if player.admin == false then
		player.print({"command-output.parameters-require-admin"}, {1, 0, 0})
		return
	end

	end_round()
end)

commands.add_command("change-team", {"MOBA-ZO-commands.change-team"}, function(cmd)
	if cmd.player_index == 0 then -- server
		-- WIP
		return
	end

	local player = game.get_player(cmd.player_index)
	if not (player and player.valid) then return end

	local screen = player.gui.screen
	if screen.MOBA_ZO_pick_team_frame then
		screen.MOBA_ZO_pick_team_frame.destroy()
		return
	end
	create_pick_team_GUI(player)
end)


function check_timers()
	local end_round_tick = mod_data.end_round_tick
	local end_preparation_tick = mod_data.end_preparation_tick
	if end_round_tick then
		local ticks = end_round_tick - game.tick
		local time = time_util.ticks_to_game_mm_ss(ticks)

		for _, HUDs in pairs(player_HUD_data) do
			HUDs[3].caption = time
		end

		if ticks <= 0 then
			end_round()
		end
	elseif end_preparation_tick then
		local ticks = end_preparation_tick - game.tick
		local time = time_util.ticks_to_game_mm_ss(ticks)
		for _, HUDs in pairs(player_HUD_data) do
			HUDs[2].caption = time
		end

		if ticks <= 0 then
			start_round()
		end
	end
end


--#region Pre-game stage


function add_event_filters()
end


function link_data()
	mod_data = global.MOBA_ZO
	player_HUD_data = mod_data.player_HUD_data
end


function update_global_data()
	local surface = game.get_surface(1)
	surface.generate_with_lab_tiles = true

	global.MOBA_ZO = global.MOBA_ZO or {}
	mod_data = global.MOBA_ZO
	mod_data.current_round = mod_data.current_round or 0
	mod_data.count_teams = mod_data.count_teams or 2
	mod_data.is_battle = mod_data.is_battle or false
	mod_data.is_preparation_state = mod_data.is_preparation_state or false
	mod_data.end_round_tick = mod_data.end_round_tick
	mod_data.tech_price_multiplier = mod_data.tech_price_multiplier or 1
	mod_data.manual_crafting_speed_modifier = mod_data.manual_crafting_speed_modifier or 5
	mod_data.generate_new_round = mod_data.generate_new_round or false
	mod_data.is_new_map_changes = mod_data.is_new_map_changes or true
	mod_data.player_HUD_data = mod_data.player_HUD_data or {}
	mod_data.last_round_tick = mod_data.last_round_tick or game.tick
	mod_data.generate_new_round_tick = mod_data.generate_new_round_tick
	---@type table<uint, LuaEntity>
	mod_data.reserved_characters = mod_data.reserved_characters or {}
	---@type table<uint64, LuaEntity>
	mod_data.end_trigger_entities = mod_data.end_trigger_entities or {}

	if game then
		if mod_data.teams == nil then
			mod_data.teams = mod_data.teams or {}
			for i=1, mod_data.count_teams do
				mod_data.teams[i] = {
					territory = nil,
					safe_surface = game.surfaces["team" .. i],
					main_teleport = nil,
					teleport_entities = {{nil, nil}, {nil, nil}},
					safe_main_teleport = nil,
					safe_teleport_entities = {{nil, nil}, {nil, nil}},
					force = game.forces["team" .. i],
				}
				mod_data.teams["team" .. i] = mod_data.teams[i]
			end
			mod_data.teams[1].territory = {{x = -1000, y = -100}, right_bottom = {x = 0, y = 700}}
			mod_data.teams[2].territory = {{x = 0, y = -100}, right_bottom = {x = 1000, y = 700}}
		end

		mod_data.bonuses = {}
		local bonuses = mod_data.bonuses
		local item_prototypes = game.item_prototypes
		local last_id = 0
		for _, items in ipairs(M.bonus_choices or BONUS_CHOICES) do
			for i = 1, #items do
				local item = items[i]
				if not item_prototypes[item.name] then
					log(item.name .. " is invalid")
					goto continue
				end
			end
			bonuses[#bonuses+1] = items
			last_id = last_id + 1
			items.id = last_id
			:: continue ::
		end
	end

	link_data()

	check_player_data()
end


local function add_remote_interface()
	-- https://lua-api.factorio.com/latest/LuaRemote.html
	remote.remove_interface("MOBA-ZO") -- For safety
	remote.add_interface("MOBA-ZO", {})
end
M.add_remote_interface = add_remote_interface

M.on_init = function()
	update_global_data()
	reset_forces_data()
	add_event_filters()
end
M.on_load = function()
	link_data()
	add_event_filters()
end
M.on_configuration_changed = function()
	delete_settings_gui()
end


M.events = {
	[defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
	[defines.events.on_player_joined_game] = on_player_joined_game,
	[defines.events.on_player_left_game] = on_player_left_game,
	[defines.events.on_gui_opened] = on_gui_opened,
	[defines.events.on_player_created] = on_player_created,
	[defines.events.on_player_removed] = on_player_removed,
	[defines.events.on_built_entity] = on_built_entity,
	[defines.events.on_robot_built_entity] = on_built_entity,
	[defines.events.script_raised_built] = on_built_entity,
	[defines.events.on_gui_click] = on_gui_click,
	[defines.events.on_entity_destroyed] = on_entity_destroyed,
}
M.on_nth_tick = {
	[60] = check_timers
}


return M
