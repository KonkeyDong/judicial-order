package timers

import "core:testing"
import rl "vendor:raylib"

test_levels := [4]rl.Color {
	{255, 255, 255, 255},
	{200, 220, 255, 200},
	{140, 180, 255, 180},
	{80, 120, 255, 160},
}

@(test)
test_oscillator_steps_after_delay :: proc(test: ^testing.T) {
	oscillator: Oscillator(rl.Color)
	oscillator_init(&oscillator, test_levels[:], 6)
	testing.expect_value(test, oscillator_value(oscillator), test_levels[0])
	for _ in 0 ..< 6 {
		oscillator_tick(&oscillator)
	}

	testing.expect_value(test, oscillator_value(oscillator), test_levels[1])
}

@(test)
test_oscillator_reverses_at_end :: proc(test: ^testing.T) {
	oscillator: Oscillator(rl.Color)
	oscillator_init(&oscillator, test_levels[:], 1)
	for _ in 0 ..< 3 {
		oscillator_tick(&oscillator)
	}

	testing.expect_value(test, oscillator.current_index, 3)
	testing.expect_value(test, oscillator.direction, -1)
	oscillator_tick(&oscillator)
	testing.expect_value(test, oscillator.current_index, 2)
}

@(test)
test_oscillator_reset :: proc(test: ^testing.T) {
	oscillator: Oscillator(rl.Color)
	oscillator_init(&oscillator, test_levels[:], 6)
	for _ in 0 ..< 6 {
		oscillator_tick(&oscillator)
	}

	oscillator_reset(&oscillator)
	testing.expect_value(test, oscillator_value(oscillator), test_levels[0])
	testing.expect_value(test, oscillator.direction, 1)
	testing.expect_value(test, oscillator.current_index, 0)
}

@(test)
test_oscillator_empty_levels :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	oscillator: Oscillator(rl.Color)
	empty: []rl.Color
	oscillator_init(&oscillator, empty, 6)
	oscillator_tick(&oscillator)
	testing.expect_value(test, oscillator_value(oscillator), rl.Color{})
}
