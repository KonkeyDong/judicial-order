package timers

import "core:log"

Sequence_Timer :: struct {
	frame_count:                  int,
	frames_per_step:              int,
	original_start_delay_frames:  int,
	start_delay_frames_remaining: int,
	current_tick:                 int,
	current_index:                int,
	is_complete:                  bool,
}

sequence_timer_init :: proc(
	timer: ^Sequence_Timer,
	frame_count: int,
	frames_per_step: int,
	start_delay_frames := 0,
) {
	if frame_count <= 0 {
		log.errorf("SequenceTimer: frameCount must be greater than zero.")
	}

	if frames_per_step <= 0 {
		log.errorf("SequenceTimer: framesPerStep must be greater than zero.")
	}

	if start_delay_frames < 0 {
		log.errorf("SequenceTimer: startDelayFrames cannot be less than zero.")
	}

	timer.frame_count = frame_count
	timer.frames_per_step = frames_per_step
	timer.original_start_delay_frames = max(start_delay_frames, 0)
	sequence_timer_reset(timer)
}

sequence_timer_has_started :: proc(timer: Sequence_Timer) -> bool {
	return timer.start_delay_frames_remaining <= 0
}

sequence_timer_is_playing :: proc(timer: Sequence_Timer) -> bool {
	return sequence_timer_has_started(timer) && !timer.is_complete
}

sequence_timer_total_duration_frames :: proc(timer: Sequence_Timer) -> int {
	return timer.original_start_delay_frames + timer.frame_count * timer.frames_per_step
}

sequence_timer_tick :: proc(timer: ^Sequence_Timer) {
	if timer.is_complete || timer.frame_count <= 0 || timer.frames_per_step <= 0 {
		return
	}

	if timer.start_delay_frames_remaining > 0 {
		timer.start_delay_frames_remaining -= 1
		return
	}

	timer.current_tick += 1
	if timer.current_tick < timer.frames_per_step {
		return
	}

	timer.current_tick = 0
	timer.current_index += 1
	if timer.current_index >= timer.frame_count {
		timer.is_complete = true
		timer.current_index = timer.frame_count - 1
	}
}

sequence_timer_reset :: proc(timer: ^Sequence_Timer) {
	timer.current_tick = 0
	timer.current_index = 0
	timer.start_delay_frames_remaining = timer.original_start_delay_frames
	timer.is_complete = false
}

sequence_timer_reset_timer_only :: proc(timer: ^Sequence_Timer) {
	timer.current_tick = 0
	timer.start_delay_frames_remaining = timer.original_start_delay_frames
	timer.is_complete = false
}

sequence_timer_seek :: proc(timer: ^Sequence_Timer, absolute_frame: int) {
	sequence_timer_reset(timer)
	frames := max(absolute_frame, 0)
	for _ in 0 ..< frames {
		sequence_timer_tick(timer)
	}
}
