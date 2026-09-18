package sprites

import "core:testing"

import "../data"
import "../timers"
import unit_pkg "../unit"

@(test)
test_renderer_ease_in_out :: proc(test: ^testing.T) {
	testing.expect_value(test, renderer_ease_in_out(0), f32(0))
	testing.expect_value(test, renderer_ease_in_out(0.25), f32(0.125))
	testing.expect_value(test, renderer_ease_in_out(0.5), f32(0.5))
	testing.expect_value(test, renderer_ease_in_out(1), f32(1))
}

@(test)
test_renderer_draw_unit_off_map_hale :: proc(test: ^testing.T) {
	data.init()
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	testing.expect(test, !hale.on_map)
	old_logger := context.logger
	context.logger = {}
	renderer_draw_unit(1, hale, false)
	context.logger = old_logger
}

@(test)
test_renderer_split_display_name :: proc(test: ^testing.T) {
	line1, line2 := renderer_split_display_name("Short Sword")
	testing.expect_value(test, line1, "Short")
	testing.expect_value(test, line2, "Sword")

	line1, line2 = renderer_split_display_name("Unarmed")
	testing.expect_value(test, line1, "Unarmed")
	testing.expect_value(test, line2, "")

	line1, line2 = renderer_split_display_name("Medical Herb")
	testing.expect_value(test, line1, "Medical")
	testing.expect_value(test, line2, "Herb")
}

@(test)
test_renderer_info_box_content_height :: proc(test: ^testing.T) {
	testing.expect_value(test, renderer_info_box_content_height(10, 10, 10, 4), 38)
}

@(test)
test_renderer_artillery_frame_index :: proc(test: ^testing.T) {
	not_started := timers.Sequence_Timer {
		start_delay_frames_remaining = 3,
		current_index                = 2,
	}
	frame_index, draw := renderer_artillery_frame_index(not_started, 4)
	testing.expect_value(test, draw, false)
	testing.expect_value(test, frame_index, 0)

	complete := timers.Sequence_Timer {
		is_complete   = true,
		current_index = 2,
	}
	frame_index, draw = renderer_artillery_frame_index(complete, 4)
	testing.expect_value(test, draw, false)
	testing.expect_value(test, frame_index, 0)

	playing := timers.Sequence_Timer {
		current_index = 1,
	}
	frame_index, draw = renderer_artillery_frame_index(playing, 0)
	testing.expect_value(test, draw, false)
	testing.expect_value(test, frame_index, 0)

	frame_index, draw = renderer_artillery_frame_index(playing, 4)
	testing.expect_value(test, draw, true)
	testing.expect_value(test, frame_index, 1)

	playing.current_index = -3
	frame_index, draw = renderer_artillery_frame_index(playing, 4)
	testing.expect_value(test, draw, true)
	testing.expect_value(test, frame_index, 0)

	playing.current_index = 9
	frame_index, draw = renderer_artillery_frame_index(playing, 4)
	testing.expect_value(test, draw, true)
	testing.expect_value(test, frame_index, 3)
}

@(test)
test_renderer_artillery_slice_bounds :: proc(test: ^testing.T) {
	slice_start, slice_end := renderer_artillery_slice_bounds(0, 3, 7)
	testing.expect_value(test, slice_start, 0)
	testing.expect_value(test, slice_end, 3)

	slice_start, slice_end = renderer_artillery_slice_bounds(3, 7, 7)
	testing.expect_value(test, slice_start, 3)
	testing.expect_value(test, slice_end, 7)

	slice_start, slice_end = renderer_artillery_slice_bounds(3, 7, 2)
	testing.expect_value(test, slice_start, 3)
	testing.expect_value(test, slice_end, 2)
}
