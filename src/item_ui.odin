package game

import "catalog"
import "defs"
import unit_pkg "unit"
import rl "vendor:raylib"

Item_Slot_Filter :: #type proc(slot: unit_pkg.Item_Slot, caster: ^unit_pkg.Unit) -> bool

Item_UI :: struct {
	selected_index: int,
	selected_name:  defs.Item_Name,
	center:         rl.Vector2,
	info_box:       rl.Vector2,
}

item_ui_reset :: proc(ui: ^Item_UI) {
	ui.selected_index = -1
	ui.selected_name = .NoItem
}

item_ui_set_layout_center :: proc(ui: ^Item_UI, center: rl.Vector2) {
	ui.center = center
	ui.info_box = radial_info_box_position(center)
}

item_ui_reset_layout_center :: proc(game: ^Game) {
	item_ui_set_layout_center(&game.item_ui, radial_center(game))
}

item_ui_giveable_filter :: proc(slot: unit_pkg.Item_Slot, _: ^unit_pkg.Unit) -> bool {
	return !unit_pkg.item_slot_is_empty(slot) && slot.name != .Unarmed
}

item_ui_usable_filter :: proc(slot: unit_pkg.Item_Slot, caster: ^unit_pkg.Unit) -> bool {
	if caster == nil || unit_pkg.item_slot_is_empty(slot) {
		return false
	}

	return unit_pkg.item_is_usable(slot.name, caster.job)
}

item_ui_has_selection :: proc(ui: ^Item_UI) -> bool {
	return ui.selected_index >= 0
}

item_ui_has_valid_selection :: proc(
	ui: ^Item_UI,
	caster: ^unit_pkg.Unit,
	can_select: Item_Slot_Filter,
) -> bool {
	if caster == nil || ui.selected_index < 0 || ui.selected_index >= defs.MAX_BUCKET_SIZE {
		return false
	}

	return can_select(caster.items[ui.selected_index], caster)
}

item_ui_set_selected :: proc(
	ui: ^Item_UI,
	direction: defs.Direction,
	caster: ^unit_pkg.Unit,
	can_select: Item_Slot_Filter,
) {
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

	slot := caster.items[index]
	if !can_select(slot, caster) {
		return
	}

	ui.selected_index = index
	ui.selected_name = slot.name
}

item_ui_select_first :: proc(ui: ^Item_UI, caster: ^unit_pkg.Unit, can_select: Item_Slot_Filter) {
	if caster == nil {
		item_ui_reset(ui)
		return
	}

	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := radial_index_for_direction(direction)
		if index < 0 {
			continue
		}

		slot := caster.items[index]
		if can_select(slot, caster) {
			ui.selected_index = index
			ui.selected_name = slot.name
			return
		}
	}

	item_ui_reset(ui)
}

item_ui_selected_data :: proc(ui: ^Item_UI) -> catalog.Item_Data {
	return catalog.item_get(ui.selected_name)
}
