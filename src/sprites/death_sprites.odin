package sprites

import "core:log"
import "core:reflect"

import "../defs"

death_frames: [dynamic]Sprite

death_sprites_destroy :: proc() {
	delete(death_frames)
	death_frames = nil
}

death_sprites_load :: proc() {
	if len(death_frames) > 0 {
		log.debug("Death sprite frame data has already been loaded.")
		return
	}

	if !battle_sprites_ready() {
		return
	}

	name := battle_snake_case(reflect.enum_string(defs.Attack_Effect.BattleFieldDeath))
	dir := join_path({defs.PATHS.effects, name})
	json_path := join_path({dir, defs.PATHS.effect_json})
	png_path := join_path({dir, defs.PATHS.effect_png})

	frames := extract_frames(json_path)
	defer delete(frames)

	if len(frames) == 0 {
		log.errorf("Death sprites: no frames in %s.", json_path)
		return
	}

	tex := load(png_path)
	for frame in frames {
		append(&death_frames, Sprite{texture = tex, frame = frame})
	}

	log.infof("Death sprites have been loaded (%d).", len(death_frames))
}

death_sprites_count :: proc() -> int {
	return len(death_frames)
}

death_sprites_frame :: proc(index: int) -> (Sprite, bool) {
	if index < 0 || index >= len(death_frames) {
		return {}, false
	}

	return death_frames[index], true
}
