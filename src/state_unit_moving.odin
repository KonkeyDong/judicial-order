package game

import "core:log"

import "defs"
import "timers"
import unit_pkg "unit"
import rl "vendor:raylib"

unit_moving_enter :: proc(game: ^Game) {
	log.debug("UnitMoving::Enter() called.")
	current := game_current_unit(game)
	if current == nil {
		return
	}

	timers.oscillator_reset(&game.grid.range_tint)
	grid_calculate_unit_movement_range(&game.grid, current)
	game_initialize_highlight(game)
	unit_pkg.reset_starting_world_position(current)
	timers.countdown_timer_init(
		&game.state_scratch.countdown,
		defs.ANIMATIONS.countdown_timer_delay,
	)
}

unit_moving_exit :: proc(game: ^Game) {
	log.debug("UnitMoving::Exit() called.")
}

unit_moving_handle_input :: proc(game: ^Game) {
	current := game_current_unit(game)
	if current == nil || current.is_animating {
		return
	}

	if input_key_pressed(.UP) {
		grid_move_unit_in_direction(&game.grid, current, .Up)
	}

	if input_key_pressed(.DOWN) {
		grid_move_unit_in_direction(&game.grid, current, .Down)
	}

	if input_key_pressed(.LEFT) {
		grid_move_unit_in_direction(&game.grid, current, .Left)
	}

	if input_key_pressed(.RIGHT) {
		grid_move_unit_in_direction(&game.grid, current, .Right)
	}

	if input_confirm_press() {
		block := grid_unit_block(&game.grid, current)
		if block != nil && !block_is_fully_occupied(block) {
			state_change(game, .BattleActionMenu)
		}
	}
}

unit_moving_update :: proc(game: ^Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.countdown_timer_tick(&game.state_scratch.countdown)
	timers.flip_flop_tick(&game.flip_flop)
	current := game_current_unit(game)
	if current != nil && current.is_animating {
		unit_pkg.update_movement(current, rl.GetFrameTime())
	}
}

unit_moving_draw :: proc(game: ^Game, scale: f32) {
	state_draw_map(game, scale, true, game.state_scratch.countdown.is_active)
}
