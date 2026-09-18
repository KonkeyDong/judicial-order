package state

import game_pkg "../game"

import "../timers"
import rl "vendor:raylib"

select_enemy_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	game_pkg.grid_calculate_weapon_attack_range(&game.grid, current)
	if len(game.unfriendly_units_in_range) > 0 {
		game_pkg.game_initialize_highlight(game)
		game.state_scratch.list_index = 0
		game_pkg.game_set_highlight_target(game, game.unfriendly_units_in_range[0])
	}
}

select_enemy_exit :: proc(_: ^game_pkg.Game) {}

select_enemy_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_try_cycle_index(
		&game.state_scratch.list_index,
		len(game.unfriendly_units_in_range),
	) {
		target := game.unfriendly_units_in_range[game.state_scratch.list_index]
		if target != nil && target.on_map {
			game_pkg.game_set_highlight_target(game, target)
		}
	}

	if game_pkg.input_confirm_press() {
		select_enemy_confirm(game)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleActionMenu)
	}
}

select_enemy_confirm :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil || len(game.unfriendly_units_in_range) == 0 {
		return
	}

	index := game.state_scratch.list_index
	if index < 0 || index >= len(game.unfriendly_units_in_range) {
		return
	}

	game.battle_screen_mode = .Combat
	game_pkg.attack_context_init(
		&game.attack_context,
		current,
		game.unfriendly_units_in_range[index],
	)
	state_change(game, .EnterBattleScreen)
}

select_enemy_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)
	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

select_enemy_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, true)
}
