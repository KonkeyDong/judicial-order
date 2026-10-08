package sprites

import "core:testing"

import "../defs"
import "../unit"

@(test)
test_battle_field_death_has_eight_frames :: proc(test: ^testing.T) {
	frames := extract_frames("assets/sprites/shared/effects/battle_field_death/effect.json")
	defer delete(frames)
	testing.expect_value(test, len(frames), 8)
	if len(frames) != 8 {
		return
	}

	testing.expect_value(test, frames[0].x, 0)
	testing.expect_value(test, frames[0].y, 0)
	testing.expect_value(test, frames[0].w, 24)
	testing.expect_value(test, frames[0].h, 24)
	testing.expect_value(test, frames[7].x, 168)
	testing.expect_value(test, frames[7].w, 24)
	testing.expect_value(test, frames[7].h, 24)
}

@(test)
test_extract_frames_weasel_lawyer :: proc(test: ^testing.T) {
	frames := extract_frames("assets/sprites/weasel_lawyer.json")
	defer delete(frames)

	testing.expect_value(test, len(frames), 2)
	if len(frames) < 2 {
		return
	}

	testing.expect_value(test, frames[0].x, 0)
	testing.expect_value(test, frames[0].y, 0)
	testing.expect_value(test, frames[0].w, 24)
	testing.expect_value(test, frames[0].h, 24)
	testing.expect_value(test, frames[0].offset_x, 0)
	testing.expect_value(test, frames[0].offset_y, 0)

	testing.expect_value(test, frames[1].x, 24)
	testing.expect_value(test, frames[1].y, 0)
	testing.expect_value(test, frames[1].w, 24)
	testing.expect_value(test, frames[1].h, 24)
	testing.expect_value(test, frames[1].offset_x, 0)
	testing.expect_value(test, frames[1].offset_y, 0)
}

@(test)
test_extract_frames_item_icons :: proc(test: ^testing.T) {
	frames := extract_frames("assets/sprites/shared/item_icons/FrameData.json")
	defer delete(frames)

	testing.expect_value(test, len(frames), 2)
	if len(frames) < 2 {
		return
	}

	testing.expect_value(test, frames[0].x, 0)
	testing.expect_value(test, frames[0].y, 0)
	testing.expect_value(test, frames[0].w, 17)
	testing.expect_value(test, frames[0].h, 25)
	testing.expect_value(test, frames[1].x, 17)
	testing.expect_value(test, frames[1].y, 0)
	testing.expect_value(test, frames[1].w, 17)
	testing.expect_value(test, frames[1].h, 25)
}

@(test)
test_extract_frames_battle_planes :: proc(test: ^testing.T) {
	background := extract_frames("assets/backgrounds/FrameData.json")
	defer delete(background)
	testing.expect_value(test, len(background), 1)
	if len(background) > 0 {
		testing.expect_value(test, background[0].x, 0)
		testing.expect_value(test, background[0].y, 0)
		testing.expect_value(test, background[0].w, 256)
		testing.expect_value(test, background[0].h, 96)
	}

	foreground := extract_frames("assets/foreground/FrameData.json")
	defer delete(foreground)
	testing.expect_value(test, len(foreground), 1)
	if len(foreground) > 0 {
		testing.expect_value(test, foreground[0].x, 0)
		testing.expect_value(test, foreground[0].y, 0)
		testing.expect_value(test, foreground[0].w, 96)
		testing.expect_value(test, foreground[0].h, 32)
	}
}

@(test)
test_battle_plane_png_path_uses_placeholder :: proc(test: ^testing.T) {
	background_named := battle_plane_png_path(
		defs.PATHS.backgrounds,
		"law_101",
		defs.PATHS.background_placeholder,
	)
	testing.expect_value(test, background_named, "assets/backgrounds/law_101.png")

	background_missing := battle_plane_png_path(
		defs.PATHS.backgrounds,
		"GatesOfGuardiana",
		defs.PATHS.background_placeholder,
	)
	testing.expect_value(test, background_missing, "assets/backgrounds/law_101.png")

	foreground_named := battle_plane_png_path(
		defs.PATHS.foreground,
		"class_room",
		defs.PATHS.foreground_placeholder,
	)
	testing.expect_value(test, foreground_named, "assets/foreground/class_room.png")

	foreground_missing := battle_plane_png_path(
		defs.PATHS.foreground,
		"RoughTerrain",
		defs.PATHS.foreground_placeholder,
	)
	testing.expect_value(test, foreground_missing, "assets/foreground/class_room.png")
}

