package unit

import "core:log"

import "../defs"

walk_loader: proc(unit: ^Unit)

load_walk_animations :: proc(unit: ^Unit) {
	if walk_loader == nil {
		unit.walk_frames_loaded = 0
		return
	}

	walk_loader(unit)
}

facing_sprite :: proc(unit: ^Unit, direction: defs.Direction) -> defs.Sprite {
	if unit.walk_frames_loaded == 0 {
		log.error("No walk animations loaded.")
		return {}
	}

	return unit.walk_animations[direction][0]
}

walk_sprite :: proc(unit: ^Unit, global_flip_flop_on: bool) -> defs.Sprite {
	if unit.walk_frames_loaded == 0 {
		log.error("No walk animations loaded.")
		return {}
	}

	frame_index := 0
	if unit.is_animating {
		frame_index = 1 if unit.movement_flip_flop.is_on else 0
	} else {
		frame_index = 1 if global_flip_flop_on else 0
	}

	if frame_index >= unit.walk_frames_loaded {
		frame_index = 0
	}

	return unit.walk_animations[unit.facing_direction][frame_index]
}
