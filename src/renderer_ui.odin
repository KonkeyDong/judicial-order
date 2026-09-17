package game

import "core:fmt"
import "core:strings"

import "catalog"
import "defs"
import "sprites"
import unit_pkg "unit"
import rl "vendor:raylib"

Info_Box_Metrics :: struct {
	fill_x, fill_y, fill_w, fill_h:       int,
	text_left_x, text_start_y:            int,
	font_size, line_spacing, left_margin: int,
}

renderer_draw_info_box_frame :: proc(
	scale: f32,
	position: rl.Vector2,
	content_width: f32,
	content_height: f32,
) -> Info_Box_Metrics {
	font_size := int(8 * scale)
	padding := 12
	line_spacing := 4
	left_margin := 8

	box_width := int(content_width) + padding * 2
	box_height := int(content_height) + padding * 2
	box_x := int(position.x * scale) - padding
	box_y := int(position.y * scale) - padding

	rl.DrawRectangle(
		i32(box_x),
		i32(box_y),
		i32(box_width),
		i32(box_height),
		defs.TEXTURES.dark_orange,
	)
	rl.DrawRectangle(i32(box_x), i32(box_y), i32(box_width), 3, defs.TEXTURES.light_orange)
	rl.DrawRectangle(i32(box_x), i32(box_y), 3, i32(box_height), defs.TEXTURES.light_orange)

	inner_x := box_x + 3
	inner_y := box_y + 3
	inner_w := box_width - 6
	inner_h := box_height - 6
	rl.DrawRectangle(
		i32(inner_x),
		i32(inner_y),
		i32(inner_w),
		i32(inner_h),
		defs.TEXTURES.off_white,
	)

	fill_x := inner_x + 3
	fill_y := inner_y + 3
	fill_w := inner_w - 6
	fill_h := inner_h - 6
	rl.DrawRectangle(i32(fill_x), i32(fill_y), i32(fill_w), i32(fill_h), defs.TEXTURES.blue)

	return Info_Box_Metrics {
		fill_x = fill_x,
		fill_y = fill_y,
		fill_w = fill_w,
		fill_h = fill_h,
		text_left_x = fill_x + left_margin,
		text_start_y = fill_y + 6,
		font_size = font_size,
		line_spacing = line_spacing,
		left_margin = left_margin,
	}
}

renderer_measure_text :: proc(text: string, font_size: int) -> rl.Vector2 {
	return rl.MeasureTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(text, context.temp_allocator),
		f32(font_size),
		1,
	)
}

renderer_info_box_content_height :: proc(line0_h, line1_h, line2_h, line_spacing: int) -> int {
	return line0_h + line1_h + line2_h + (line_spacing * 2)
}

renderer_split_display_name :: proc(display: string) -> (line1, line2: string) {
	last_space := -1
	for i in 0 ..< len(display) {
		if display[i] == ' ' {
			last_space = i
		}
	}

	if last_space < 0 {
		return display, ""
	}

	return display[:last_space], display[last_space + 1:]
}

renderer_draw_info_box_text :: proc(text: string, pos: rl.Vector2, font_size: int) {
	rl.DrawTextEx(
		rl.GetFontDefault(),
		strings.clone_to_cstring(text, context.temp_allocator),
		pos,
		f32(font_size),
		1,
		rl.WHITE,
	)
}

renderer_draw_battle_menu_message :: proc(scale: f32, text: string, text_pos: rl.Vector2) {
	font_size := int(8 * scale)
	text_size := renderer_measure_text(text, font_size)
	metrics := renderer_draw_info_box_frame(scale, text_pos, text_size.x, text_size.y)

	final_text_pos := rl.Vector2 {
		f32(metrics.fill_x) + (f32(metrics.fill_w) - text_size.x) / 2,
		f32(metrics.fill_y) + (f32(metrics.fill_h) - text_size.y) / 2,
	}
	renderer_draw_info_box_text(text, final_text_pos, metrics.font_size)
}

