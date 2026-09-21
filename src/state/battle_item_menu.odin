package state

import game_pkg "../game"
import unit_pkg "../unit"

import "core:log"

import "../defs"
import "../sprites"
import "../timers"


battle_item_menu_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current != nil {
		game_pkg.grid_calculate_unit_movement_range(&game.grid, current)
	}

	game.state_scratch.selected_command = .Use
	sprites.command_icons_set_selected(.Use)
}

battle_item_menu_set_command :: proc(game: ^game_pkg.Game, command: defs.Command_Icon) {
	if game.state_scratch.selected_command == command {
		return
	}

	game.state_scratch.selected_command = command
	sprites.command_icons_set_selected(command)
}

battle_item_menu_exit :: proc(_: ^game_pkg.Game) {}

battle_item_menu_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_key_pressed(.UP) {
		battle_item_menu_set_command(game, .Use)
	}

	if game_pkg.input_key_pressed(.DOWN) {
		battle_item_menu_set_command(game, .Drop)
	}

	if game_pkg.input_key_pressed(.LEFT) {
		battle_item_menu_set_command(game, .Give)
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		battle_item_menu_set_command(game, .Equip)
	}

	if game_pkg.input_confirm_press() {
		battle_item_menu_confirm(game)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleActionMenu)
	}
}

battle_item_menu_confirm :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	switch game.state_scratch.selected_command {
	case .Use:
		if !unit_pkg.has_usable_item(current) {
			state_show_message_notice(game, defs.MESSAGE_NOTICE.no_item, .BattleItemMenu)
			return
		}

		state_change(game, .UseWhichItem)
	case .Drop:
		state_change(game, .DropItem)
	case .Give:
		if !unit_pkg.has_giveable_item(current) {
			log.warn("Give: no giveable items in inventory.")
			return
		}

		state_change(game, .GiveWhichItem)
	case .Equip:
		state_change(game, .EquipItem)
	case .Attack,
	     .Stay,
	     .Magic,
	     .Item,
	     .Yes,
	     .No,
	     .Talk,
	     .Search,
	     .Map,
	     .Speed,
	     .Message,
	     .Quit,
	     .Save,
	     .Cure,
	     .Raise,
	     .Promote,
	     .Buy,
	     .Deals,
	     .Sell,
	     .Repair:
	}
}

battle_item_menu_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.command_icons_tick()
}

battle_item_menu_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	center := sprites.radial_center(game.window)
	sprites.radial_draw_command_icons(scale, center, sprites.BATTLE_ITEM_COMMANDS)
	sprites.renderer_draw_battle_menu_message(
		scale,
		sprites.command_icon_display_name(game.state_scratch.selected_command),
		sprites.radial_menu_message_position(center),
	)
}
