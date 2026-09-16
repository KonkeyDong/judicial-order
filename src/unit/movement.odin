package unit

import "core:log"

import "../defs"
import "../timers"
import rl "vendor:raylib"

tile_pixel :: proc(unit: ^Unit) -> rl.Vector2 {
	return {f32(unit.grid_x * defs.TILE_SIZE), f32(unit.grid_y * defs.TILE_SIZE)}
}

reset_starting_world_position :: proc(unit: ^Unit) {
	if !unit.on_map {
		log.error("reset_starting_world_position: unit is not on the map.")
		return
	}

	unit.world_position = tile_pixel(unit)
}

start_moving_to :: proc(unit: ^Unit, target_world: rl.Vector2) {
	unit.start_world_position = unit.world_position
	unit.target_world_position = target_world
	unit.movement_timer = 0
	unit.is_animating = true
}

snap_to_pixel :: proc(unit: ^Unit, pos: rl.Vector2) {
	unit.world_position = pos
	unit.target_world_position = pos
	unit.start_world_position = pos
}

snap_to_current_tile :: proc(unit: ^Unit) {
	if !unit.on_map {
		log.error("Cannot snap unit — not on the map.")
		return
	}

	snap_to_pixel(unit, tile_pixel(unit))
}

update_movement :: proc(unit: ^Unit, delta_time: f32) {
	if !unit.is_animating {
		return
	}

	unit.movement_timer += delta_time
	progress := clamp(unit.movement_timer / defs.ANIMATIONS.movement_duration, 0, 1)
	unit.world_position =
		unit.start_world_position +
		(unit.target_world_position - unit.start_world_position) * progress
	timers.flip_flop_tick(&unit.movement_flip_flop)

	if progress >= 1.0 {
		stop_movement(unit)
	}
}

stop_movement :: proc(unit: ^Unit) {
	unit.world_position = unit.target_world_position
	unit.is_animating = false
	unit.movement_timer = 0
}

reset_facing_direction :: proc(unit: ^Unit) {
	unit.facing_direction = .Down
}
