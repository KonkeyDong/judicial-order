package game

import "core:log"
import "core:math"

import "defs"
import rl "vendor:raylib"

WINDOW_SCALE_MIN :: 1.0
WINDOW_SCALE_MAX :: 5.0

Window_View :: struct {
	scale:         f32,
	width, height: i32,
}

window_scale_clamp :: proc(scale: f32) -> f32 {
	return math.clamp(scale, WINDOW_SCALE_MIN, WINDOW_SCALE_MAX)
}

window_view_from_scale :: proc(scale: f32) -> Window_View {
	clamped := window_scale_clamp(scale)
	return Window_View {
		scale = clamped,
		width = i32(f32(defs.WINDOW.width) * clamped),
		height = i32(f32(defs.WINDOW.height) * clamped),
	}
}

window_apply_scale :: proc(game: ^Game, scale: f32, apply_os_window := true) {
	if game == nil {
		log.errorf("window_apply_scale: game is nil.")
		return
	}

	game.window = window_view_from_scale(scale)
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
