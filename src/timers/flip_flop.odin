package timers

Flip_Flop :: struct {
	frames_per_phase: int,
	counter:          int,
	is_on:            bool,
}

flip_flop_init :: proc(flip_flop: ^Flip_Flop, frames_per_phase: int) {
	flip_flop.frames_per_phase = frames_per_phase
	flip_flop.counter = 0
	flip_flop.is_on = false
}

flip_flop_tick :: proc(flip_flop: ^Flip_Flop) {
	flip_flop.counter += 1
	if flip_flop.counter >= flip_flop.frames_per_phase {
		flip_flop.is_on = !flip_flop.is_on
		flip_flop.counter = 0
	}
}

flip_flop_reset :: proc(flip_flop: ^Flip_Flop) {
	flip_flop.is_on = false
	flip_flop.counter = 0
}
