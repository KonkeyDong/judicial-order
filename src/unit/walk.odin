package unit

import "core:log"
import "core:os"
import "core:path/filepath"

import "../defs"
import "../sprites"

join_path :: proc(elems: []string) -> string {
	path, _ := filepath.join(elems, context.temp_allocator)
	return path
}

asset_root :: proc(unit: ^Unit) -> string {
	base := defs.name_base(unit.name)
	if unit.friendly {
		promo := defs.PATHS.promoted if is_promoted(unit) else defs.PATHS.unpromoted
		return join_path({defs.PATHS.force_members, base, promo})
	}

	return join_path({defs.PATHS.monsters, base})
}

structured_walk_complete :: proc(overworld_dir: string) -> bool {
	json_path := join_path({overworld_dir, defs.PATHS.frame_data})
	if !os.exists(json_path) {
		return false
	}

	for direction in defs.Direction {
		png := join_path({overworld_dir, defs.direction_walk_image(direction)})
		if !os.exists(png) {
			return false
		}
	}

	return true
}

load_walk_animations :: proc(unit: ^Unit) {
	unit.walk_frames_loaded = 0
	if sprites.cache.textures.allocator.procedure == nil {
		return
	}

	overworld_dir := join_path({asset_root(unit), defs.PATHS.overworld})
	json_path := join_path({overworld_dir, defs.PATHS.frame_data})
	png_for_dir: [defs.Direction]string
	use_placeholder := !structured_walk_complete(overworld_dir)
	if use_placeholder {
		log.warnf(
			"load_walk_animations: incomplete walk set for %s; using placeholder.",
			defs.name_display(unit.name),
		)
		json_path = defs.PATHS.placeholder_json
		for direction in defs.Direction {
			png_for_dir[direction] = defs.PATHS.placeholder_png
		}
	} else {
		for direction in defs.Direction {
			png_for_dir[direction] = join_path(
				{overworld_dir, defs.direction_walk_image(direction)},
			)
		}
	}

	frames := sprites.extract_frames(json_path)
	defer delete(frames)

	frame_count := min(defs.WALK_FRAME_COUNT, len(frames))
	for direction in defs.Direction {
		tex := sprites.load(png_for_dir[direction])
		for i in 0 ..< frame_count {
			unit.walk_animations[direction][i] = sprites.Sprite {
				texture = tex,
				frame   = frames[i],
			}
		}
	}

	unit.walk_frames_loaded = frame_count
	log.infof(
		"LoadWalkAnimations completed. Loaded %d frames across 4 directions.",
		frame_count * 4,
	)
}

facing_sprite :: proc(unit: ^Unit, direction: defs.Direction) -> sprites.Sprite {
	if unit.walk_frames_loaded == 0 {
		log.error("No walk animations loaded.")
		return {}
	}

	return unit.walk_animations[direction][0]
}

walk_sprite :: proc(unit: ^Unit, global_flip_flop_on: bool) -> sprites.Sprite {
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
