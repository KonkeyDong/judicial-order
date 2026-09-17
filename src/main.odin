package game

import "core:log"
import "core:mem"

import "catalog"
import "data"
import "defs"
import "sprites"
import "timers"
import unit_pkg "unit"
import rl "vendor:raylib"

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	w := i32(f32(defs.WINDOW.width) * defs.WINDOW.scale)
	h := i32(f32(defs.WINDOW.height) * defs.WINDOW.scale)
	rl.InitWindow(w, h, "Judicial Order") // 768x672. 11x10 stub dest 792x720 still clips — same as C#, not a bug.
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	sprites.init()
	defer sprites.destroy()
	catalog.init()
	data.init()
	sprites.item_icons_load() // AFTER InitWindow (GL). Placeholder path when PNGs missing.
	sprites.magic_icons_load()

	game: Game
	game_init(&game, GAME_STUB_WIDTH, GAME_STUB_HEIGHT)
	defer game_destroy(&game)

	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	game_add_unit(&game, hale, 3, 1)
	game_add_unit(&game, judy, 3, 2)
	grid_calculate_unit_movement_range(&game.grid, hale)
	game_initialize_highlight(&game)

	for !rl.WindowShouldClose() {
		if rl.IsKeyPressed(.F1) {
			game.renderer.debug_draw = !game.renderer.debug_draw
		}

		timers.flip_flop_tick(&game.flip_flop)
		timers.oscillator_tick(&game.grid.range_tint)
		sprites.item_icons_tick()
		sprites.magic_icons_tick()

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		scale := defs.WINDOW.scale
		renderer_draw_background(scale, &game.grid, 255, game.renderer.debug_draw)
		renderer_draw_range(scale, &game.grid, game.renderer.debug_draw)
		renderer_draw_units(scale, game.units[:], game.flip_flop.is_on, 255, game.renderer.debug_draw)
		renderer_draw_highlight_rectangle(scale, game.highlight_current_position)
		rl.EndDrawing()

		mem.free_all(context.temp_allocator)
	}
}
