package timers

Countdown_Timer :: struct {
	duration_frames: int,
	frame_counter:   int,
	is_active:       bool,
}

countdown_timer_init :: proc(timer: ^Countdown_Timer, duration_frames: int) {
	timer.duration_frames = duration_frames
	timer.frame_counter = duration_frames
	timer.is_active = true
}

countdown_timer_tick :: proc(timer: ^Countdown_Timer) {
	if timer.frame_counter == 0 {
		return
	}

	timer.frame_counter -= 1
	if timer.frame_counter == 0 {
		timer.is_active = false
	}
}

countdown_timer_stop :: proc(timer: ^Countdown_Timer) {
	timer.frame_counter = 0
	timer.is_active = false
}

countdown_timer_start :: proc(timer: ^Countdown_Timer) {
	timer.is_active = true
}

countdown_timer_reset :: proc(timer: ^Countdown_Timer) {
	timer.frame_counter = timer.duration_frames
	timer.is_active = true
}
