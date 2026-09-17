package game

import "core:fmt"
import "core:log"

import "defs"
import "timers"
import unit_pkg "unit"

calculate_unit_movement_range_enter :: proc(game: ^Game) {
	current := game_current_unit(game)
	if current == nil {
		return
	}

	game.state_scratch.is_poisoned = unit_pkg.has_status(current, .Poison)
	game.state_scratch.is_sleeping = unit_pkg.has_status(current, .Sleep)
	timers.countdown_timer_init(
		&game.state_scratch.countdown,
		defs.ANIMATIONS.switch_state_countdown,
	)

	if game.state_scratch.is_poisoned || game.state_scratch.is_sleeping {
		timers.countdown_timer_reset(&game.state_scratch.countdown)
		timers.countdown_timer_start(&game.state_scratch.countdown)
	} else {
		calculate_unit_movement_range_proceed(game)
	}
}

calculate_unit_movement_range_exit :: proc(game: ^Game) {
}

calculate_unit_movement_range_handle_input :: proc(game: ^Game) {
	if input_confirm_press() {
		timers.countdown_timer_stop(&game.state_scratch.countdown)
	}
}

calculate_unit_movement_range_proceed :: proc(game: ^Game) {
	current := game_current_unit(game)
	if current == nil {
		return
	}

	grid_calculate_unit_movement_range(&game.grid, current)
	state_change(game, .UnitMoving)
}

calculate_unit_movement_range_update :: proc(game: ^Game) {
	timers.countdown_timer_tick(&game.state_scratch.countdown)
	timers.flip_flop_tick(&game.flip_flop)

	if !(game.state_scratch.is_poisoned || game.state_scratch.is_sleeping) {
		return
	}

	if game.state_scratch.countdown.is_active {
		return
	}

	current := game_current_unit(game)
	if current == nil {
		return
	}

	if game.state_scratch.is_poisoned {
		game.state_scratch.is_poisoned = false
		unit_pkg.process_poison(current)
		if unit_pkg.is_dead(current) {
			game_set_first_unit_died_from_poison(game, current)
			state_change(game, .AnimateUnitDeaths)
			return
		}
	}

	if game.state_scratch.is_sleeping {
		game.state_scratch.is_sleeping = false
		unit_pkg.process_sleep(current)
		state_change(game, .EndTurn)
		return
	}

	calculate_unit_movement_range_proceed(game)
}

calculate_unit_movement_range_draw :: proc(game: ^Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	current := game_current_unit(game)
	if current == nil {
		return
	}

	box := defs.WORLD_MAP.positions.no_target_message_box
	if game.state_scratch.is_poisoned {
		renderer_draw_battle_menu_message(
			scale,
			fmt.tprintf("%s suffers poison damage.", defs.name_display(current.name)),
			box,
		)
	}

	if game.state_scratch.is_sleeping {
		message := fmt.tprintf("%s is sleeping.", defs.name_display(current.name))
		if unit_pkg.status_duration(current, .Sleep) <= 0 {
			message = fmt.tprintf("%s has awoken.", defs.name_display(current.name))
		}

		renderer_draw_battle_menu_message(scale, message, box)
	}
}
