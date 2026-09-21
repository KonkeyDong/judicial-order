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
test_extract_frames_item_icons :: proc(test: ^testing.T) {
	frames := extract_frames("assets/sprites/shared/item_icons/FrameData.json")
	defer delete(frames)

	testing.expect_value(test, len(frames), 2)
	if len(frames) < 2 {
		return
	}

	testing.expect_value(test, frames[0].x, 0)
	testing.expect_value(test, frames[0].y, 0)
	testing.expect_value(test, frames[0].w, 17)
	testing.expect_value(test, frames[0].h, 25)
	testing.expect_value(test, frames[1].x, 17)
	testing.expect_value(test, frames[1].y, 0)
	testing.expect_value(test, frames[1].w, 17)
	testing.expect_value(test, frames[1].h, 25)
}

@(test)
test_icon_set_defaults_and_blink :: proc(test: ^testing.T) {
	item_icons_init()
	magic_icons_init()
	command_icons_init()
	defer item_icons_destroy()
	defer magic_icons_destroy()
	defer command_icons_destroy()

	testing.expect_value(test, item_icons.selected, defs.Item_Name.NoItem)
	testing.expect_value(test, magic_icons.selected, defs.Magic_Family.Blaze)
	testing.expect_value(test, command_icons.selected, defs.Command_Icon.Attack)

	frame0 := Sprite {
		frame = {x = 0, y = 0, w = 24, h = 24},
	}
	frame1 := Sprite {
		frame = {x = 24, y = 0, w = 24, h = 24},
	}
	item_icons.animations[.SmallBriefcase] = {frame0, frame1}
	item_icons_set_selected(.SmallBriefcase)

	item_icons.flip_flop.is_on = true
	selected_on := item_icons_get(.SmallBriefcase)
	testing.expect_value(test, selected_on.frame.x, 24)

	item_icons.flip_flop.is_on = false
	selected_off := item_icons_get(.SmallBriefcase)
	testing.expect_value(test, selected_off.frame.x, 0)

	old_logger := context.logger
	context.logger = {}
	missing := item_icons_get(.Hotdog)
	context.logger = old_logger
	testing.expect_value(test, missing, Sprite{})

	no_item := Sprite {
		frame = {x = 1, y = 2, w = 17, h = 25},
	}
	item_icons.animations[.NoItem] = {no_item, no_item}
	placeholder := item_icons_get(.Hotdog)
	testing.expect_value(test, placeholder.frame, no_item.frame)
	testing.expect_value(test, item_icons_resolve(.Hotdog), defs.Item_Name.NoItem)
	testing.expect_value(test, item_icons_resolve(.SmallBriefcase), defs.Item_Name.SmallBriefcase)

	command_icons.animations[.Attack] = {frame0, frame1}
	command_icons_set_selected(.Attack)
	command_icons.flip_flop.is_on = true
	attack_on := command_icons_get(.Attack)
	testing.expect_value(test, attack_on.frame.x, 24)

	command_icons.flip_flop.is_on = false
	attack_off := command_icons_get(.Attack)
	testing.expect_value(test, attack_off.frame.x, 0)
}
