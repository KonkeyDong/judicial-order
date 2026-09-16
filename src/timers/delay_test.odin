package timers

import "core:testing"

@(test)
test_delay_advances_index :: proc(test: ^testing.T) {
	delay: Delay
	delay_init(&delay, 2)
	delay_tick(&delay)
	testing.expect_value(test, delay.current_index, 0)
	delay_tick(&delay)
	testing.expect_value(test, delay.current_index, 1)
	delay_tick(&delay)
	testing.expect_value(test, delay.current_index, 1)
	delay_tick(&delay)
	testing.expect_value(test, delay.current_index, 2)
}

@(test)
test_delay_start_delay_then_reset_timer_only :: proc(test: ^testing.T) {
	delay: Delay
	delay_init(&delay, 1, 2)
	delay_tick(&delay)
	delay_tick(&delay)
	testing.expect_value(test, delay.current_index, 0)
	delay_tick(&delay)
	testing.expect_value(test, delay.current_index, 1)
	delay_reset_timer_only(&delay)
	testing.expect_value(test, delay.current_index, 1)
	testing.expect_value(test, delay.start_delay_frames, 2)
	delay_reset(&delay)
	testing.expect_value(test, delay.current_index, 0)
	testing.expect_value(test, delay.start_delay_frames, 2)
}
