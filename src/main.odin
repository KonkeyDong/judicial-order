package main

import "core:log"
import "core:mem"
import "core:os"

import "defs"
import "game"
import "sprites"
import "state"
import unit_pkg "unit"
import rl "vendor:raylib"

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	options, parsed := program_parse_args(os.args)
	if !parsed {
		return
	}

	program_set_log_level(options.log_level)
	log.infof("Logger level set to: %v", program_log_level_get())

	view := defs.window_view_from_scale(defs.WINDOW.scale)
	rl.InitWindow(view.width, view.height, "Judicial Order") // 768x672. 11x10 stub dest 792x720 still clips — same as C#, not a bug.
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	program_init_databases()
	program_load_graphics()
	defer sprites.destroy()

	session: game.Game
	game.game_init(&session, game.GAME_STUB_WIDTH, game.GAME_STUB_HEIGHT)
	defer game.game_destroy(&session)
	program_apply_debug_draw(&session)

	hale, judy, bellweather := program_add_test_units(&session)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer unit_pkg.destroy(bellweather)
	state.state_enter(&session)

	for !rl.WindowShouldClose() {
		program_handle_global_input(&session)
		context.logger.lowest_level = program_log_level_get()
		program_update(&session)
		program_draw(&session)
		mem.free_all(context.temp_allocator)
	}
}
