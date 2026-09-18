package state

import game_pkg "../game"

import "../defs"

calculate_weapon_attack_range_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	game_pkg.grid_calculate_weapon_attack_range(&game.grid, current)
	units := game_pkg.grid_units_in_range(&game.grid)
	defer delete(units)
	game_pkg.game_separate_units_in_range(game, current, units)
	if len(game.unfriendly_units_in_range) > 0 {
		state_change(game, .SelectEnemyForPhysicalAttack)
	} else {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .BattleActionMenu)
	}
}

calculate_weapon_attack_range_exit :: proc(_: ^game_pkg.Game) {}
calculate_weapon_attack_range_handle_input :: proc(_: ^game_pkg.Game) {}
calculate_weapon_attack_range_update :: proc(_: ^game_pkg.Game) {}
calculate_weapon_attack_range_draw :: proc(_: ^game_pkg.Game, _: f32) {}
