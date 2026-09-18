package state

import game_pkg "../game"

import "core:log"

import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"

end_turn_enter :: proc(game: ^game_pkg.Game) {
	current :=
		game.unit_that_died_from_poison if game.first_unit_died_from_poison else game_pkg.game_current_unit(game)
	if current != nil {
		unit_pkg.reset_facing_direction(current)
		log.infof("%s's turn ends.", defs.name_display(current.name))
		current.movement_origin = unit_pkg.MOVEMENT_ORIGIN_INVALID
	}

	timers.flip_flop_reset(&game.flip_flop)

	game_pkg.grid_clear_range_set(&game.grid)
	game_pkg.game_reset_units_in_range(game)

	sprites.magic_ui_reset(&game.magic_ui)
	sprites.magic_ui_reset_layout_center(&game.magic_ui, game.window)
	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)

	game_pkg.give_reset(&game.give)
	game_pkg.message_notice_reset(&game.message_notice)
	game_pkg.attack_context_reset(&game.attack_context)
	game_pkg.item_context_reset(&game.item_context)
	game_pkg.magic_context_reset(&game.magic_context)
	game.battle_screen_mode = .Combat
	game_pkg.prompt_reset(&game.prompt)

	if !game.first_unit_died_from_poison {
		game_pkg.game_move_first_unit_to_end(game)
	}

	game_pkg.game_reset_first_unit_died_from_poison(game)

	next := game_pkg.game_current_unit(game)
	if next != nil && next.on_map {
		next.movement_origin = {next.grid_x, next.grid_y}
	}

	state_change(game, .CalculateUnitMovementRange)
}

end_turn_exit :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	log.infof("%s's turn begins.", defs.name_display(current.name))
}

end_turn_handle_input :: proc(_: ^game_pkg.Game) {}
end_turn_update :: proc(_: ^game_pkg.Game) {}
end_turn_draw :: proc(_: ^game_pkg.Game, _: f32) {}
