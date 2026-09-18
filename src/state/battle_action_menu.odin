package state

import game_pkg "../game"

import "core:log"

import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"

battle_action_menu_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	game_pkg.grid_calculate_unit_movement_range(&game.grid, current)
	game.state_scratch.selected_command = .Attack
	sprites.command_icons_set_selected(.Attack)
	sprites.magic_ui_reset_layout_center(&game.magic_ui, game.window)
}

battle_action_menu_exit :: proc(_: ^game_pkg.Game) {}

battle_action_menu_set_command :: proc(game: ^game_pkg.Game, command: defs.Command_Icon) {
	if game.state_scratch.selected_command == command {
		return
	}

	game.state_scratch.selected_command = command
	sprites.command_icons_set_selected(command)
}

battle_action_menu_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_key_pressed(.UP) {
		battle_action_menu_set_command(game, .Attack)
	}

	if game_pkg.input_key_pressed(.DOWN) {
		battle_action_menu_set_command(game, .Stay)
	}

	if game_pkg.input_key_pressed(.LEFT) {
		battle_action_menu_set_command(game, .Magic)
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		battle_action_menu_set_command(game, .Item)
	}

	if game_pkg.input_confirm_press() {
		battle_action_menu_confirm(game)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .UnitMoving)
	}
}

battle_action_menu_confirm :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	log.debugf("BattleActionMenu: Confirmed command %v", game.state_scratch.selected_command)
	switch game.state_scratch.selected_command {
	case .Attack:
		state_change(game, .CalculateWeaponAttackRange)
	case .Stay:
		state_change(game, .TransitionSelectorToNextUnit)
	case .Magic:
		if unit_pkg.has_spells(current) {
			state_change(game, .SelectMagic)
		} else {
			state_show_message_notice(game, defs.MESSAGE_NOTICE.no_magic, .BattleActionMenu)
		}
	case .Item:
		if unit_pkg.has_giveable_item(current) {
			state_change(game, .BattleItemMenu)
		} else {
			state_show_message_notice(game, defs.MESSAGE_NOTICE.no_item, .BattleActionMenu)
		}
	case .Yes,
	     .No,
	     .Talk,
	     .Search,
	     .Use,
	     .Give,
	     .Equip,
	     .Drop,
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

battle_action_menu_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)
	sprites.command_icons_tick()
}

battle_action_menu_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	center := sprites.radial_center(game.window)
	sprites.radial_draw_command_icons(scale, center, sprites.BATTLE_ACTION_COMMANDS)
	sprites.renderer_draw_battle_menu_message(
		scale,
		sprites.command_icon_display_name(game.state_scratch.selected_command),
		sprites.radial_menu_message_position(center),
	)
}
