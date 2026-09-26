package sprites

import "core:fmt"
import "core:log"
import "core:strings"

import "../defs"
import grid_pkg "../grid"
import "../timers"
import rl "vendor:raylib"

MAP_DEBUG_GRID_COLOR :: rl.Color{200, 50, 50, 255}

renderer_draw_background :: proc(
	scale: f32,
	grid: ^grid_pkg.Grid,
	alpha := 255,
	debug_draw := false,
) {
	tint := rl.Color{255, 255, 255, renderer_alpha_u8(alpha)}
	for x in 0 ..< grid.width {
		for y in 0 ..< grid.height {
			renderer_draw_block(scale, grid, &grid.blocks[x * grid.height + y], tint, debug_draw)
		}
	}

	if debug_draw {
		renderer_draw_map_lines(
			scale,
			grid.width,
			grid.height,
			grid.block_size,
			MAP_DEBUG_GRID_COLOR,
		)
	}
}

renderer_draw_range :: proc(scale: f32, grid: ^grid_pkg.Grid, debug_draw := false) {
	tint := timers.oscillator_value(grid.range_tint)
	for coord in grid.range_coords {
		if coord.x < 0 || coord.x >= grid.width || coord.y < 0 || coord.y >= grid.height {
			log.errorf("renderer_draw_range: (%d, %d) out of bounds.", coord.x, coord.y)
			continue
		}

		renderer_draw_block(
			scale,
			grid,
			&grid.blocks[coord.x * grid.height + coord.y],
			tint,
			debug_draw,
		)
	}
}

renderer_draw_block :: proc(
	scale: f32,
	grid: ^grid_pkg.Grid,
	block: ^grid_pkg.Block,
	tint: rl.Color,
	debug_draw: bool,
) {
	position := rl.Vector2 {
		f32(block.grid_x * grid.block_size),
		f32(block.grid_y * grid.block_size),
	}
	renderer_draw_texture(block.texture, position, scale, tint)
	if debug_draw {
		renderer_draw_text(
			fmt.tprintf("[%d, %d]", block.grid_x, block.grid_y),
			{position.x, position.y + 20},
			16,
			rl.WHITE,
		)
	}
}

renderer_draw_texture :: proc(
	texture: rl.Texture2D,
	position: rl.Vector2,
	scale: f32,
	tint: rl.Color,
) {
	if texture.id == 0 {
		return
	}

	rl.DrawTextureEx(texture, position, defs.TEXTURES.base_rotation, scale, tint)
}

renderer_draw_text :: proc(text: string, position: rl.Vector2, font_size: int, color: rl.Color) {
	rl.DrawText(
		strings.clone_to_cstring(text, context.temp_allocator),
		i32(position.x),
		i32(position.y),
		i32(font_size),
		color,
	)
}

renderer_draw_map_lines :: proc(scale: f32, columns, rows, block_size: int, color: rl.Color) {
	line_thickness := 1.0 * scale

	width := f32(columns * block_size)
	height := f32(rows * block_size)
	for x in 0 ..= columns {
		x_pos := f32(x * block_size)
		rl.DrawLineEx({x_pos, 0}, {x_pos, height}, line_thickness, color)
	}

	for y in 0 ..= rows {
		y_pos := f32(y * block_size)
		rl.DrawLineEx({0, y_pos}, {width, y_pos}, line_thickness, color)
	}
}
