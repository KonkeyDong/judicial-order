package state

import game_pkg "../game"

import "../defs"
import "../sprites"
import unit_pkg "../unit"
import rl "vendor:raylib"

state_item_handle_slot_keys :: proc(
	game: ^game_pkg.Game,
	caster: ^unit_pkg.Unit,
	filter: sprites.Item_Slot_Filter,
) {
	if game_pkg.input_key_pressed(.UP) {
		sprites.item_ui_set_selected(&game.item_ui, .Up, caster, filter)
	}

	if game_pkg.input_key_pressed(.LEFT) {
		sprites.item_ui_set_selected(&game.item_ui, .Left, caster, filter)
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		sprites.item_ui_set_selected(&game.item_ui, .Right, caster, filter)
	}

	if game_pkg.input_key_pressed(.DOWN) {
		sprites.item_ui_set_selected(&game.item_ui, .Down, caster, filter)
	}
}

state_draw_item_icons :: proc(
	scale: f32,
	center: rl.Vector2,
	owner: ^unit_pkg.Unit,
	selected_index: int,
	filter: sprites.Item_Slot_Filter = nil,
	blank_disallowed := false,
) {
	if owner == nil {
		return
	}

	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := sprites.radial_index_for_direction(direction)
		slot := owner.items[index]
		name := unit_pkg.item_display_name(slot.name)
		if blank_disallowed && filter != nil && !filter(slot, owner) {
			name = .NoItem
		}

		sprites.renderer_draw_item_icon(
			scale,
			name,
			sprites.radial_icon_position(center, direction),
			selected_index >= 0 && index == selected_index,
		)
	}
}

state_draw_item_radial :: proc(game: ^game_pkg.Game, scale: f32, owner: ^unit_pkg.Unit) {
	state_draw_item_icons(scale, game.item_ui.center, owner, game.item_ui.selected_index)
}