@(test)
test_icon_set_defaults_and_blink :: proc(test: ^testing.T) {
	item_icons_init()
	magic_icons_init()
	command_icons_init()
	defer item_icons_destroy()
	defer magic_icons_destroy()
	defer command_icons_destroy()

	testing.expect_value(test, item_icons.selected, defs.Item_Name.NoItem)
	testing.expect_value(test, magic_icons.selected, defs.Magic_Family.Blaze)
	testing.expect_value(test, command_icons.selected, defs.Command_Icon.Attack)

	frame0 := Sprite {
		frame = {x = 0, y = 0, w = 24, h = 24},
	}
	frame1 := Sprite {
		frame = {x = 24, y = 0, w = 24, h = 24},
	}
	item_icons.animations[.SmallBriefcase] = {frame0, frame1}
	item_icons_set_selected(.SmallBriefcase)

	item_icons.flip_flop.is_on = true
	selected_on := item_icons_get(.SmallBriefcase)
	testing.expect_value(test, selected_on.frame.x, 24)

	item_icons.flip_flop.is_on = false
	selected_off := item_icons_get(.SmallBriefcase)
	testing.expect_value(test, selected_off.frame.x, 0)

	old_logger := context.logger
	context.logger = {}
	missing := item_icons_get(.Hotdog)
	context.logger = old_logger
	testing.expect_value(test, missing, Sprite{})

	no_item := Sprite {
		frame = {x = 1, y = 2, w = 17, h = 25},
	}
	item_icons.animations[.NoItem] = {no_item, no_item}
	placeholder := item_icons_get(.Hotdog)
	testing.expect_value(test, placeholder.frame, no_item.frame)
	testing.expect_value(test, item_icons_resolve(.Hotdog), defs.Item_Name.NoItem)
	testing.expect_value(test, item_icons_resolve(.SmallBriefcase), defs.Item_Name.SmallBriefcase)

	command_icons.animations[.Attack] = {frame0, frame1}
	command_icons_set_selected(.Attack)
	command_icons.flip_flop.is_on = true
	attack_on := command_icons_get(.Attack)
	testing.expect_value(test, attack_on.frame.x, 24)

	command_icons.flip_flop.is_on = false
	attack_off := command_icons_get(.Attack)
	testing.expect_value(test, attack_off.frame.x, 0)
}

@(test)
test_extract_frames_law_professor_battle :: proc(test: ^testing.T) {
	idle := extract_frames("assets/sprites/monsters/law_professor/battle/idle.json")
	defer delete(idle)
	testing.expect_value(test, len(idle), 1)
	if len(idle) > 0 {
		testing.expect_value(test, idle[0].x, 0)
		testing.expect_value(test, idle[0].y, 0)
		testing.expect_value(test, idle[0].w, 72)
		testing.expect_value(test, idle[0].h, 96)
	}

	attack := extract_frames("assets/sprites/monsters/law_professor/battle/attack.json")
	defer delete(attack)
	testing.expect_value(test, len(attack), 2)
	if len(attack) > 1 {
		testing.expect_value(test, attack[0].w, 72)
		testing.expect_value(test, attack[0].h, 96)
		testing.expect_value(test, attack[1].x, 72)
		testing.expect_value(test, attack[1].w, 72)
		testing.expect_value(test, attack[1].h, 96)
	}
}

