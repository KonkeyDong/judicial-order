package game

import rl "vendor:raylib"

input_confirm_press :: proc() -> bool {
	return rl.IsKeyPressed(.Z) || rl.IsKeyPressed(.C)
}

input_cancel_press :: proc() -> bool {
	return rl.IsKeyPressed(.X)
}

input_dismiss_press :: proc() -> bool {
	return input_confirm_press() || input_cancel_press()
}
