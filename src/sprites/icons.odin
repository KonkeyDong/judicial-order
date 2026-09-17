package sprites

import "core:log"
import "core:os"
import "core:reflect"
import "core:strings"

import "../defs"
import "../timers"

Icon_Set :: struct($Key: typeid) {
	root_path:  string,
	flip_flop:  timers.Flip_Flop,
	animations: map[Key][2]Sprite,
	selected:   Key,
	loaded:     bool,
}

icon_set_init :: proc(set: ^Icon_Set($Key), root_path: string, selected: Key) {
	if set.animations.allocator.procedure != nil {
		delete(set.animations)
	}

	set.root_path = root_path
	set.animations = make(map[Key][2]Sprite)
	set.selected = selected
	set.loaded = false
	timers.flip_flop_init(&set.flip_flop, defs.ANIMATIONS.blink_delay)
}

icon_set_destroy :: proc(set: ^Icon_Set($Key)) {
	// Do NOT UnloadTexture — sprites share sprites.cache.
	if set.animations.allocator.procedure != nil {
		delete(set.animations)
	}

	set.animations = {}
	set.loaded = false
}

icon_set_load :: proc(set: ^Icon_Set($Key)) {
	clear(&set.animations) // C# Load starts with Clear; skip leaks

	json_path := strings.concatenate({set.root_path, "/FrameData.json"}, context.temp_allocator)
	frames := extract_frames(json_path)
	defer delete(frames)

	rects := frames
	synthesized: [2]Frame_Rect
	if len(frames) == 0 {
		// Missing JSON must not panic; placeholder blink needs two weasel-lawyer rects.
		synthesized[0] = Frame_Rect{x = 0, y = 0, w = 24, h = 24}
		synthesized[1] = Frame_Rect{x = 24, y = 0, w = 24, h = 24}
		rects = synthesized[:]
	}

	total_frames := 0
	for key in Key {
		png := strings.concatenate(
			{set.root_path, "/", reflect.enum_string(key), ".png"},
			context.temp_allocator,
		)
		if !os.exists(png) {
			log.warnf("icon_set_load: missing %s; using placeholder.", png)
			png = defs.PATHS.placeholder_png
		}

		tex := load(png)

		pair: [2]Sprite
		frame_count := min(2, len(rects))
		for i in 0 ..< frame_count {
			pair[i] = Sprite {
				texture = tex,
				frame   = rects[i],
			}
			total_frames += 1
		}

		if frame_count == 1 {
			pair[1] = pair[0]
		}

		set.animations[key] = pair
	}

	set.loaded = true
	log.infof("IconSet<%v>.Load() completed. Loaded %d frames.", typeid_of(Key), total_frames)
}

icon_set_tick :: proc(set: ^Icon_Set($Key)) {
	timers.flip_flop_tick(&set.flip_flop)
}

icon_set_reset :: proc(set: ^Icon_Set($Key)) {
	timers.flip_flop_reset(&set.flip_flop)
}

icon_set_set_selected :: proc(set: ^Icon_Set($Key), key: Key) {
	set.selected = key
	icon_set_reset(set)
}

icon_set_get :: proc(set: ^Icon_Set($Key), key: Key) -> Sprite {
	return icon_set_get_selected(set, key, key == set.selected)
}

icon_set_get_selected :: proc(set: ^Icon_Set($Key), key: Key, is_selected: bool) -> Sprite {
	pair, ok := set.animations[key]
	if !ok {
		log.errorf("Icon for [%v] not found in IconSet.", key)
		return {}
	}

	frame_index := 0
	if is_selected && set.flip_flop.is_on {
		frame_index = 1
	} else {
		frame_index = 0
	}

	return pair[frame_index]
}
