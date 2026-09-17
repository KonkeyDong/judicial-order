package game

import "core:fmt"
import "core:log"
import "core:strings"

import "defs"
import "sprites"
import "timers"
import unit_pkg "unit"
import rl "vendor:raylib"

Renderer :: struct {
	debug_draw: bool,
}

renderer_init :: proc(renderer: ^Renderer) {
	renderer.debug_draw = false
}

renderer_destroy :: proc(renderer: ^Renderer) {
	renderer.debug_draw = false
}

// C# passes `alpha` straight into Color (byte wrap). Clamp 0..255 is a labeled delta.
// Shared so background and sprite draws cannot drift.
renderer_alpha_u8 :: proc(alpha: int) -> u8 {
	if alpha < 0 {
		return 0
	}

	if alpha > 255 {
		return 255
	}

	return u8(alpha)
}

renderer_draw :: proc(
	scale: f32,
	sprite: sprites.Sprite,
	position: rl.Vector2,
	alpha := 255,
	debug_draw := false,
) {
	// House-rule / robustness delta vs C# (null sprite NRE): skip unloaded walk / missing icons.
	if sprite.texture.id == 0 {
		return
	}

	source := rl.Rectangle {
		f32(sprite.frame.x),
		f32(sprite.frame.y),
		f32(sprite.frame.w),
		f32(sprite.frame.h),
	}
	dest := rl.Rectangle {
		f32(i32((position.x + f32(sprite.frame.offset_x)) * scale)),
		f32(i32((position.y + f32(sprite.frame.offset_y)) * scale)),
		f32(sprite.frame.w) * scale,
		f32(sprite.frame.h) * scale,
	}
	tint := rl.Color{255, 255, 255, renderer_alpha_u8(alpha)}
	rl.DrawTexturePro(
		sprite.texture,
		source,
		dest,
		defs.TEXTURES.base_origin,
		defs.TEXTURES.base_rotation,
		tint,
	)

	if debug_draw {
		rl.DrawRectangleLinesEx(dest, f32(defs.DEBUG.spacing), defs.DEBUG.color)
		debug_text := fmt.tprintf(
			"X: %v, Y: %v",
			position.x + f32(sprite.frame.offset_x),
			position.y + f32(sprite.frame.offset_y),
		)
		rl.DrawTextEx(
			rl.GetFontDefault(),
			strings.clone_to_cstring(debug_text, context.temp_allocator),
			{dest.x, dest.y - 15},
			f32(defs.DEBUG.font_size),
			f32(defs.DEBUG.spacing),
			defs.DEBUG.color,
		)
	}
}

