package game

import "core:testing"

import "data"
import unit_pkg "unit"

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