renderer_draw_spell_info_box :: proc(
	scale: f32,
	spell: catalog.Magic_Data,
	position: rl.Vector2,
	highlight_level := false,
) {
	font_size := int(8 * scale)
	// C# MagicName.GetBaseName() is the family ("Blaze"), not Blaze1.
	line1 := defs.magic_family_base(catalog.magic_data_family(spell))
	line2 := fmt.tprintf("Level %d", spell.level)
	line3_left := "MP"
	line3_right := fmt.tprintf("%d", spell.mp_cost)

	size1 := renderer_measure_text(line1, font_size)
	size2 := renderer_measure_text(line2, font_size)
	size_left := renderer_measure_text(line3_left, font_size)
	size_right := renderer_measure_text(line3_right, font_size)

	content_width := max(size1.x, size2.x, size_left.x + size_right.x + 20)
	content_height := size1.y + size2.y + size_left.y + f32(4 * 2)

	metrics := renderer_draw_info_box_frame(scale, position, content_width, content_height)
	y := metrics.text_start_y

	renderer_draw_info_box_text(line1, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	y += int(size1.y + f32(metrics.line_spacing))

	if highlight_level {
		pad := 2
		rl.DrawRectangle(
			i32(metrics.text_left_x - pad),
			i32(y - pad),
			i32(size2.x + f32(pad * 2)),
			i32(size2.y + f32(pad * 2)),
			defs.TEXTURES.dark_red,
		)
	}

	renderer_draw_info_box_text(line2, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	y += int(size2.y + f32(metrics.line_spacing))

	renderer_draw_info_box_text(line3_left, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	renderer_draw_info_box_text(
		line3_right,
		{f32(metrics.fill_x + metrics.fill_w) - size_right.x - f32(metrics.left_margin), f32(y)},
		metrics.font_size,
	)
}

renderer_draw_unit_info_box :: proc(
	scale: f32,
	unit: ^unit_pkg.Unit,
	position: rl.Vector2,
	alpha := 255,
) {
	// C# accepts alpha; the body never tints the box.
	_ = alpha

	font_size := int(8 * scale)
	line1 := defs.name_display(unit.name)
	line2 := fmt.tprintf("HP: %s", unit_pkg.stat_string(unit.hp))
	line3 := fmt.tprintf("MP: %s", unit_pkg.stat_string(unit.mp))

	size1 := renderer_measure_text(line1, font_size)
	size2 := renderer_measure_text(line2, font_size)
	size3 := renderer_measure_text(line3, font_size)

	content_width := max(size1.x, size2.x, size3.x)
	content_height := size1.y + size2.y + size3.y + f32(4 * 2)

	metrics := renderer_draw_info_box_frame(scale, position, content_width, content_height)
	y := metrics.text_start_y

	renderer_draw_info_box_text(line1, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	y += int(size1.y + f32(metrics.line_spacing))
	renderer_draw_info_box_text(line2, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	y += int(size2.y + f32(metrics.line_spacing))
	renderer_draw_info_box_text(line3, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
}

renderer_draw_item_info_box :: proc(
	scale: f32,
	item: catalog.Item_Data,
	is_equipped: bool,
	position: rl.Vector2,
) {
	font_size := int(8 * scale)
	line1, line2 := renderer_split_display_name(defs.item_name_display(item.name))
	line3 := ""
	if is_equipped {
		line3 = "EQUIPPED"
	}

	size2_src := "A"
	if line2 != "" {
		size2_src = line2
	}
	size3_src := "EQUIPPED"
	if line3 != "" {
		size3_src = line3
	}

	size1 := renderer_measure_text(line1, font_size)
	size2 := renderer_measure_text(size2_src, font_size)
	size3 := renderer_measure_text(size3_src, font_size)

	content_width := max(size1.x, size2.x, size3.x)
	content_height := size1.y + size2.y + size3.y + f32(4 * 2)

	metrics := renderer_draw_info_box_frame(scale, position, content_width, content_height)
	y := metrics.text_start_y

	renderer_draw_info_box_text(line1, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	y += int(size1.y + f32(metrics.line_spacing))

	if line2 != "" {
		renderer_draw_info_box_text(line2, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	}

	y += int(size2.y + f32(metrics.line_spacing))

	if is_equipped {
		renderer_draw_info_box_text(line3, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	}
}

renderer_draw_equip_weapon_info_box :: proc(
	scale: f32,
	item: catalog.Item_Data,
	position: rl.Vector2,
) {
	font_size := int(8 * scale)
	line1 := "WEAPON"
	line2: string
	line3: string
	if item.name == .Unarmed {
		line2 = "REMOVE"
		line3 = ""
	} else {
		line2, line3 = renderer_split_display_name(defs.item_name_display(item.name))
	}

	size3_src := "A"
	if line3 != "" {
		size3_src = line3
	}

	size1 := renderer_measure_text(line1, font_size)
	size2 := renderer_measure_text(line2, font_size)
	size3 := renderer_measure_text(size3_src, font_size)

	content_width := max(size1.x, size2.x, size3.x)
	content_height := size1.y + size2.y + size3.y + f32(4 * 2)

	metrics := renderer_draw_info_box_frame(scale, position, content_width, content_height)
	y := metrics.text_start_y

	renderer_draw_info_box_text(line1, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	y += int(size1.y + f32(metrics.line_spacing))
	renderer_draw_info_box_text(line2, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	y += int(size2.y + f32(metrics.line_spacing))

	if line3 != "" {
		renderer_draw_info_box_text(line3, {f32(metrics.text_left_x), f32(y)}, metrics.font_size)
	}
}

renderer_draw_equip_stats_box :: proc(
	scale: f32,
	attack, defense, move, agility: int,
	position: rl.Vector2,
) {
	font_size := int(8 * scale)
	labels := [4]string{"ATTACK", "DEFENSE", "MOVE", "AGILITY"}
	values := [4]string {
		fmt.tprintf("%d", attack),
		fmt.tprintf("%d", defense),
		fmt.tprintf("%d", move),
		fmt.tprintf("%d", agility),
	}
	value_gap := f32(16)

	max_label_width: f32 = 0
	max_value_width: f32 = 0
	line_height: f32 = 0

	for i in 0 ..< len(labels) {
		label_size := renderer_measure_text(labels[i], font_size)
		value_size := renderer_measure_text(values[i], font_size)
		max_label_width = max(max_label_width, label_size.x)
		max_value_width = max(max_value_width, value_size.x)
		line_height = max(line_height, label_size.y)
	}

	content_width := max_label_width + value_gap + max_value_width
	content_height := (line_height * f32(len(labels))) + f32(4 * (len(labels) - 1))

	metrics := renderer_draw_info_box_frame(scale, position, content_width, content_height)
	y := f32(metrics.text_start_y)
	value_right_x := f32(metrics.fill_x + metrics.fill_w - metrics.left_margin)

	for i in 0 ..< len(labels) {
		renderer_draw_info_box_text(labels[i], {f32(metrics.text_left_x), y}, metrics.font_size)
		value_size := renderer_measure_text(values[i], metrics.font_size)
		renderer_draw_info_box_text(
			values[i],
			{value_right_x - value_size.x, y},
			metrics.font_size,
		)
		y += line_height + f32(metrics.line_spacing)
	}
}

renderer_draw_trade_prompt_box :: proc(
	scale: f32,
	action_label: string,
	giver_name: string,
	giver_item: defs.Item_Name,
	receiver_name: string,
	receiver_item: defs.Item_Name,
	has_receiver_item: bool,
	position: rl.Vector2,
) {
	font_size := int(8 * scale)
	icon_logical := defs.TILE_SIZE
	column_gap := defs.GIVE.trade_prompt_column_gap * scale
	name_to_icon_gap := defs.GIVE.trade_prompt_name_to_icon_gap * scale

	action_size := renderer_measure_text(action_label, font_size)
	giver_name_size := renderer_measure_text(giver_name, font_size)
	receiver_name_size := renderer_measure_text(receiver_name, font_size)

	icon_pixel := f32(icon_logical) * scale
	left_col_width := max(giver_name_size.x, icon_pixel)
	right_col_width := max(receiver_name_size.x, icon_pixel)
	content_width := max(action_size.x, left_col_width + column_gap + right_col_width)
	content_height :=
		action_size.y +
		name_to_icon_gap +
		max(giver_name_size.y, receiver_name_size.y) +
		name_to_icon_gap +
		icon_pixel

	metrics := renderer_draw_info_box_frame(scale, position, content_width, content_height)

	action_x := f32(metrics.fill_x) + (f32(metrics.fill_w) - action_size.x) / 2
	y := f32(metrics.text_start_y)
	renderer_draw_info_box_text(action_label, {action_x, y}, metrics.font_size)

	y += action_size.y + name_to_icon_gap

	left_col_left := metrics.text_left_x
	right_col_right := metrics.fill_x + metrics.fill_w - metrics.left_margin

	renderer_draw_info_box_text(giver_name, {f32(left_col_left), y}, metrics.font_size)
	renderer_draw_info_box_text(
		receiver_name,
		{f32(right_col_right) - receiver_name_size.x, y},
		metrics.font_size,
	)

	y += max(giver_name_size.y, receiver_name_size.y) + name_to_icon_gap

	icon_y_logical := y / scale
	left_icon_x_logical := f32(left_col_left) / scale
	right_icon_x_logical := (f32(right_col_right) - icon_pixel) / scale

	renderer_draw_item_icon(scale, giver_item, {left_icon_x_logical, icon_y_logical}, false)

	if has_receiver_item {
		renderer_draw_item_icon(
			scale,
			receiver_item,
			{right_icon_x_logical, icon_y_logical},
			false,
		)
	}
}

renderer_draw_magic_icon :: proc(scale: f32, family: defs.Magic_Family, position: rl.Vector2) {
	sprite := sprites.magic_icons_get(family)
	renderer_draw(scale, sprite, position, 255, false)
}

renderer_draw_item_icon :: proc(
	scale: f32,
	name: defs.Item_Name,
	position: rl.Vector2,
	is_selected := false,
) {
	sprite := sprites.item_icons_get_selected(name, is_selected)
	renderer_draw(scale, sprite, position, 255, false)
}
