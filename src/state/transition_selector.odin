package state

import game_pkg "../game"

import "../sprites"

import "../timers"
import rl "vendor:raylib"

transition_selector_enter :: proc(game: ^game_pkg.Game) {
	game_pkg.game_initialize_highlight(game)
	game_pkg.game_set_highlight_target(game, game_pkg.game_next_unit(game))
}

transition_selector_exit :: proc(game: ^game_pkg.Game) {
}

transition_selector_handle_input :: proc(game: ^game_pkg.Game) {
}

transition_selector_update :: proc(game: ^game_pkg.Game) {
	if game.highlight.animation_complete {
		state_change(game, .EndTurn)
	}

	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

transition_selector_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	debug_draw := game.renderer.debug_draw
	game_pkg.renderer_draw_background(scale, &game.grid, 255, debug_draw)
	game_pkg.renderer_draw_range(scale, &game.grid, debug_draw)
	sprites.renderer_draw_units(
		scale,
		game.units[:],
		game.overworld_idle_flip_flop.is_on,
		255,
		debug_draw,
	)
	sprites.renderer_draw_highlight_rectangle(scale, game.highlight.current_position)
}
