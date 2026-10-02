package sprites

import "core:log"
import "core:os"
import "core:path/filepath"
import "core:reflect"
import "core:strings"

import "../defs"
import "../unit"

join_path :: proc(elems: []string) -> string {
	path, _ := filepath.join(elems, context.temp_allocator)
	return path
}

@(private = "file")
asset_root :: proc(target: ^unit.Unit) -> string {
	if target == nil {
		log.panic("target is nil.")
	}

	base := battle_snake_case(defs.name_base(target.name))
	if base == "" {
		return ""
	}

	if target.friendly {
		promo := defs.PATHS.promoted if unit.is_promoted(target) else defs.PATHS.unpromoted
		return join_path({defs.PATHS.force_members, base, promo})
	}

	return join_path({defs.PATHS.monsters, base})
}

@(private)
unit_overworld_dir :: proc(target: ^unit.Unit) -> string {
	if target == nil {
		log.panic("target is nil.")
	}

	root := asset_root(target)
	if root == "" {
		return ""
	}

	return join_path({root, defs.PATHS.overworld})
}

@(private = "file")
first_existing_path :: proc(paths: []string) -> (string, bool) {
	for path in paths {
		if path != "" && os.exists(path) {
			return path, true
		}
	}

	return "", false
}

// Somber-Inertia names the sheet WalkDown.png and FrameData.json.
// The exported law-professor set uses walk_down.png and frame_data.json.
@(private = "file")
walk_json_path :: proc(overworld_dir: string) -> (string, bool) {
	if overworld_dir == "" {
		return "", false
	}

	return first_existing_path(
		{
			join_path({overworld_dir, defs.PATHS.frame_data}),
			join_path({overworld_dir, "frame_data.json"}),
		},
	)
}

@(private = "file")
walk_png_path :: proc(overworld_dir: string, direction: defs.Direction) -> (string, bool) {
	if overworld_dir == "" {
		return "", false
	}

	snake := battle_snake_case(reflect.enum_string(direction))
	exported := ""
	if snake != "" {
		exported = strings.concatenate({"walk_", snake, ".png"}, context.temp_allocator)
	}

	return first_existing_path(
		{
			join_path({overworld_dir, defs.direction_walk_image(direction)}),
			join_path({overworld_dir, exported}),
		},
	)
}

@(private)
structured_walk_complete :: proc(overworld_dir: string) -> bool {
	if _, ok := walk_json_path(overworld_dir); !ok {
		return false
	}

	for direction in defs.Direction {
		if _, ok := walk_png_path(overworld_dir, direction); !ok {
			return false
		}
	}

	return true
}

@(private)
load_unit_walk :: proc(target: ^unit.Unit) {
	if target == nil {
		log.panic("target is nil.")
	}

	target.walk_frames_loaded = 0
	if cache.textures.allocator.procedure == nil {
		return
	}

	overworld_dir := unit_overworld_dir(target)
	json_path, json_ok := walk_json_path(overworld_dir)
	png_for_dir: [defs.Direction]string
	use_placeholder := !json_ok
	if !use_placeholder {
		for direction in defs.Direction {
			png, ok := walk_png_path(overworld_dir, direction)
			if !ok {
				use_placeholder = true
				break
			}

			png_for_dir[direction] = png
		}
	}

	if use_placeholder {
		log.warnf(
			"load_walk_animations: incomplete walk set for %s; using placeholder.",
			defs.name_display(target.name),
		)
		json_path = defs.PATHS.placeholder_json
		for direction in defs.Direction {
			png_for_dir[direction] = defs.PATHS.placeholder_png
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
