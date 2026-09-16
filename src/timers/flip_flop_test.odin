package timers

import "core:testing"

@(test)
test_flip_flop_toggles_after_period :: proc(test: ^testing.T) {
	flip_flop: Flip_Flop
	flip_flop_init(&flip_flop, 2)
	testing.expect(test, !flip_flop.is_on)
	testing.expect_value(test, flip_flop.counter, 0)

	flip_flop_tick(&flip_flop)
	testing.expect(test, !flip_flop.is_on)
	testing.expect_value(test, flip_flop.counter, 1)

	flip_flop_tick(&flip_flop)
	testing.expect(test, flip_flop.is_on)
	testing.expect_value(test, flip_flop.counter, 0)

	flip_flop_tick(&flip_flop)
	testing.expect(test, flip_flop.is_on)

	flip_flop_tick(&flip_flop)
	testing.expect(test, !flip_flop.is_on)
}

@(test)
test_flip_flop_reset :: proc(test: ^testing.T) {
	flip_flop: Flip_Flop
	flip_flop_init(&flip_flop, 2)
	flip_flop_tick(&flip_flop)
	flip_flop_tick(&flip_flop)
	testing.expect(test, flip_flop.is_on)

	flip_flop_reset(&flip_flop)

	testing.expect(test, !flip_flop.is_on)
	testing.expect_value(test, flip_flop.counter, 0)
}
