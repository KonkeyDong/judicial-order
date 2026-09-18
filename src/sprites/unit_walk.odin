package sprites

import "core:log"
import "core:os"
import "core:path/filepath"

import "../defs"
import "../unit"

join_path :: proc(elems: []string) -> string {
	path, _ := filepath.join(elems, context.temp_allocator)
	return path
}

asset_root :: proc(target: ^unit.Unit) -> string {
	base := defs.name_base(target.name)
	if target.friendly {
		promo := defs.PATHS.promoted if unit.is_promoted(target) else defs.PATHS.unpromoted
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

load_unit_walk :: proc(target: ^unit.Unit) {
	target.walk_frames_loaded = 0
	if cache.textures.allocator.procedure == nil {
		return
	}

	overworld_dir := join_path({asset_root(target), defs.PATHS.overworld})
	json_path := join_path({overworld_dir, defs.PATHS.frame_data})
	png_for_dir: [defs.Direction]string
	use_placeholder := !structured_walk_complete(overworld_dir)
	if use_placeholder {
		log.warnf(
			"load_walk_animations: incomplete walk set for %s; using placeholder.",
			defs.name_display(target.name),
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

	frames := extract_frames(json_path)
	defer delete(frames)

	frame_count := min(defs.WALK_FRAME_COUNT, len(frames))
	for direction in defs.Direction {
		tex := load(png_for_dir[direction])
		for i in 0 ..< frame_count {
			target.walk_animations[direction][i] = Sprite {
				texture = tex,
				frame   = frames[i],
			}
		}
	}

	target.walk_frames_loaded = frame_count
	log.infof(
		"LoadWalkAnimations completed. Loaded %d frames across 4 directions.",
		frame_count * 4,
	)
}
