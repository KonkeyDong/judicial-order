package game

import "core:testing"

import rl "vendor:raylib"

INPUT_TEST_KEY_CAP :: 8

@(thread_local)
input_test_pressed_buf: [INPUT_TEST_KEY_CAP]rl.KeyboardKey
@(thread_local)
input_test_pressed_count: int
@(thread_local)
input_test_down_buf: [INPUT_TEST_KEY_CAP]rl.KeyboardKey
@(thread_local)
input_test_down_count: int

input_test_pressed_query :: proc(key: rl.KeyboardKey) -> bool {
	for i in 0 ..< input_test_pressed_count {
		if input_test_pressed_buf[i] == key {
			return true
		}
	}

	return false
}

input_test_down_query :: proc(key: rl.KeyboardKey) -> bool {
	for i in 0 ..< input_test_down_count {
		if input_test_down_buf[i] == key {
			return true
		}
	}

	return false
}

input_test_install_pressed :: proc(keys: []rl.KeyboardKey) {
	count := len(keys)
	if count > INPUT_TEST_KEY_CAP {
		count = INPUT_TEST_KEY_CAP
	}

	for i in 0 ..< count {
		input_test_pressed_buf[i] = keys[i]
	}

	input_test_pressed_count = count
	input_set_pressed(input_test_pressed_query)
}

input_test_install_down :: proc(keys: []rl.KeyboardKey) {
	count := len(keys)
	if count > INPUT_TEST_KEY_CAP {
		count = INPUT_TEST_KEY_CAP
	}

	for i in 0 ..< count {
		input_test_down_buf[i] = keys[i]
	}

	input_test_down_count = count
	input_set_down(input_test_down_query)
}

@(test)
test_cycle_count_le_1 :: proc(test: ^testing.T) {
	defer input_set_pressed(nil)

	index := 0
	input_test_install_pressed({.LEFT})
	testing.expect_value(test, input_try_cycle_index(&index, 0), false)
	testing.expect_value(test, index, 0)
	testing.expect_value(test, input_try_cycle_index(&index, 1), false)
	testing.expect_value(test, index, 0)
}

@(test)
test_cycle_left_wraps :: proc(test: ^testing.T) {
	defer input_set_pressed(nil)

	index := 2
	input_test_install_pressed({.LEFT})
	testing.expect(test, input_try_cycle_index(&index, 3))
	testing.expect_value(test, index, 0)
}

@(test)
test_cycle_right_wraps :: proc(test: ^testing.T) {
	defer input_set_pressed(nil)

	index := 0
	input_test_install_pressed({.RIGHT})
	testing.expect(test, input_try_cycle_index(&index, 3))
	testing.expect_value(test, index, 2)
}

@(test)
test_cycle_no_arrow_unchanged :: proc(test: ^testing.T) {
	defer input_set_pressed(nil)

	index := 1
	input_test_install_pressed({.Z})
	testing.expect_value(test, input_try_cycle_index(&index, 3), false)
	testing.expect_value(test, index, 1)
}

@(test)
test_cycle_nil_index :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	testing.expect_value(test, input_try_cycle_index(nil, 3), false)
}

@(test)
test_confirm_cancel_dismiss :: proc(test: ^testing.T) {
	defer input_set_pressed(nil)

	input_test_install_pressed({.Z})
	testing.expect(test, input_confirm_press())
	testing.expect(test, !input_cancel_press())
	testing.expect(test, input_dismiss_press())

	input_test_install_pressed({.C})
	testing.expect(test, input_confirm_press())

	input_test_install_pressed({.X})
	testing.expect(test, input_cancel_press())
	testing.expect(test, !input_confirm_press())
	testing.expect(test, input_dismiss_press())
}
