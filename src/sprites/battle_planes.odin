package sprites

import "core:log"
import "core:os"
import "core:reflect"
import "core:strings"

import "../defs"

backgrounds: [defs.Background]Sprite
foregrounds: [defs.Foreground]Sprite
backgrounds_loaded: bool
foregrounds_loaded: bool

battle_planes_init :: proc() {
	backgrounds = {}
	foregrounds = {}
	backgrounds_loaded = false
	foregrounds_loaded = false
}

battle_planes_destroy :: proc() {
	battle_planes_init()
}

battle_plane_png_path :: proc(root, name, placeholder_file: string) -> string {
	named := strings.concatenate({root, "/", name, ".png"}, context.temp_allocator)
	if os.exists(named) {
		return named
	}

	return strings.concatenate({root, "/", placeholder_file}, context.temp_allocator)
}

battle_plane_load :: proc(sprites: ^[$Key]Sprite, root, placeholder_file, label: string) -> bool {
	json_path := strings.concatenate({root, "/", defs.PATHS.frame_data}, context.temp_allocator)
	frames := extract_frames(json_path)
	defer delete(frames)
	if len(frames) == 0 {
		log.errorf("%s: no frames in %s.", label, json_path)
		return false
	}

	frame := frames[0]
	count := 0
	for key in Key {
		name := reflect.enum_string(key)
		png := battle_plane_png_path(root, name, placeholder_file)
		named := strings.concatenate({root, "/", name, ".png"}, context.temp_allocator)
		if png != named {
			log.warnf("%s: missing %s; using %s.", label, named, png)
		}

		sprites[key] = Sprite {
			texture = load(png),
			frame   = frame,
		}
		count += 1
	}

	log.infof("%s have been loaded (%d).", label, count)
	return true
}

battle_planes_load :: proc() {
	if backgrounds_loaded {
		log.debug("Battle backgrounds have already been loaded.")
	} else {
		backgrounds_loaded = battle_plane_load(
			&backgrounds,
			defs.PATHS.backgrounds,
			defs.PATHS.background_placeholder,
			"Battle backgrounds",
		)
	}

	if foregrounds_loaded {
		log.debug("Battle foregrounds have already been loaded.")
	} else {
		foregrounds_loaded = battle_plane_load(
			&foregrounds,
			defs.PATHS.foreground,
			defs.PATHS.foreground_placeholder,
			"Battle foregrounds",
		)
	}
}

battle_background_get :: proc(name: defs.Background) -> Sprite {
	if !backgrounds_loaded {
		return {}
	}

	return backgrounds[name]
}

battle_foreground_get :: proc(name: defs.Foreground) -> Sprite {
	if !foregrounds_loaded {
		return {}
	}

	return foregrounds[name]
}
