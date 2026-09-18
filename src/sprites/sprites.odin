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

	sheet: Aseprite_Sheet
	if err := json.unmarshal(data, &sheet); err != nil {
		log.errorf("Failed to load/parse JSON %s: %v", json_path, err)
		return {}
	}

	defer delete(sheet.frames)

	if len(sheet.frames) == 0 {
		log.warnf("No frames found in JSON: %s", json_path)
		return {}
	}

	out := make([]Frame_Rect, len(sheet.frames))
	for entry, i in sheet.frames {
		out[i] = entry.frame
	}

	return out
}
