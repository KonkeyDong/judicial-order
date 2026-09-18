package game

import "core:strings"

import "../defs"
import "../sprites"
import "../timers"
import rl "vendor:raylib"

// Map draws stay in package game so sprites does not import Grid.
renderer_draw_background :: proc(scale: f32, grid: ^Grid, alpha := 255, debug_draw := false) {
	tint := rl.Color{255, 255, 255, sprites.renderer_alpha_u8(alpha)}
	for x in 0 ..< grid.width {
		for y in 0 ..< grid.height {
			block := grid_block_at(grid, x, y)
			position := rl.Vector2{f32(x * grid.block_size), f32(y * grid.block_size)}
			rl.DrawTextureEx(block.texture, position, defs.TEXTURES.base_rotation, scale, tint)
			if debug_draw {
				rl.DrawText(
					strings.clone_to_cstring(block_print_coords(block), context.temp_allocator),
					i32(position.x),
					i32(position.y) + 20,
					16,
					rl.WHITE,
				)
			}
		}
	}

	if debug_draw {
		grid_color := rl.Color{200, 50, 50, 255}
		line_thickness := 1.0 * scale
		for x in 0 ..= grid.width {
			x_pos := f32(x * grid.block_size)
			rl.DrawLineEx(
				{x_pos, 0},
				{x_pos, f32(grid.height * grid.block_size)},
				line_thickness,
				grid_color,
			)
		}

		for y in 0 ..= grid.height {
			y_pos := f32(y * grid.block_size)
			rl.DrawLineEx(
				{0, y_pos},
				{f32(grid.width * grid.block_size), y_pos},
				line_thickness,
				grid_color,
			)
		}
	}
}

renderer_draw_range :: proc(scale: f32, grid: ^Grid, debug_draw := false) {
	tint := timers.oscillator_value(grid.range_tint)
	for coord in grid.range_coords {
		block := grid_block_at(grid, coord.x, coord.y)
		position := rl.Vector2{f32(coord.x * grid.block_size), f32(coord.y * grid.block_size)}
		rl.DrawTextureEx(block.texture, position, defs.TEXTURES.base_rotation, scale, tint)
		if debug_draw {
			rl.DrawText(
				strings.clone_to_cstring(block_print_coords(block), context.temp_allocator),
				i32(position.x),
				i32(position.y) + 20,
				16,
				rl.WHITE,
			)
		}
	}
}