renderer_draw_background :: proc(scale: f32, grid: ^Grid, alpha := 255, debug_draw := false) {
	tint := rl.Color{255, 255, 255, renderer_alpha_u8(alpha)}
	for x in 0 ..< grid.width {
		for y in 0 ..< grid.height {
			block := grid_block_at(grid, x, y)
			position := rl.Vector2{f32(x * grid.block_size), f32(y * grid.block_size)}
			rl.DrawTextureEx(block.texture, position, defs.TEXTURES.base_rotation, scale, tint)
			if debug_draw {
				// C# hardcoded 16 and White — not DEBUG.color (yellow) / DEBUG.font_size.
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

renderer_draw_highlight_rectangle :: proc(scale: f32, position: rl.Vector2) {
	tile_size := f32(defs.TILE_SIZE) * scale
	rect := rl.Rectangle {
		position.x * f32(i32(scale)),
		position.y * f32(i32(scale)),
		tile_size,
		tile_size,
	}
	rl.DrawRectangleLinesEx(rect, scale, rl.WHITE)
}

renderer_draw_highlight_rectangles :: proc(scale: f32, positions: []rl.Vector2) {
	for position in positions {
		renderer_draw_highlight_rectangle(scale, position)
	}
}

renderer_draw_unit :: proc(
	scale: f32,
	unit: ^unit_pkg.Unit,
	frame_flipper_flag: bool,
	alpha := 255,
	debug_draw := false,
) {
	if unit == nil || !unit.on_map {
		name := "nil"
		if unit != nil {
			name = defs.name_display(unit.name)
		}

		log.errorf("Unit %s has no Block reference!", name)
		return
	}

	sprite := unit_pkg.walk_sprite(unit, frame_flipper_flag)
	renderer_draw(scale, sprite, unit.world_position, alpha, debug_draw)
}

renderer_draw_units :: proc(
	scale: f32,
	units: []^unit_pkg.Unit,
	frame_flipper_flag: bool,
	alpha := 255,
	debug_draw := false,
) {
	// Reverse so roster[0] (current unit / visitor) paints last = on top of occupant.
	// C#: for (i = Count-1; i >= 0; i--). Do not y-sort.
	#reverse for unit in units {
		renderer_draw_unit(scale, unit, frame_flipper_flag, alpha, debug_draw)
	}
}

renderer_draw_debug_logical_grid :: proc(
	scale: f32,
	logical_spacing: int,
	color: rl.Color,
	pixel_width: f32,
	pixel_height: f32,
) {
	if logical_spacing <= 0 {
		return
	}

	step := f32(logical_spacing) * scale
	line_thickness := scale
	if line_thickness < 1 {
		line_thickness = 1
	}

	for x := f32(0); x <= pixel_width; x += step {
		rl.DrawLineEx({x, 0}, {x, pixel_height}, line_thickness, color)
	}

	for y := f32(0); y <= pixel_height; y += step {
		rl.DrawLineEx({0, y}, {pixel_width, y}, line_thickness, color)
	}
}

renderer_ease_in_out :: proc(progress: f32) -> f32 {
	if progress < 0.5 {
		return 2 * progress * progress
	}

	remainder := -2 * progress + 2
	return 1 - (remainder * remainder) / 2
}

renderer_vector_lerp :: proc(start, finish: rl.Vector2, amount: f32) -> rl.Vector2 {
	t := clamp(amount, 0, 1)
	return start + (finish - start) * t
}

renderer_draw_battle_ground :: proc(scale: f32, alpha: int) {
	pos := defs.BATTLE.positions.foreground
	rect := rl.Rectangle {
		pos.x * scale,
		pos.y * scale,
		f32(defs.WINDOW.width) * scale,
		f32(defs.TILE_SIZE) * scale,
	}
	color := defs.TEXTURES.dark_orange
	color.a = renderer_alpha_u8(alpha)
	rl.DrawRectangleRec(rect, color)
}

renderer_draw_battle_standin :: proc(
	scale: f32,
	unit: ^unit_pkg.Unit,
	position: rl.Vector2,
	alpha := 255,
	jitter := 0,
) {
	if unit == nil {
		return
	}

	draw_pos := position
	draw_pos.x += f32(jitter)
	size := f32(defs.TILE_SIZE) * 1.5
	dest := rl.Rectangle{draw_pos.x * scale, draw_pos.y * scale, size * scale, size * scale}
	fill := defs.TEXTURES.blue if unit.friendly else defs.TEXTURES.dark_red
	fill.a = renderer_alpha_u8(alpha)
	rl.DrawRectangleRec(dest, fill)
	rl.DrawRectangleLinesEx(dest, max(1, scale), defs.TEXTURES.off_white)

	sprite := unit_pkg.facing_sprite(unit, unit.facing_direction)
	if sprite.texture.id != 0 {
		renderer_draw(scale, sprite, draw_pos, alpha, false)
	}

	label := defs.name_display(unit.name)
	font_size := f32(int(8 * scale))
	rl.DrawTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(label, context.temp_allocator),
		{dest.x, dest.y - font_size - 2},
		font_size,
		1,
		defs.TEXTURES.off_white,
	)
}
