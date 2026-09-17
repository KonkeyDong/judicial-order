package game

import "core:log"

import "defs"
import unit_pkg "unit"

DEATH_DIRECTION_CYCLE := [12]defs.Direction {
	.Up,
	.Right,
	.Down,
	.Left,
	.Up,
	.Right,
	.Down,
	.Left,
	.Up,
	.Right,
	.Down,
	.Left,
}

animate_unit_deaths_enter :: proc(game: ^Game) {
	dead := game_remove_all_dead_units(game)
	defer delete(dead)
	game.state_scratch.target_count = 0
	for unit in dead {
		if game.state_scratch.target_count >= len(game.state_scratch.targets) {
			break
		}

		game.state_scratch.targets[game.state_scratch.target_count] = unit
		game.state_scratch.target_count += 1
	}

	if game.state_scratch.target_count == 0 {
		log.info("No dead units found; exiting state.")
		state_change(game, .EndTurn)
		return
	}

	game.state_scratch.death_direction_index = 0
	game.state_scratch.death_phase_done = false
	game.state_scratch.death_delay = 0
}

animate_unit_deaths_exit :: proc(_: ^Game) {}
animate_unit_deaths_handle_input :: proc(_: ^Game) {}

animate_unit_deaths_update :: proc(game: ^Game) {
	if game.state_scratch.death_delay > 0 {
		game.state_scratch.death_delay -= 1
		return
	}

	game.state_scratch.death_delay = 2
	if !game.state_scratch.death_phase_done {
		game.state_scratch.death_direction_index += 1
		if game.state_scratch.death_direction_index >= len(DEATH_DIRECTION_CYCLE) {
			game.state_scratch.death_phase_done = true
			state_change(game, .EndTurn)
		}
	} else {
		state_change(game, .EndTurn)
	}
}

animate_unit_deaths_draw :: proc(game: ^Game, scale: f32) {
	state_draw_map(game, scale, false, false)
	if game.state_scratch.death_phase_done {
		return
	}

	index := game.state_scratch.death_direction_index
	if index < 0 || index >= len(DEATH_DIRECTION_CYCLE) {
		return
	}

	dir := DEATH_DIRECTION_CYCLE[index]
	for i in 0 ..< game.state_scratch.target_count {
		unit := game.state_scratch.targets[i]
		if unit == nil {
			continue
		}

		sprite := unit_pkg.facing_sprite(unit, dir)
		renderer_draw(scale, sprite, unit.world_position, 255, game.renderer.debug_draw)
	}
}
