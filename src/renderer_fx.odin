package game

import "sprites"
import "timers"
import rl "vendor:raylib"

// Slot slice is owned storage; tick &slots[i].timer in place. Draw may copy a slot only as a read snapshot.
Sequence_Timer_Slot :: struct {
	timer:    timers.Sequence_Timer, // owned value, not a pointer
	position: rl.Vector2,
}

renderer_artillery_frame_index :: proc(
	timer: timers.Sequence_Timer,
	frame_count: int,
) -> (
	frame_index: int,
	draw: bool,
) {
	if frame_count <= 0 {
		return 0, false
	}

	if !timers.sequence_timer_is_playing(timer) {
		return 0, false
	}

	frame_index = timer.current_index
	if frame_index < 0 {
		frame_index = 0
	} else if frame_index >= frame_count {
		frame_index = frame_count - 1
	}

	return frame_index, true
}

renderer_artillery_slice_bounds :: proc(
	start, requested_end, slot_count: int,
) -> (
	slice_start, slice_end: int,
) {
	slice_start = start
	slice_end = requested_end
	if slice_end > slot_count {
		slice_end = slot_count
	}

	return
}

renderer_draw_artillery_explosions_in_front_of_sprite :: proc(
	scale: f32,
	slots: []Sequence_Timer_Slot,
	frames: []sprites.Sprite,
) {
	start, end := renderer_artillery_slice_bounds(0, 3, len(slots))
	renderer_draw_artillery_explosions_slice(scale, slots, frames, start, end)
}

renderer_draw_artillery_explosions_behind_sprite :: proc(
	scale: f32,
	slots: []Sequence_Timer_Slot,
	frames: []sprites.Sprite,
) {
	start, end := renderer_artillery_slice_bounds(3, 7, len(slots))
	renderer_draw_artillery_explosions_slice(scale, slots, frames, start, end)
}

renderer_draw_artillery_explosions_slice :: proc(
	scale: f32,
	slots: []Sequence_Timer_Slot,
	frames: []sprites.Sprite,
	start: int,
	end: int,
) {
	for i in start ..< end {
		frame_index, draw := renderer_artillery_frame_index(slots[i].timer, len(frames))
		if draw {
			renderer_draw(scale, frames[frame_index], slots[i].position)
		}
	}
}
