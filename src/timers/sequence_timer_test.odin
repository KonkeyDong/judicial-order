package timers

import "core:testing"

@(test)
test_sequence_timer_plays_then_completes :: proc(test: ^testing.T) {
	timer: Sequence_Timer
	sequence_timer_init(&timer, 2, 2, 1)
	testing.expect_value(test, sequence_timer_total_duration_frames(timer), 5)
	testing.expect(test, !sequence_timer_has_started(timer))
	sequence_timer_tick(&timer)
	testing.expect(test, sequence_timer_is_playing(timer))
	testing.expect_value(test, timer.current_index, 0)
	sequence_timer_tick(&timer)
	testing.expect_value(test, timer.current_index, 0)
	sequence_timer_tick(&timer)
	testing.expect_value(test, timer.current_index, 1)
	testing.expect(test, sequence_timer_is_playing(timer))
	sequence_timer_tick(&timer)
	sequence_timer_tick(&timer)
	testing.expect(test, timer.is_complete)
	testing.expect(test, !sequence_timer_is_playing(timer))
	testing.expect_value(test, timer.current_index, 1)
}

@(test)
test_sequence_timer_seek_and_reset_timer_only :: proc(test: ^testing.T) {
	timer: Sequence_Timer
	sequence_timer_init(&timer, 2, 1)
	sequence_timer_seek(&timer, 2)
	testing.expect(test, timer.is_complete)
	testing.expect_value(test, timer.current_index, 1)
	sequence_timer_reset_timer_only(&timer)
	testing.expect(test, !timer.is_complete)
	testing.expect_value(test, timer.current_index, 1)
	sequence_timer_reset(&timer)
	testing.expect_value(test, timer.current_index, 0)
	testing.expect(test, sequence_timer_is_playing(timer))
}
