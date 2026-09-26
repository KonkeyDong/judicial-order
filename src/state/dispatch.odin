package state

import game_pkg "../game"

import "core:log"

import "../defs"
import "../sprites"

State_Procs :: struct {
	enter:        proc(game: ^game_pkg.Game),
	exit:         proc(game: ^game_pkg.Game),
	handle_input: proc(game: ^game_pkg.Game),
	update:       proc(game: ^game_pkg.Game),
	draw:         proc(game: ^game_pkg.Game, scale: f32),
}

state_noop :: proc(_: ^game_pkg.Game) {}
state_noop_draw :: proc(_: ^game_pkg.Game, _: f32) {}

STATE_NOOP := State_Procs {
	enter        = state_noop,
	exit         = state_noop,
	handle_input = state_noop,
	update       = state_noop,
	draw         = state_noop_draw,
}

STATE_TABLE := [defs.State_Kind]State_Procs {
	.UnitMoving = {
		enter = unit_moving_enter,
		exit = unit_moving_exit,
		handle_input = unit_moving_handle_input,
		update = unit_moving_update,
		draw = unit_moving_draw,
	},
	.EndTurn = {
		enter = end_turn_enter,
		exit = end_turn_exit,
		handle_input = end_turn_handle_input,
		update = end_turn_update,
		draw = end_turn_draw,
	},
	.CalculateUnitMovementRange = {
		enter = calculate_unit_movement_range_enter,
		exit = calculate_unit_movement_range_exit,
		handle_input = calculate_unit_movement_range_handle_input,
		update = calculate_unit_movement_range_update,
		draw = calculate_unit_movement_range_draw,
	},
	.CalculateWeaponAttackRange = {
		enter = calculate_weapon_attack_range_enter,
		exit = calculate_weapon_attack_range_exit,
		handle_input = calculate_weapon_attack_range_handle_input,
		update = calculate_weapon_attack_range_update,
		draw = calculate_weapon_attack_range_draw,
	},
	.PrepareMagicTargets = {
		enter = prepare_magic_targets_enter,
		exit = prepare_magic_targets_exit,
		handle_input = prepare_magic_targets_handle_input,
		update = prepare_magic_targets_update,
		draw = prepare_magic_targets_draw,
	},
	.BattleActionMenu = {
		enter = battle_action_menu_enter,
		exit = battle_action_menu_exit,
		handle_input = battle_action_menu_handle_input,
		update = battle_action_menu_update,
		draw = battle_action_menu_draw,
	},
	.BattleItemMenu = {
		enter = battle_item_menu_enter,
		exit = battle_item_menu_exit,
		handle_input = battle_item_menu_handle_input,
		update = battle_item_menu_update,
		draw = battle_item_menu_draw,
	},
	.SelectingAction = STATE_NOOP,
	.SelectEnemyForPhysicalAttack = {
		enter = select_enemy_enter,
		exit = select_enemy_exit,
		handle_input = select_enemy_handle_input,
		update = select_enemy_update,
		draw = select_enemy_draw,
	},
	.TransitionSelectorToNextUnit = {
		enter = transition_selector_enter,
		exit = transition_selector_exit,
		handle_input = transition_selector_handle_input,
		update = transition_selector_update,
		draw = transition_selector_draw,
	},
	.AnimateUnitDeaths = {
		enter = animate_unit_deaths_enter,
		exit = animate_unit_deaths_exit,
		handle_input = animate_unit_deaths_handle_input,
		update = animate_unit_deaths_update,
		draw = animate_unit_deaths_draw,
	},
	.SelectMagic = {
		enter = select_magic_enter,
		exit = select_magic_exit,
		handle_input = select_magic_handle_input,
		update = select_magic_update,
		draw = select_magic_draw,
	},
	.SelectMagicLevel = {
		enter = select_magic_level_enter,
		exit = select_magic_level_exit,
		handle_input = select_magic_level_handle_input,
		update = select_magic_level_update,
		draw = select_magic_level_draw,
	},
	.MessageNotice = {
		enter = message_notice_enter,
		exit = message_notice_exit,
		handle_input = message_notice_handle_input,
		update = message_notice_update,
		draw = message_notice_draw,
	},
	.SelectMagicTargets = {
		enter = select_magic_targets_enter,
		exit = select_magic_targets_exit,
		handle_input = select_magic_targets_handle_input,
		update = select_magic_targets_update,
		draw = select_magic_targets_draw,
	},
	.BattleResolution = {
		enter = battle_resolution_enter,
		exit = battle_resolution_exit,
		handle_input = battle_resolution_handle_input,
		update = battle_resolution_update,
		draw = battle_resolution_draw,
	},
	.BattleResolutionDebug = {
		enter = battle_resolution_debug_enter,
		exit = battle_resolution_debug_exit,
		handle_input = battle_resolution_debug_handle_input,
		update = battle_resolution_debug_update,
		draw = battle_resolution_debug_draw,
	},
	.EnterBattleScreen = {
		enter = enter_battle_screen_enter,
		exit = enter_battle_screen_exit,
		handle_input = enter_battle_screen_handle_input,
		update = enter_battle_screen_update,
		draw = enter_battle_screen_draw,
	},
	.ExitBattleScreen = {
		enter = exit_battle_screen_enter,
		exit = exit_battle_screen_exit,
		handle_input = exit_battle_screen_handle_input,
		update = exit_battle_screen_update,
		draw = exit_battle_screen_draw,
	},
	.DropItem = {
		enter = drop_item_enter,
		exit = drop_item_exit,
		handle_input = drop_item_handle_input,
		update = drop_item_update,
		draw = drop_item_draw,
	},
	.PromptYesNo = {
		enter = prompt_yes_no_enter,
		exit = prompt_yes_no_exit,
		handle_input = prompt_yes_no_handle_input,
		update = prompt_yes_no_update,
		draw = prompt_yes_no_draw,
	},
	.EquipItem = {
		enter = equip_item_enter,
		exit = equip_item_exit,
		handle_input = equip_item_handle_input,
		update = equip_item_update,
		draw = equip_item_draw,
	},
	.UseWhichItem = {
		enter = use_which_item_enter,
		exit = use_which_item_exit,
		handle_input = use_which_item_handle_input,
		update = use_which_item_update,
		draw = use_which_item_draw,
	},
	.UseItemOnWhom = {
		enter = use_item_on_whom_enter,
		exit = use_item_on_whom_exit,
		handle_input = use_item_on_whom_handle_input,
		update = use_item_on_whom_update,
		draw = use_item_on_whom_draw,
	},
	.UseConsumableBattle = {
		enter = use_consumable_battle_enter,
		exit = use_consumable_battle_exit,
		handle_input = use_consumable_battle_handle_input,
		update = use_consumable_battle_update,
		draw = use_consumable_battle_draw,
	},
	.GiveWhichItem = {
		enter = give_which_item_enter,
		exit = give_which_item_exit,
		handle_input = give_which_item_handle_input,
		update = give_which_item_update,
		draw = give_which_item_draw,
	},
	.GiveItemToWhom = {
		enter = give_item_to_whom_enter,
		exit = give_item_to_whom_exit,
		handle_input = give_item_to_whom_handle_input,
		update = give_item_to_whom_update,
		draw = give_item_to_whom_draw,
	},
	.TradeWhichItemFromAdjacentNeighbor = {
		enter = trade_which_item_enter,
		exit = trade_which_item_exit,
		handle_input = trade_which_item_handle_input,
		update = trade_which_item_update,
		draw = trade_which_item_draw,
	},
}

