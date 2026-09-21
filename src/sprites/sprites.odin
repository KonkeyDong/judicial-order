package sprites

import "core:encoding/json"
import "core:log"
import "core:os"
import "core:strings"

import "../defs"
import "../unit"
import rl "vendor:raylib"

Frame_Rect :: defs.Frame_Rect
Sprite :: defs.Sprite

Aseprite_Frame_Entry :: struct {
	frame: Frame_Rect,
}

Aseprite_Sheet :: struct {
	frames: []Aseprite_Frame_Entry,
}

Flat_Frame_Sheet :: struct {
	frames: []Frame_Rect,
}

Sprite_Cache :: struct {
	textures: map[string]rl.Texture2D,
}

cache: Sprite_Cache

init :: proc() {
	cache.textures = make(map[string]rl.Texture2D)
	item_icons_init()
	magic_icons_init()
	command_icons_init()
	unit.walk_loader = load_unit_walk
}

destroy :: proc() {
	item_icons_destroy()
	magic_icons_destroy()
	command_icons_destroy()
	for _, tex in cache.textures {
		rl.UnloadTexture(tex)
	}

	delete(cache.textures)
	log.info("All sprites unloaded.")
}

load :: proc(path: string) -> rl.Texture2D {
	if tex, ok := cache.textures[path]; ok {
		return tex
	}

	log.debugf("Loading sprite: %s", path)
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	tex := rl.LoadTexture(cpath)
	if tex.id == 0 {
		log.panicf("Failed to load sprite: %s", path)
	}

	cache.textures[path] = tex
	return tex
}

json_object_int :: proc(obj: json.Object, keys: []string) -> (int, bool) {
	for key in keys {
		if value, ok := obj[key]; ok {
			#partial switch v in value {
			case json.Integer:
				return int(v), true
			case json.Float:
				return int(v), true
			}
		}
	}

	return 0, false
}

frame_rect_from_json_object :: proc(obj: json.Object) -> (Frame_Rect, bool) {
	src := obj
	if nested, ok := obj["frame"]; ok {
		if nested_obj, nested_ok := nested.(json.Object); nested_ok {
			src = nested_obj
		}
	}

	x, x_ok := json_object_int(src, {"x", "X"})
	y, y_ok := json_object_int(src, {"y", "Y"})
	w, w_ok := json_object_int(src, {"w", "W"})
	h, h_ok := json_object_int(src, {"h", "H"})
	if !x_ok || !y_ok || !w_ok || !h_ok {
		return {}, false
	}

	return Frame_Rect{x = x, y = y, w = w, h = h}, true
}

extract_frames_from_value :: proc(root: json.Value) -> []Frame_Rect {
	obj, is_obj := root.(json.Object)
	if !is_obj {
		return {}
	}

	frames_value, has_frames := obj["frames"]
	if !has_frames {
		return {}
	}

	out: [dynamic]Frame_Rect
	#partial switch frames in frames_value {
	case json.Array:
		for entry in frames {
			entry_obj, ok := entry.(json.Object)
			if !ok {
				continue
			}

			rect, rect_ok := frame_rect_from_json_object(entry_obj)
			if rect_ok {
				append(&out, rect)
			}
		}
	case json.Object:
		for _, entry in frames {
			entry_obj, ok := entry.(json.Object)
			if !ok {
				continue
			}

			rect, rect_ok := frame_rect_from_json_object(entry_obj)
			if rect_ok {
				append(&out, rect)
			}
		}
	}

	if len(out) == 0 {
		delete(out)
		return {}
	}

	return out[:]
}

extract_frames :: proc(json_path: string) -> []Frame_Rect {
	if json_path == "" {
		log.error("ExtractFrameData: jsonFilePath is empty")
		return {}
	}

	data, err := os.read_entire_file(json_path, context.allocator)
	if err != nil {
		log.errorf("JSON file not found: %s", json_path)
		return {}
	}

	defer delete(data)

	root, parse_err := json.parse(data, parse_integers = true)
	if parse_err == .None {
		defer json.destroy_value(root)
		if parsed := extract_frames_from_value(root); len(parsed) > 0 {
			return parsed
		}
	}

	sheet: Aseprite_Sheet
	if unmarshal_err := json.unmarshal(data, &sheet);
	   unmarshal_err == nil && len(sheet.frames) > 0 {
		defer delete(sheet.frames)
		out := make([]Frame_Rect, len(sheet.frames))
		for entry, i in sheet.frames {
			out[i] = entry.frame
		}

		return out
	}

	flat: Flat_Frame_Sheet
	if unmarshal_err := json.unmarshal(data, &flat); unmarshal_err == nil && len(flat.frames) > 0 {
		defer delete(flat.frames)
		out := make([]Frame_Rect, len(flat.frames))
		copy(out, flat.frames)
		return out
	}

	log.errorf("Failed to load/parse JSON %s: %v", json_path, parse_err)
	return {}
}
