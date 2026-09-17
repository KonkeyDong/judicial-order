package game

import "defs"
import "sprites"
import "timers"
import unit_pkg "unit"

select_magic_enter :: proc(game: ^Game) {
	current := game_current_unit(game)
	magic_ui_reset_layout_center(game)
	magic_ui_set_selected(game, .Up, current)
	if current != nil {
		grid_calculate_magic_attack_range(&game.grid, current, magic_ui_selected_data(game))
	}
}

select_magic_exit :: proc(_: ^Game) {}

select_magic_set :: proc(game: ^Game, direction: defs.Direction) {
	current := game_current_unit(game)
	magic_ui_set_selected(game, direction, current)
	if current != nil {
		grid_calculate_magic_attack_range(&game.grid, current, magic_ui_selected_data(game))
	}
}

select_magic_handle_input :: proc(game: ^Game) {
	if input_key_pressed(.UP) {
		select_magic_set(game, .Up)
	}

	if input_key_pressed(.LEFT) {
		select_magic_set(game, .Left)
	}

	if input_key_pressed(.RIGHT) {
		select_magic_set(game, .Right)
	}

	if input_key_pressed(.DOWN) {
		select_magic_set(game, .Down)
	}

	if input_confirm_press() {
		state_change(game, .SelectMagicLevel)
	}

	if input_cancel_press() {
		state_change(game, .BattleActionMenu)
	}
}

select_magic_update :: proc(game: ^Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)
	sprites.magic_icons_tick()
}

select_magic_draw :: proc(game: ^Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	current := game_current_unit(game)
	if current == nil {
		return
	}

	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := radial_index_for_direction(direction)
		family := current.magic_family_buckets[index]
		renderer_draw_magic_icon(
			scale,
			family,
			radial_icon_position(game.magic_ui.center, direction),
		)
	}

	renderer_draw_spell_info_box(scale, magic_ui_selected_data(game), game.magic_ui.info_box)
}

select_magic_level_enter :: proc(game: ^Game) {
	current := game_current_unit(game)
	timers.flip_flop_init(&game.state_scratch.blinker, defs.ANIMATIONS.blink_delay)
	if current != nil {
		grid_calculate_magic_attack_range(&game.grid, current, magic_ui_selected_data(game))
	}
}

select_magic_level_exit :: proc(_: ^Game) {}

select_magic_level_handle_input :: proc(game: ^Game) {
	current := game_current_unit(game)
	if input_key_pressed(.LEFT) {
		magic_ui_previous_level(game, current)
		if current != nil {
			grid_calculate_magic_attack_range(&game.grid, current, magic_ui_selected_data(game))
		}
	}

	if input_key_pressed(.RIGHT) {
		magic_ui_next_level(game, current)
		if current != nil {
			grid_calculate_magic_attack_range(&game.grid, current, magic_ui_selected_data(game))
		}
	}

	if input_confirm_press() {
		state_change(game, .PrepareMagicTargets)
	}

	if input_cancel_press() {
		state_change(game, .SelectMagic)
	}
}

select_magic_level_update :: proc(game: ^Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)
	timers.flip_flop_tick(&game.state_scratch.blinker)
	sprites.magic_icons_tick()
}

select_magic_level_draw :: proc(game: ^Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	current := game_current_unit(game)
	if current == nil {
		return
	}

	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := radial_index_for_direction(direction)
		family := current.magic_family_buckets[index]
		renderer_draw_magic_icon(
			scale,
			family,
			radial_icon_position(game.magic_ui.center, direction),
		)
	}

	renderer_draw_spell_info_box(
		scale,
		magic_ui_selected_data(game),
		game.magic_ui.info_box,
		game.state_scratch.blinker.is_on,
	)
}

prepare_magic_targets_enter :: proc(game: ^Game) {
	current := game_current_unit(game)
	if current == nil {
		return
	}

	units := grid_units_in_range(&game.grid)
	defer delete(units)
	game_separate_units_in_range(game, current, units)
	if magic_ui_is_offensive(game) {
		if len(game.unfriendly_units_in_range) > 0 {
			state_change(game, .SelectMagicTargets)
		} else {
			state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .SelectMagicLevel)
		}
	} else {
		if len(game.friendly_units_in_range) > 0 {
			state_change(game, .SelectMagicTargets)
		} else {
			state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .SelectMagicLevel)
		}
	}
}

prepare_magic_targets_exit :: proc(_: ^Game) {}
prepare_magic_targets_handle_input :: proc(_: ^Game) {}
prepare_magic_targets_update :: proc(_: ^Game) {}
prepare_magic_targets_draw :: proc(_: ^Game, _: f32) {}

select_magic_targets_list :: proc(game: ^Game) -> [dynamic]^unit_pkg.Unit {
	if magic_ui_is_offensive(game) {
		return game.unfriendly_units_in_range
	}

	return game.friendly_units_in_range
}

select_magic_targets_enter :: proc(game: ^Game) {
	list := select_magic_targets_list(game)
	if len(list) > 0 {
		game_initialize_highlight(game)
		game.state_scratch.list_index = 0
		game_set_highlight_target(game, list[0])
		select_magic_targets_set_context(game)
	}
}

select_magic_targets_exit :: proc(_: ^Game) {}

select_magic_targets_set_context :: proc(game: ^Game) {
	list := select_magic_targets_list(game)
	index := game.state_scratch.list_index
	if index < 0 || index >= len(list) {
		return
	}

	selected := list[index]
	data := magic_ui_selected_data(game)
	grid_calculate_spell_effect_range(&game.grid, selected, data)
	aoe := grid_units_in_range(&game.grid)
	defer delete(aoe)
	current := game_current_unit(game)
	magic_context_init(&game.magic_context, current, aoe, &game.grid)
}

select_magic_targets_handle_input :: proc(game: ^Game) {
	list := select_magic_targets_list(game)
	if input_try_cycle_index(&game.state_scratch.list_index, len(list)) {
		target := list[game.state_scratch.list_index]
		if target != nil && target.on_map {
			game_set_highlight_target(game, target)
			select_magic_targets_set_context(game)
		}
	}

	if input_confirm_press() {
		magic_context_cast(&game.magic_context, game.magic_ui.selected_name)
		state_change(game, .AnimateUnitDeaths)
	}

	if input_cancel_press() {
		state_change(game, .SelectMagicLevel)
	}
}

select_magic_targets_update :: proc(game: ^Game) {
	timers.flip_flop_tick(&game.flip_flop)
	timers.oscillator_tick(&game.grid.range_tint)
	game_update_highlight(game, 1.0 / 60)
}

select_magic_targets_draw :: proc(game: ^Game, scale: f32) {
	highlight := !game.highlight_animation_complete
	state_draw_map(game, scale, true, highlight)
	if game.highlight_animation_complete {
		for coord in game.grid.range_coords {
			block := grid_block_at(&game.grid, coord.x, coord.y)
			if block != nil {
				renderer_draw_highlight_rectangle(
					scale,
					{f32(block.grid_x * defs.TILE_SIZE), f32(block.grid_y * defs.TILE_SIZE)},
				)
			}
		}
	}
}