@(test)
test_battle_sprite_position_law_professor :: proc(test: ^testing.T) {
	professor: unit.Unit
	professor.name = .LawProfessor
	testing.expect_value(
		test,
		battle_sprite_position_key(&professor),
		"LawProfessor_Unpromoted_Unarmed",
	)
	pos := battle_sprite_position(&professor, {0, 0})
	testing.expect_value(test, pos.x, f32(40))
	testing.expect_value(test, pos.y, f32(50))

	hale: unit.Unit
	hale.name = .Hale
	hale.friendly = true
	hale.equipped_weapon_index = defs.UNARMED_INDEX
	testing.expect_value(test, battle_sprite_position_key(&hale), "Hale_Unpromoted_Unarmed")
	hale.promoted = true
	testing.expect_value(test, battle_sprite_position_key(&hale), "Hale_Promoted_Unarmed")
	hale.items[0].name = .SmallBriefcase
	hale.equipped_weapon_index = 0
	testing.expect_value(test, battle_sprite_position_key(&hale), "Hale_Promoted_SmallBriefcase")

	fallback := defs.BATTLE.positions.friendly_standin
	missing := battle_sprite_position(&hale, fallback)
	testing.expect_value(test, missing.x, fallback.x)
	testing.expect_value(test, missing.y, fallback.y)
}

@(test)
test_law_professor_overworld_walk_set :: proc(test: ^testing.T) {
	professor: unit.Unit
	professor.name = .LawProfessor
	dir := unit_overworld_dir(&professor)
	testing.expect_value(test, dir, "assets/sprites/monsters/law_professor/overworld")
	testing.expect(test, structured_walk_complete(dir))

	frames := extract_frames(join_path({dir, "frame_data.json"}))
	defer delete(frames)
	testing.expect_value(test, len(frames), 2)
	if len(frames) > 1 {
		testing.expect_value(test, frames[0].w, 24)
		testing.expect_value(test, frames[0].h, 24)
		testing.expect_value(test, frames[1].x, 24)
		testing.expect_value(test, frames[1].w, 24)
		testing.expect_value(test, frames[1].h, 24)
	}

	hale: unit.Unit
	hale.name = .Hale
	hale.friendly = true
	hale.equipped_weapon_index = defs.UNARMED_INDEX
	testing.expect(test, !structured_walk_complete(unit_overworld_dir(&hale)))
}

@(test)
test_battle_unit_dir_snake_case :: proc(test: ^testing.T) {
	professor: unit.Unit
	professor.name = .LawProfessor
	testing.expect_value(
		test,
		battle_unit_dir(&professor),
		"assets/sprites/monsters/law_professor/battle",
	)

	hale: unit.Unit
	hale.name = .Hale
	hale.friendly = true
	hale.equipped_weapon_index = defs.UNARMED_INDEX
	testing.expect_value(
		test,
		battle_unit_dir(&hale),
		"assets/sprites/force/hale/unpromoted/battle/unarmed",
	)
}

@(test)
test_battle_sequence_paces_attack_sheet :: proc(test: ^testing.T) {
	attacker: Battle_Unit_Sprite_Set
	defender: Battle_Unit_Sprite_Set
	defer battle_unit_sprite_set_reset(&attacker)
	defer battle_unit_sprite_set_reset(&defender)

	append(&attacker.attack, Sprite{frame = {w = 72, h = 96}})
	append(&attacker.attack, Sprite{frame = {x = 72, w = 72, h = 96}})
	append(&defender.idle, Sprite{frame = {w = 72, h = 96}})

	frame := battle_build_normal_attack_scene(&attacker, &defender, false, false, true)
	testing.expect_value(test, frame, 1)
	testing.expect_value(test, len(attacker.battle_sequence), 2)
	testing.expect_value(test, len(defender.battle_sequence), 2)
	testing.expect_value(test, attacker.battle_sequence[1].frame.x, 72)
}

@(test)
test_battle_sequence_empty_without_attack_sheet :: proc(test: ^testing.T) {
	attacker: Battle_Unit_Sprite_Set
	defender: Battle_Unit_Sprite_Set
	defer battle_unit_sprite_set_reset(&attacker)
	defer battle_unit_sprite_set_reset(&defender)

	append(&defender.idle, Sprite{frame = {w = 72, h = 96}})
	frame := battle_build_normal_attack_scene(&attacker, &defender, true, true, true)
	testing.expect_value(test, frame, 0)
	testing.expect_value(test, len(attacker.battle_sequence), 0)
	testing.expect_value(test, len(defender.battle_sequence), 0)
}
