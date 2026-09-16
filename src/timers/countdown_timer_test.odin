package timers

import "core:testing"

@(test)
test_countdown_timer_expires :: proc(test: ^testing.T) {
	timer: Countdown_Timer
	countdown_timer_init(&timer, 3)
	testing.expect(test, timer.is_active)
	countdown_timer_tick(&timer)
	countdown_timer_tick(&timer)
	testing.expect(test, timer.is_active)
	countdown_timer_tick(&timer)
	testing.expect(test, !timer.is_active)
	testing.expect_value(test, timer.frame_counter, 0)
	countdown_timer_tick(&timer)
	testing.expect_value(test, timer.frame_counter, 0)
}

@(test)
test_countdown_timer_reset_and_stop :: proc(test: ^testing.T) {
	timer: Countdown_Timer
	countdown_timer_init(&timer, 2)
	countdown_timer_tick(&timer)
	countdown_timer_reset(&timer)
	testing.expect(test, timer.is_active)
	testing.expect_value(test, timer.frame_counter, 2)
	countdown_timer_stop(&timer)
	testing.expect(test, !timer.is_active)
	testing.expect_value(test, timer.frame_counter, 0)
	countdown_timer_start(&timer)
	testing.expect(test, timer.is_active)
	testing.expect_value(test, timer.frame_counter, 0)
}
