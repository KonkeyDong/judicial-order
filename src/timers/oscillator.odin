package timers

import "core:log"

Oscillator :: struct($T: typeid) {
	levels:          []T,
	frames_per_step: int,
	frame_counter:   int,
	current_index:   int,
	direction:       int,
}

oscillator_init :: proc(oscillator: ^Oscillator($T), levels: []T, frames_per_step: int) {
	if len(levels) == 0 {
		log.errorf("Oscillator requires at least one level.")
		oscillator.levels = {}
		oscillator.frames_per_step = frames_per_step
		oscillator.frame_counter = frames_per_step
		oscillator.current_index = 0
		oscillator.direction = 1
		return
	}

	oscillator.levels = levels
	oscillator.frames_per_step = frames_per_step
	oscillator.frame_counter = frames_per_step
	oscillator.current_index = 0
	oscillator.direction = 1
}

oscillator_tick :: proc(oscillator: ^Oscillator($T)) {
	if len(oscillator.levels) == 0 {
		return
	}

	oscillator.frame_counter -= 1
	if oscillator.frame_counter <= 0 {
		oscillator.frame_counter = oscillator.frames_per_step
		oscillator.current_index += oscillator.direction
		if oscillator.current_index >= len(oscillator.levels) - 1 {
			oscillator.current_index = len(oscillator.levels) - 1
			oscillator.direction = -1
		} else if oscillator.current_index <= 0 {
			oscillator.current_index = 0
			oscillator.direction = 1
		}
	}
}

oscillator_reset :: proc(oscillator: ^Oscillator($T)) {
	oscillator.current_index = 0
	oscillator.direction = 1
	oscillator.frame_counter = oscillator.frames_per_step
}

oscillator_value :: proc(oscillator: Oscillator($T)) -> T {
	if len(oscillator.levels) == 0 {
		return T{}
	}

	return oscillator.levels[oscillator.current_index]
}
