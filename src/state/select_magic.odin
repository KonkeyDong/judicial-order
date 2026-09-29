package state

import "core:log"

import game_pkg "../game"

import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"

@(private)
select_magic_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	current := game_pkg.game_current_unit(game)
	sprites.magic_ui_reset_layout_center(&game.magic_ui, game.window)
	sprites.magic_ui_set_selected(&game.magic_ui, .Up, current)
	if current != nil {
		game_pkg.grid_calculate_magic_attack_range(
			&game.grid,
			current,
			sprites.magic_ui_selected_data(&game.magic_ui),
		)
	}
}

@(private)
select_magic_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private = "file")
select_magic_set :: proc(game: ^game_pkg.Game, direction: defs.Direction) {
	if game == nil {
		log.panic("game is nil.")
	}

	current := game_pkg.game_current_unit(game)
	sprites.magic_ui_set_selected(&game.magic_ui, direction, current)
	if current != nil {
		game_pkg.grid_calculate_magic_attack_range(
			&game.grid,
			current,
			sprites.magic_ui_selected_data(&game.magic_ui),
		)
	}
}

@(private)
select_magic_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	if game_pkg.input_key_pressed(.UP) {
		select_magic_set(game, .Up)
	}

	if game_pkg.input_key_pressed(.LEFT) {
		select_magic_set(game, .Left)
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		select_magic_set(game, .Right)
	}

	if game_pkg.input_key_pressed(.DOWN) {
		select_magic_set(game, .Down)
	}

	if game_pkg.input_confirm_press() {
		state_change(game, .SelectMagicLevel)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleActionMenu)
	}
}

@(private)
select_magic_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.magic_icons_tick()
}

@(private)
select_magic_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	state_draw_map(game, scale, true, false)
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := sprites.radial_index_for_direction(direction)
		family := current.magic_family_buckets[index]
		sprites.renderer_draw_magic_icon(
			scale,
			family,
			sprites.radial_icon_position(game.magic_ui.center, direction),
		)
	}

	sprites.renderer_draw_spell_info_box(
		scale,
		sprites.magic_ui_selected_data(&game.magic_ui),
		game.magic_ui.info_box,
	)
}

@(private)
select_magic_level_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	current := game_pkg.game_current_unit(game)
	timers.flip_flop_init(&game.state_scratch.blinker, defs.ANIMATIONS.blink_delay)
	if current != nil {
		game_pkg.grid_calculate_magic_attack_range(
			&game.grid,
			current,
			sprites.magic_ui_selected_data(&game.magic_ui),
		)
	}
}

@(private)
select_magic_level_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private)
select_magic_level_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	current := game_pkg.game_current_unit(game)
	if game_pkg.input_key_pressed(.LEFT) {
		sprites.magic_ui_previous_level(&game.magic_ui, current)
		if current != nil {
			game_pkg.grid_calculate_magic_attack_range(
				&game.grid,
				current,
				sprites.magic_ui_selected_data(&game.magic_ui),
			)
		}
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		sprites.magic_ui_next_level(&game.magic_ui, current)
		if current != nil {
			game_pkg.grid_calculate_magic_attack_range(
				&game.grid,
				current,
				sprites.magic_ui_selected_data(&game.magic_ui),
			)
		}
	}

	if game_pkg.input_confirm_press() {
		state_change(game, .PrepareMagicTargets)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .SelectMagic)
	}
}

@(private)
select_magic_level_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	timers.flip_flop_tick(&game.state_scratch.blinker)
	sprites.magic_icons_tick()
}

@(private)
select_magic_level_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	state_draw_map(game, scale, true, false)
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := sprites.radial_index_for_direction(direction)
		family := current.magic_family_buckets[index]
		sprites.renderer_draw_magic_icon(
			scale,
			family,
			sprites.radial_icon_position(game.magic_ui.center, direction),
		)
	}

	sprites.renderer_draw_spell_info_box(
		scale,
		sprites.magic_ui_selected_data(&game.magic_ui),
		game.magic_ui.info_box,
		game.state_scratch.blinker.is_on,
	)
}

@(private)
prepare_magic_targets_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	units := game_pkg.grid_units_in_range(&game.grid)
	defer delete(units)
	game_pkg.game_separate_units_in_range(game, current, units)
	if sprites.magic_ui_is_offensive(&game.magic_ui) {
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

@(private)
prepare_magic_targets_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
prepare_magic_targets_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
prepare_magic_targets_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
prepare_magic_targets_draw :: proc(game: ^game_pkg.Game, _: f32) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private = "file")
select_magic_targets_list :: proc(game: ^game_pkg.Game) -> [dynamic]^unit_pkg.Unit {
	if game == nil {
		log.panic("game is nil.")
	}

	if sprites.magic_ui_is_offensive(&game.magic_ui) {
		return game.unfriendly_units_in_range
	}

	return game.friendly_units_in_range
}

@(private)
select_magic_targets_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	list := select_magic_targets_list(game)
	if len(list) > 0 {
		game_pkg.game_initialize_highlight(game)
		game.state_scratch.list_index = 0
		game_pkg.game_set_highlight_target(game, list[0])
		select_magic_targets_set_context(game)
	}
}

@(private)
select_magic_targets_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private = "file")
select_magic_targets_set_context :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	list := select_magic_targets_list(game)
	index := game.state_scratch.list_index
	if index < 0 || index >= len(list) {
		return
	}

	selected := list[index]
	data := sprites.magic_ui_selected_data(&game.magic_ui)
	game_pkg.grid_calculate_spell_effect_range(&game.grid, selected, data)
	aoe := game_pkg.grid_units_in_range(&game.grid)
	defer delete(aoe)
	current := game_pkg.game_current_unit(game)
	game_pkg.magic_context_init(&game.contexts.magic_context, current, aoe, &game.grid)
}

@(private)
select_magic_targets_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	list := select_magic_targets_list(game)
	if game_pkg.input_try_cycle_index(&game.state_scratch.list_index, len(list)) {
		target := list[game.state_scratch.list_index]
		if target != nil && target.on_map {
			game_pkg.game_set_highlight_target(game, target)
			select_magic_targets_set_context(game)
		}
	}

	if game_pkg.input_confirm_press() {
		game_pkg.magic_context_cast(&game.contexts.magic_context, game.magic_ui.selected_name)
		state_change(game, .AnimateUnitDeaths)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .SelectMagicLevel)
	}
}

@(private)
select_magic_targets_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	timers.oscillator_tick(&game.grid.range_tint)
	game_pkg.game_update_highlight(game, 1.0 / 60)
}

@(private)
select_magic_targets_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	highlight := !game.highlight.animation_complete
	state_draw_map(game, scale, true, highlight)
	if game.highlight.animation_complete {
		for coord in game.grid.range_coords {
			block := game_pkg.grid_block_at(&game.grid, coord.x, coord.y)
			if block != nil {
				sprites.renderer_draw_highlight_rectangle(
					scale,
					{f32(block.grid_x * defs.TILE_SIZE), f32(block.grid_y * defs.TILE_SIZE)},
				)
			}
		}
	}
}
