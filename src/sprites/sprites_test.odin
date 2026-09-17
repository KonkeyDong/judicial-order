package sprites

import "core:testing"

@(test)
test_extract_frames_weasel_lawyer :: proc(test: ^testing.T) {
	frames := extract_frames("assets/sprites/weasel_lawyer.json")
	defer delete(frames)

	testing.expect_value(test, len(frames), 2)
	if len(frames) < 2 {
		return
	}

	testing.expect_value(test, frames[0].x, 0)
	testing.expect_value(test, frames[0].y, 0)
	testing.expect_value(test, frames[0].w, 24)
	testing.expect_value(test, frames[0].h, 24)
	testing.expect_value(test, frames[0].offset_x, 0)
	testing.expect_value(test, frames[0].offset_y, 0)

	testing.expect_value(test, frames[1].x, 24)
	testing.expect_value(test, frames[1].y, 0)
	testing.expect_value(test, frames[1].w, 24)
	testing.expect_value(test, frames[1].h, 24)
	testing.expect_value(test, frames[1].offset_x, 0)
	testing.expect_value(test, frames[1].offset_y, 0)
}
