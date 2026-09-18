package sprites

import "../catalog"
import "../defs"
import unit_pkg "../unit"
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

magic_ui_reset_layout_center :: proc(ui: ^Magic_UI, window: defs.Window_View) {
	magic_ui_set_layout_center(ui, radial_center(window))
}

magic_ui_set_selected :: proc(ui: ^Magic_UI, direction: defs.Direction, caster: ^unit_pkg.Unit) {
	if caster == nil {
		return
	}

	index := radial_index_for_direction(direction)
	if index < 0 {
		return
	}

	if ui.selected_index == index {
		return
	}

	family := caster.magic_family_buckets[index]
	if family == .NoSpell {
		return
	}

	list := unit_pkg.magic_list_in_bucket(caster, family)
	ui.selected_index = index
	ui.selected_family = family
	if len(list) == 0 {
		ui.selected_name = .NoSpell
		ui.selected_level = 0
		return
	}

	ui.selected_level = len(list) - 1
	ui.selected_name = list[ui.selected_level]
}

magic_ui_selected_data :: proc(ui: ^Magic_UI) -> catalog.Magic_Data {
	return catalog.magic_get(ui.selected_name)
}

magic_ui_is_offensive :: proc(ui: ^Magic_UI) -> bool {
	return magic_ui_selected_data(ui).offensive
}

magic_ui_next_level :: proc(ui: ^Magic_UI, caster: ^unit_pkg.Unit) {
	if caster == nil || ui.selected_family == .NoSpell {
		return
	}

	list := unit_pkg.magic_list_in_bucket(caster, ui.selected_family)
	if len(list) <= 1 {
		return
	}

	ui.selected_level += 1
	if ui.selected_level >= len(list) {
		ui.selected_level = 0
	}

	ui.selected_name = list[ui.selected_level]
}

magic_ui_previous_level :: proc(ui: ^Magic_UI, caster: ^unit_pkg.Unit) {
	if caster == nil || ui.selected_family == .NoSpell {
		return
	}

	list := unit_pkg.magic_list_in_bucket(caster, ui.selected_family)
	if len(list) <= 1 {
		return
	}

	ui.selected_level -= 1
	if ui.selected_level < 0 {
		ui.selected_level = len(list) - 1
	}

	ui.selected_name = list[ui.selected_level]
}
