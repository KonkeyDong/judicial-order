package sprites

import "core:c"
import "core:log"
import "core:math/rand"
import "core:os"
import "core:reflect"
import "core:strings"

import "../defs"
import "../unit"
import rl "vendor:raylib"

Battle_Unit_Sprite_Set :: struct {
	idle:            [dynamic]Sprite,
	attack:          [dynamic]Sprite,
	battle_sequence: [dynamic]Sprite,
	base_position:   rl.Vector2,
}

battle_sprites_ready :: proc() -> bool {
	return cache.textures.allocator.procedure != nil
}

battle_unit_sprite_set_load :: proc(target: ^unit.Unit) -> Battle_Unit_Sprite_Set {
	if target == nil {
		log.panic("target is nil.")
	}

	if !battle_sprites_ready() {
		return {}
	}

	dir := battle_unit_dir(target)
	set: Battle_Unit_Sprite_Set
	set.idle = battle_load_sheet(
		join_path({dir, defs.PATHS.idle_png}),
		join_path({dir, defs.PATHS.idle_json}),
	)
	set.attack = battle_load_sheet(
		join_path({dir, defs.PATHS.attack_png}),
		join_path({dir, defs.PATHS.attack_json}),
	)
	log.infof(
		"Battle sprites for %s: idle %d, attack %d (%s).",
		defs.name_display(target.name),
		len(set.idle),
		len(set.attack),
		dir,
	)
	return set
}

battle_unit_sprite_set_reset :: proc(set: ^Battle_Unit_Sprite_Set) {
	if set == nil {
		log.panic("set is nil.")
	}

	battle_unload_owned_sequence(set)
	delete(set.idle)
	delete(set.attack)
	delete(set.battle_sequence)
	set^ = {}
}

battle_idle_frame :: proc(set: ^Battle_Unit_Sprite_Set, frame_index: int) -> (Sprite, bool) {
	if set == nil {
		log.panic("set is nil.")
	}

	count := len(set.idle)
	if count == 0 {
		return {}, false
	}

	if count == 1 {
		return set.idle[0], true
	}

	index := frame_index
	if index < 0 {
		index = 0
	}

	return set.idle[index % count], true
}

battle_attack_frame :: proc(set: ^Battle_Unit_Sprite_Set, frame_index: int) -> (Sprite, bool) {
	if set == nil {
		log.panic("set is nil.")
	}

	count := len(set.attack)
	if count == 0 {
		return {}, false
	}

	index := frame_index
	if index < 0 {
		index = 0
	}

	return set.attack[index % count], true
}

battle_sequence_frame :: proc(set: ^Battle_Unit_Sprite_Set, frame_index: int) -> (Sprite, bool) {
	if set == nil {
		log.panic("set is nil.")
	}

	count := len(set.battle_sequence)
	if count == 0 {
		return {}, false
	}

	index := frame_index
	if index < 0 {
		index = 0
	}

	if index >= count {
		index = count - 1
	}

	return set.battle_sequence[index], true
}

// Pose copies follow the attacker's attack sheet. An empty attack sheet leaves both sequences empty.
battle_build_normal_attack_scene :: proc(
	attacker_set, defender_set: ^Battle_Unit_Sprite_Set,
	hit, defender_killed, debug_draw: bool,
) -> int {
	if attacker_set == nil {
		log.panic("attacker_set is nil.")
	}

	if defender_set == nil {
		log.panic("defender_set is nil.")
	}

	if len(attacker_set.attack) == 0 {
		return 0
	}

	pose_copies := 1 if debug_draw else defs.ANIMATIONS.attack_delay
	if debug_draw {
		battle_append_attacker_idle_prefix(attacker_set, defender_set)
	}

	last := len(attacker_set.attack) - 1
	damage_apply_frame := last * pose_copies
	for i in 0 ..< len(attacker_set.attack) {
		attack_frame, attack_ok := battle_attack_frame(attacker_set, i)
		if attack_ok {
			battle_append_copies(attacker_set, attack_frame, pose_copies, false)
		}

		idle_frame, idle_ok := battle_idle_frame(defender_set, i)
		if idle_ok {
			battle_append_copies(defender_set, idle_frame, pose_copies, hit && i == last)
		}
	}

	if hit && defender_killed {
		hold := defs.ANIMATIONS.dissolve.number_of_frame_copies * defs.ANIMATIONS.dissolve.group_size
		last_attack, attack_ok := battle_attack_frame(attacker_set, last)
		if attack_ok {
			battle_append_copies(attacker_set, last_attack, hold, false)
		}

		base, idle_ok := battle_idle_frame(defender_set, 0)
		if idle_ok {
			copies := defs.ANIMATIONS.dissolve.number_of_frame_copies
			for step in 1 ..= defs.ANIMATIONS.dissolve.group_size {
				dissolved := battle_sprite_dissolve(base, step)
				battle_append_copies(defender_set, dissolved, copies, false)
			}
		}
	}

	return damage_apply_frame
}

