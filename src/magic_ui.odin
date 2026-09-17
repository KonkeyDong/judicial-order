package game

import "catalog"
import "defs"
import unit_pkg "unit"
import rl "vendor:raylib"

Magic_UI :: struct {
	selected_index:  int,
	selected_family: defs.Magic_Family,
	selected_name:   defs.Magic_Name,
	selected_level:  int,
	center:          rl.Vector2,
	info_box:        rl.Vector2,
}

magic_ui_reset :: proc(ui: ^Magic_UI) {
	ui.selected_index = -1
	ui.selected_family = .NoSpell
	ui.selected_name = .NoSpell
	ui.selected_level = 0
}

magic_ui_set_layout_center :: proc(ui: ^Magic_UI, center: rl.Vector2) {
	ui.center = center
	ui.info_box = radial_info_box_position(center)
}

magic_ui_reset_layout_center :: proc(game: ^Game) {
	magic_ui_set_layout_center(&game.magic_ui, radial_center(game))
}

magic_ui_set_selected :: proc(game: ^Game, direction: defs.Direction, caster: ^unit_pkg.Unit) {
	if caster == nil {
		return
	}

	index := radial_index_for_direction(direction)
	if index < 0 {
		return
	}

	if game.magic_ui.selected_index == index {
		return
	}

	family := caster.magic_family_buckets[index]
	if family == .NoSpell {
		return
	}

	list := unit_pkg.magic_list_in_bucket(caster, family)
	game.magic_ui.selected_index = index
	game.magic_ui.selected_family = family
	if len(list) == 0 {
		game.magic_ui.selected_name = .NoSpell
		game.magic_ui.selected_level = 0
		return
	}

	game.magic_ui.selected_level = len(list) - 1
	game.magic_ui.selected_name = list[game.magic_ui.selected_level]
}

magic_ui_selected_data :: proc(game: ^Game) -> catalog.Magic_Data {
	return catalog.magic_get(game.magic_ui.selected_name)
}

magic_ui_is_offensive :: proc(game: ^Game) -> bool {
	return magic_ui_selected_data(game).offensive
}

magic_ui_next_level :: proc(game: ^Game, caster: ^unit_pkg.Unit) {
	if caster == nil || game.magic_ui.selected_family == .NoSpell {
		return
	}

	list := unit_pkg.magic_list_in_bucket(caster, game.magic_ui.selected_family)
	if len(list) <= 1 {
		return
	}

	game.magic_ui.selected_level += 1
	if game.magic_ui.selected_level >= len(list) {
		game.magic_ui.selected_level = 0
	}

	game.magic_ui.selected_name = list[game.magic_ui.selected_level]
}

magic_ui_previous_level :: proc(game: ^Game, caster: ^unit_pkg.Unit) {
	if caster == nil || game.magic_ui.selected_family == .NoSpell {
		return
	}

	list := unit_pkg.magic_list_in_bucket(caster, game.magic_ui.selected_family)
	if len(list) <= 1 {
		return
	}

	game.magic_ui.selected_level -= 1
	if game.magic_ui.selected_level < 0 {
		game.magic_ui.selected_level = len(list) - 1
	}

	game.magic_ui.selected_name = list[game.magic_ui.selected_level]
}
