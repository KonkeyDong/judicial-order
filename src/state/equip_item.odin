package state

import game_pkg "../game"

import "../catalog"
import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"

equip_item_slot_equippable :: proc(caster: ^unit_pkg.Unit, index: int) -> bool {
	if caster == nil || index < 0 || index > 2 {
		return false
	}

	slot := caster.items[index]
	if unit_pkg.item_slot_is_empty(slot) {
		return false
	}

	return unit_pkg.can_equip_weapon(caster, catalog.item_get(slot.name))
}

equip_item_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	game.state_scratch.list_index = 3
	game.state_scratch.equip_unarmed = true

	if current != nil && current.equipped_weapon_index >= 0 && current.equipped_weapon_index <= 2 {
		if equip_item_slot_equippable(current, current.equipped_weapon_index) {
			game.state_scratch.list_index = current.equipped_weapon_index
			game.state_scratch.equip_unarmed = false
		}
	}
}

equip_item_exit :: proc(_: ^game_pkg.Game) {}

equip_item_handle_input :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if game_pkg.input_key_pressed(.UP) && equip_item_slot_equippable(current, 0) {
		game.state_scratch.list_index = 0
		game.state_scratch.equip_unarmed = false
	}

	if game_pkg.input_key_pressed(.LEFT) && equip_item_slot_equippable(current, 1) {
		game.state_scratch.list_index = 1
		game.state_scratch.equip_unarmed = false
	}

	if game_pkg.input_key_pressed(.RIGHT) && equip_item_slot_equippable(current, 2) {
		game.state_scratch.list_index = 2
		game.state_scratch.equip_unarmed = false
	}

	if game_pkg.input_key_pressed(.DOWN) {
		game.state_scratch.list_index = 3
		game.state_scratch.equip_unarmed = true
	}

	if game_pkg.input_confirm_press() {
		if current == nil {
			return
		}

		if game.state_scratch.equip_unarmed {
			unit_pkg.unequip_weapon(current)
		} else if equip_item_slot_equippable(current, game.state_scratch.list_index) {
			unit_pkg.equip_weapon_at(current, game.state_scratch.list_index)
		}

		state_change(game, .BattleItemMenu)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleItemMenu)
	}
}

equip_item_update :: proc(game: ^game_pkg.Game) {
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.item_icons_tick()
}

equip_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, false, false)
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	center := sprites.radial_center(game.window)
	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := sprites.radial_index_for_direction(direction)
		name: defs.Item_Name
		selected: bool
		if index == 3 {
			name = .Unarmed
			selected = game.state_scratch.equip_unarmed
		} else if equip_item_slot_equippable(current, index) {
			name = current.items[index].name
			selected = !game.state_scratch.equip_unarmed && game.state_scratch.list_index == index
		} else {
			name = .NoItem
		}

		sprites.renderer_draw_item_icon(
			scale,
			name,
			sprites.radial_icon_position(center, direction),
			selected,
		)
	}
}
