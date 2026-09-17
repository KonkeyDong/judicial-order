package game

import "core:log"

import "defs"
import "timers"
import unit_pkg "unit"

end_turn_enter :: proc(game: ^Game) {
	current :=
		game.unit_that_died_from_poison if game.first_unit_died_from_poison else game_current_unit(game)
	if current != nil {
		unit_pkg.reset_facing_direction(current)
		log.infof("%s's turn ends.", defs.name_display(current.name))
		current.movement_origin = unit_pkg.MOVEMENT_ORIGIN_INVALID
	}

	grid_clear_range_set(&game.grid)
	timers.flip_flop_reset(&game.flip_flop)
	game_reset_units_in_range(game)
	magic_ui_reset(&game.magic_ui)
	magic_ui_reset_layout_center(game)
	item_ui_reset(&game.item_ui)
	item_ui_reset_layout_center(game)
	give_reset(&game.give)
	message_notice_reset(&game.message_notice)
	attack_context_reset(&game.attack_context)
	item_context_reset(&game.item_context)
	magic_context_reset(&game.magic_context)
	game.battle_screen_mode = .Combat
	prompt_reset(&game.prompt)

	if !game.first_unit_died_from_poison {
		game_move_first_unit_to_end(game)
	}

	game_reset_first_unit_died_from_poison(game)

	next := game_current_unit(game)
	if next != nil && next.on_map {
		next.movement_origin = {next.grid_x, next.grid_y}
	}

	state_change(game, .CalculateUnitMovementRange)
}

end_turn_exit :: proc(game: ^Game) {
	current := game_current_unit(game)
	if current == nil {
		return
	}

	log.infof("%s's turn begins.", defs.name_display(current.name))
}

end_turn_handle_input :: proc(_: ^Game) {}
end_turn_update :: proc(_: ^Game) {}
end_turn_draw :: proc(_: ^Game, _: f32) {}
