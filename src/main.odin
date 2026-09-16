package game

import "core:log"

import "catalog"
import "data"
import "defs"
import "sprites"
import rl "vendor:raylib"

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	rl.InitWindow(defs.WINDOW.width, defs.WINDOW.height, "Judicial Order")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	sprites.init()
	defer sprites.destroy()
	catalog.init()
	data.init()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({18, 16, 22, 255})
		rl.DrawText("Hello", 40, 40, 32, rl.RAYWHITE)
		rl.EndDrawing()
	}
}
