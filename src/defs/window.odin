package defs

import "core:math"
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
		width = i32(f32(WINDOW.width) * clamped),
		height = i32(f32(WINDOW.height) * clamped),
	}
}
