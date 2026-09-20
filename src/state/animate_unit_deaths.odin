package state

import game_pkg "../game"

import "core:log"

import "../defs"
import "../sprites"
import unit_pkg "../unit"

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

animate_unit_deaths_enter :: proc(game: ^game_pkg.Game) {
	dead_units := game_pkg.game_remove_all_dead_units(game)
	defer delete(dead_units)

	game.state_scratch.target_count = 0
	for unit in dead_units {
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

animate_unit_deaths_exit :: proc(_: ^game_pkg.Game) {}
animate_unit_deaths_handle_input :: proc(_: ^game_pkg.Game) {}

animate_unit_deaths_update :: proc(game: ^game_pkg.Game) {
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

animate_unit_deaths_draw :: proc(game: ^game_pkg.Game, scale: f32) {
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
		sprites.renderer_draw(scale, sprite, unit.world_position, 255, game.renderer.debug_draw)
	}
}
