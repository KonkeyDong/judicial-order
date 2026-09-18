package game

import "core:log"

import rl "vendor:raylib"

Input_Query :: #type proc(key: rl.KeyboardKey) -> bool

@(thread_local)
input_pressed_override: Input_Query

@(thread_local)
input_down_override: Input_Query

input_set_pressed :: proc(query: Input_Query) {
	input_pressed_override = query
}

input_set_down :: proc(query: Input_Query) {
	input_down_override = query
}

input_key_pressed :: proc(key: rl.KeyboardKey) -> bool {
	if input_pressed_override != nil {
		return input_pressed_override(key)
	}

	if !rl.IsWindowReady() {
		return false
	}

	return rl.IsKeyPressed(key)
}

input_key_down :: proc(key: rl.KeyboardKey) -> bool {
	if input_down_override != nil {
		return input_down_override(key)
	}

	if !rl.IsWindowReady() {
		return false
	}

	return rl.IsKeyDown(key)
}

input_confirm_press :: proc() -> bool {
	return input_key_pressed(.Z) || input_key_pressed(.C)
}

input_cancel_press :: proc() -> bool {
	return input_key_pressed(.X)
}

input_dismiss_press :: proc() -> bool {
	return input_confirm_press() || input_cancel_press()
}

input_try_cycle_index :: proc(index: ^int, count: int) -> bool {
	if index == nil {
		log.errorf("input_try_cycle_index: index is nil.")
		return false
	}

	if count <= 1 {
		return false
	}

	if input_key_pressed(.LEFT) {
		index^ = (index^ + 1) % count
		return true
	}

	if input_key_pressed(.RIGHT) {
		index^ = (index^ - 1 + count) % count
		return true
	}

	return false
}
