package timers

import "core:log"

Delay :: struct {
	tick_delay:                  int,
	original_start_delay_frames: int,
	start_delay_frames:          int,
	current_tick:                int,
	current_index:               int,
}

delay_init :: proc(delay: ^Delay, tick_delay: int, start_delay_frames := 0) {
	if start_delay_frames < 0 {
		log.errorf("Delay timer cannot have its StartDelayFrames amount be less than zero.")
		delay.tick_delay = tick_delay
		delay.original_start_delay_frames = 0
		delay_reset(delay)
		return
	}

	delay.tick_delay = tick_delay
	delay.original_start_delay_frames = start_delay_frames
	delay_reset(delay)
}

delay_tick :: proc(delay: ^Delay) {
	if delay.start_delay_frames > 0 {
		delay.start_delay_frames -= 1
		return
	}

	delay.current_tick += 1
	if delay.current_tick >= delay.tick_delay {
		delay.current_index += 1
		delay.current_tick = 0
	}
}

delay_reset :: proc(delay: ^Delay) {
	delay.current_tick = 0
	delay.current_index = 0
	delay.start_delay_frames = delay.original_start_delay_frames
}

delay_reset_timer_only :: proc(delay: ^Delay) {
	delay.current_tick = 0
	delay.start_delay_frames = delay.original_start_delay_frames
}