@(private)
battle_unit_dir :: proc(target: ^unit.Unit) -> string {
	if target == nil {
		log.panic("target is nil.")
	}

	name := battle_snake_case(defs.name_base(target.name))
	if name == "" {
		return ""
	}

	if target.friendly {
		promo := defs.PATHS.promoted if unit.is_promoted(target) else defs.PATHS.unpromoted
		weapon := battle_snake_case(reflect.enum_string(unit.equipped_weapon_name(target)))
		if weapon == "" {
			return ""
		}

		return join_path({defs.PATHS.force_members, name, promo, defs.PATHS.battle, weapon})
	}

	return join_path({defs.PATHS.monsters, name, defs.PATHS.battle})
}

@(private)
battle_snake_case :: proc(raw: string) -> string {
	snake, err := strings.to_snake_case(raw, context.temp_allocator)
	if err != nil {
		log.errorf("battle_snake_case: failed for %q.", raw)
		return ""
	}

	return snake
}

@(private)
battle_load_sheet :: proc(png_path, json_path: string) -> [dynamic]Sprite {
	if png_path == "" || json_path == "" || !os.exists(png_path) || !os.exists(json_path) {
		return nil
	}

	frames := extract_frames(json_path)
	defer delete(frames)
	if len(frames) == 0 {
		return nil
	}

	tex := load(png_path)
	sheet: [dynamic]Sprite
	for frame in frames {
		append(&sheet, Sprite{texture = tex, frame = frame})
	}

	return sheet
}

@(private)
battle_append_attacker_idle_prefix :: proc(
	attacker_set, defender_set: ^Battle_Unit_Sprite_Set,
) {
	if attacker_set == nil {
		log.panic("attacker_set is nil.")
	}

	if defender_set == nil {
		log.panic("defender_set is nil.")
	}

	if len(attacker_set.idle) == 0 {
		log.warn("battle_append_attacker_idle_prefix: attacker has no idle frames; skipping.")
		return
	}

	for i in 0 ..< len(attacker_set.idle) {
		append(&attacker_set.battle_sequence, attacker_set.idle[i])
		if frame, ok := battle_idle_frame(defender_set, 0); ok {
			append(&defender_set.battle_sequence, frame)
		}
	}
}

@(private)
battle_append_copies :: proc(set: ^Battle_Unit_Sprite_Set, sprite: Sprite, count: int, invert: bool) {
	if set == nil {
		log.panic("set is nil.")
	}

	if count <= 0 {
		log.error("battle_append_copies: count must be greater than zero.")
		return
	}

	if !invert {
		for _ in 0 ..< count {
			append(&set.battle_sequence, sprite)
		}

		return
	}

	inverted := battle_sprite_invert(sprite)
	if !inverted.owns_texture {
		for _ in 0 ..< count {
			append(&set.battle_sequence, sprite)
		}

		return
	}

	for _ in 0 ..< count {
		append(&set.battle_sequence, battle_sprite_jitter(inverted))
	}
}

@(private)
battle_sprite_invert :: proc(sprite: Sprite) -> Sprite {
	if sprite.texture.id == 0 {
		log.error("battle_sprite_invert: texture is unloaded.")
		return sprite
	}

	image := rl.LoadImageFromTexture(sprite.texture)
	rl.ImageColorInvert(&image)
	texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	if texture.id == 0 {
		log.error("battle_sprite_invert: failed to create texture.")
		return sprite
	}

	inverted := sprite
	inverted.texture = texture
	inverted.owns_texture = true
	return inverted
}

@(private)
battle_sprite_jitter :: proc(sprite: Sprite) -> Sprite {
	jittered := sprite
	jittered.owns_texture = true
	offset := defs.ANIMATIONS.jitter_offset
	jittered.frame.offset_x += rand.int_max(2) * (offset * 2) - offset
	jittered.frame.offset_y += rand.int_max(2) * (offset * 2) - offset
	return jittered
}

@(private)
battle_sprite_dissolve :: proc(sprite: Sprite, clear_amount: int) -> Sprite {
	if sprite.texture.id == 0 {
		log.error("battle_sprite_dissolve: texture is unloaded.")
		return sprite
	}

	width := sprite.frame.w
	height := sprite.frame.h
	group_size := defs.ANIMATIONS.dissolve.group_size
	if group_size <= 0 || width <= 0 || height <= 0 {
		log.error("battle_sprite_dissolve: invalid frame.")
		return sprite
	}

	image := rl.LoadImageFromTexture(sprite.texture)
	for y in 0 ..< height {
		for x in 0 ..< width {
			group_index := (y * width + x) % group_size
			if group_index < clear_amount {
				rl.ImageDrawPixel(
					&image,
					c.int(x + sprite.frame.x),
					c.int(y + sprite.frame.y),
					rl.BLANK,
				)
			}
		}
	}

	texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	if texture.id == 0 {
		log.error("battle_sprite_dissolve: failed to create texture.")
		return sprite
	}

	dissolved := sprite
	dissolved.texture = texture
	dissolved.owns_texture = true
	return dissolved
}

@(private)
battle_unload_owned_sequence :: proc(set: ^Battle_Unit_Sprite_Set) {
	if set == nil {
		log.panic("set is nil.")
	}

	seen: [dynamic]c.uint
	defer delete(seen)
	for sprite in set.battle_sequence {
		if !sprite.owns_texture || sprite.texture.id == 0 {
			continue
		}

		already := false
		for id in seen {
			if id == sprite.texture.id {
				already = true
				break
			}
		}

		if already {
			continue
		}

		append(&seen, sprite.texture.id)
		rl.UnloadTexture(sprite.texture)
	}
}
