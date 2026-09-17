package sprites

import "core:testing"

import "../defs"

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

@(test)
test_icon_set_defaults_and_blink :: proc(test: ^testing.T) {
	item_icons_init()
	magic_icons_init()
	defer item_icons_destroy()
	defer magic_icons_destroy()

	testing.expect_value(test, item_icons.selected, defs.Item_Name.NoItem)
	testing.expect_value(test, magic_icons.selected, defs.Magic_Family.Blaze)

	frame0 := Sprite {
		frame = {x = 0, y = 0, w = 24, h = 24},
	}
	frame1 := Sprite {
		frame = {x = 24, y = 0, w = 24, h = 24},
	}
	item_icons.animations[.ShortSword] = {frame0, frame1}
	item_icons_set_selected(.ShortSword)

	item_icons.flip_flop.is_on = true
	selected_on := item_icons_get(.ShortSword)
	testing.expect_value(test, selected_on.frame.x, 24)

	item_icons.flip_flop.is_on = false
	selected_off := item_icons_get(.ShortSword)
	testing.expect_value(test, selected_off.frame.x, 0)

	old_logger := context.logger
	context.logger = {}
	missing := item_icons_get(.MedicalHerb)
	context.logger = old_logger
	testing.expect_value(test, missing, Sprite{})
}
