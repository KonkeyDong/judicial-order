package game

import "defs"

calculate_weapon_attack_range_enter :: proc(game: ^Game) {
	current := game_current_unit(game)
	if current == nil {
		return
	}

	grid_calculate_weapon_attack_range(&game.grid, current)
	units := grid_units_in_range(&game.grid)
	defer delete(units)
	game_separate_units_in_range(game, current, units)
	if len(game.unfriendly_units_in_range) > 0 {
		state_change(game, .SelectEnemyForPhysicalAttack)
	} else {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .BattleActionMenu)
	}
}

calculate_weapon_attack_range_exit :: proc(_: ^Game) {}
calculate_weapon_attack_range_handle_input :: proc(_: ^Game) {}
calculate_weapon_attack_range_update :: proc(_: ^Game) {}
calculate_weapon_attack_range_draw :: proc(_: ^Game, _: f32) {}
