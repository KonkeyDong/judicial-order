package game

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(500, 500, "Judicial Order")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
		rl.ClearBackground({18, 16, 22, 255})
		rl.DrawText("Hello", 40, 40, 32, rl.RAYWHITE)
		rl.EndDrawing()
    }

    rl.CloseWindow()
}