state_draw_map :: proc(game: ^game_pkg.Game, scale: f32, draw_range, draw_highlight: bool) {
	debug_draw := game.renderer.debug_draw
	sprites.renderer_draw_background(scale, &game.grid, 255, debug_draw)
	if draw_range {
		sprites.renderer_draw_range(scale, &game.grid, debug_draw)
	}

	sprites.renderer_draw_units(
		scale,
		game.units[:],
		game.overworld_idle_flip_flop.is_on,
		255,
		debug_draw,
	)
	if draw_highlight {
		sprites.renderer_draw_highlight_rectangle(scale, game.highlight.current_position)
	}
}

state_change :: proc(game: ^game_pkg.Game, kind: defs.State_Kind) {
	if game == nil {
		log.errorf("state_change: game is nil.")
		return
	}

	log.infof("ChangeGameState() updating game state from [%v] to [%v].", game.state, kind)
	state_exit(game)
	game.state = kind
	state_enter(game)
}

state_show_message_notice :: proc(
	game: ^game_pkg.Game,
	message: string,
	return_state: defs.State_Kind,
) {
	if game == nil {
		log.errorf("state_show_message_notice: game is nil.")
		return
	}

	game_pkg.message_notice_set(&game.contexts.message_notice, message, return_state)
	state_change(game, .MessageNotice)
}

state_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.errorf("state_enter: game is nil.")
		return
	}

	STATE_TABLE[game.state].enter(game)
}

state_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.errorf("state_exit: game is nil.")
		return
	}

	STATE_TABLE[game.state].exit(game)
}

state_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.errorf("state_handle_input: game is nil.")
		return
	}

	STATE_TABLE[game.state].handle_input(game)
}

state_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.errorf("state_update: game is nil.")
		return
	}

	STATE_TABLE[game.state].update(game)
}

state_draw :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.errorf("state_draw: game is nil.")
		return
	}

	STATE_TABLE[game.state].draw(game, game.window.scale)
}
