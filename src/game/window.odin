package game

import "core:log"

import "../defs"
import rl "vendor:raylib"

window_apply_scale :: proc(game: ^Game, scale: f32, apply_os_window := true) {
	if game == nil {
		log.errorf("window_apply_scale: game is nil.")
		return
	}

	game.window = defs.window_view_from_scale(scale)
	game.grid.block_size = int(f32(defs.TILE_SIZE) * game.window.scale)

	if apply_os_window && rl.IsWindowReady() {
		rl.SetWindowSize(game.window.width, game.window.height)
	}

	log.infof(
		"ResizeWindow() Window resized to %d x %d (Scale: %.2fx); BlockSize: %d",
		game.window.width,
		game.window.height,
		game.window.scale,
		game.grid.block_size,
	)
}

window_handle_resize_input :: proc(game: ^Game, apply_os_window := true) {
	if game == nil {
		log.errorf("window_handle_resize_input: game is nil.")
		return
	}

	ctrl_down := input_key_down(.LEFT_CONTROL) || input_key_down(.RIGHT_CONTROL)
	if !ctrl_down {
		return
	}

	if input_key_pressed(.EQUAL) {
		window_apply_scale(game, game.window.scale + 1.0, apply_os_window)
	}

	if input_key_pressed(.MINUS) {
		next := max(0.5, game.window.scale - 1.0)
		window_apply_scale(game, next, apply_os_window)
	}
}
