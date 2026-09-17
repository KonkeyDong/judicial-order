package game

import "timers"
import rl "vendor:raylib"

transition_selector_enter :: proc(game: ^Game) {
	game_initialize_highlight(game)
	game_set_highlight_target(game, game_next_unit(game))
}

transition_selector_exit :: proc(game: ^Game) {
}

transition_selector_handle_input :: proc(game: ^Game) {
}

transition_selector_update :: proc(game: ^Game) {
	if game.highlight_animation_complete {
		state_change(game, .EndTurn)
	}

	timers.flip_flop_tick(&game.flip_flop)
	game_update_highlight(game, rl.GetFrameTime())
}

transition_selector_draw :: proc(game: ^Game, scale: f32) {
	debug_draw := game.renderer.debug_draw
	renderer_draw_background(scale, &game.grid, 255, debug_draw)
	renderer_draw_range(scale, &game.grid, debug_draw)
	renderer_draw_units(scale, game.units[:], game.flip_flop.is_on, 255, debug_draw)
	renderer_draw_highlight_rectangle(scale, game.highlight_current_position)
}
