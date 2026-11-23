package state

import game_pkg "../game"

import "core:c"
import "core:log"
import "core:strings"

import "../defs"
import "../sprites"
import rl "vendor:raylib"

@(private = "file")
Sprite_Demo :: struct {
	entries:          [dynamic]sprites.Sprite_Demo_Entry,
	character:        int,
	animation:        int,
	characters_open:  bool,
	animation_open:   bool,
	frame:            int,
	tick:             int,
	idle:             [dynamic]sprites.Sprite,
	attack:           [dynamic]sprites.Sprite,
}

@(private = "file")
demo: Sprite_Demo

@(private)
sprite_demo_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	sprite_demo_release()
	demo.entries = sprites.sprite_demo_collect()
	demo.character = sprites.sprite_demo_default_character(demo.entries[:])
	demo.animation = sprites.SPRITE_DEMO_ANIMATION_IDLE
	sprite_demo_reload()
	log.infof(
		"Sprite demo: %d characters, showing %s %s.",
		len(demo.entries),
		sprite_demo_character_name(),
		sprite_demo_animation_name(),
	)
}

@(private)
sprite_demo_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	sprite_demo_release()
}

@(private)
sprite_demo_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private)
sprite_demo_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	sheet := sprite_demo_sheet()
	if len(sheet) == 0 {
		demo.tick = 0
		demo.frame = 0
		return
	}

	demo.tick += 1
	if demo.tick < defs.ANIMATIONS.idle_delay {
		return
	}

	demo.tick = 0
	demo.frame += 1
	if demo.frame >= len(sheet) {
		demo.frame = 0
	}
}

@(private)
sprite_demo_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	sprite_demo_draw_checker(game.window.width, game.window.height)
	sprite_demo_draw_sprite(scale, game.renderer.debug_draw)
	sprite_demo_draw_caption(scale)

	previous_character := demo.character
	previous_animation := demo.animation
	sprite_demo_draw_menus(scale, game.window.width)
	if demo.character != previous_character {
		sprite_demo_reload()
		demo.frame = 0
		demo.tick = 0
	} else if demo.animation != previous_animation {
		demo.frame = 0
		demo.tick = 0
	}
}

@(private = "file")
sprite_demo_release :: proc() {
	delete(demo.idle)
	delete(demo.attack)
	delete(demo.entries)
	demo = {}
}

@(private = "file")
sprite_demo_reload :: proc() {
	delete(demo.idle)
	delete(demo.attack)
	demo.idle = nil
	demo.attack = nil
	if demo.character < 0 || demo.character >= len(demo.entries) {
		return
	}

	demo.idle, demo.attack = sprites.sprite_demo_load_sheets(demo.entries[demo.character])
}

@(private = "file")
sprite_demo_sheet :: proc() -> []sprites.Sprite {
	if demo.animation == sprites.SPRITE_DEMO_ANIMATION_ATTACK {
		return demo.attack[:]
	}

	return demo.idle[:]
}

@(private = "file")
sprite_demo_character_name :: proc() -> string {
	if demo.character < 0 || demo.character >= len(demo.entries) {
		return ""
	}

	return demo.entries[demo.character].display
}

@(private = "file")
sprite_demo_animation_name :: proc() -> string {
	labels := sprites.SPRITE_DEMO_ANIMATION_LABELS
	if demo.animation < 0 || demo.animation >= len(labels) {
		return labels[sprites.SPRITE_DEMO_ANIMATION_IDLE]
	}

	return labels[demo.animation]
}

// Screen-pixel checker, same idea as Aseprite's transparency backdrop.
// Squares stay 16px when the window scale changes.
@(private = "file")
sprite_demo_draw_checker :: proc(window_width, window_height: i32) {
	cell := i32(16)
	if window_width <= 0 || window_height <= 0 {
		return
	}

	light := rl.Color{192, 192, 192, 255}
	dark := rl.Color{128, 128, 128, 255}
	cols := (window_width + cell - 1) / cell
	rows := (window_height + cell - 1) / cell
	for y in 0 ..< rows {
		for x in 0 ..< cols {
			color := light
			if (x + y) % 2 == 1 {
				color = dark
			}

			rl.DrawRectangle(x * cell, y * cell, cell, cell, color)
		}
	}
}

@(private = "file")
sprite_demo_draw_sprite :: proc(scale: f32, debug_draw: bool) {
	sheet := sprite_demo_sheet()
	if len(sheet) == 0 {
		return
	}

	index := demo.frame
	if index < 0 || index >= len(sheet) {
		index = 0
	}

	sprite := sheet[index]
	x := (f32(defs.WINDOW.width) - f32(sprite.frame.w)) * 0.5
	y := (f32(defs.WINDOW.height) - f32(sprite.frame.h)) * 0.5
	sprites.renderer_draw(scale, sprite, {x, y}, 255, debug_draw)
}

@(private = "file")
sprite_demo_draw_caption :: proc(scale: f32) {
	font := sprite_demo_font(scale)
	margin := sprite_demo_margin(scale)
}

@(private = "file")
sprite_demo_draw_menus :: proc(scale: f32, window_width: i32) {
	if len(demo.entries) == 0 {
		return
	}

	font := sprite_demo_font(scale)
	margin := sprite_demo_margin(scale)
	gap := f32(8 * scale)
	if gap < 8 {
		gap = 8
	}

	sprite_demo_set_dropdown_style(font)
	char_w := sprite_demo_menu_width(sprite_demo_character_labels(), "Characters", font)
	anim_w := sprite_demo_menu_width(sprites.SPRITE_DEMO_ANIMATION_LABELS[:], "Animation", font)
	available := f32(window_width) - margin * 2 - gap
	total := char_w + anim_w
	if total > available && total > 0 {
		char_w = char_w * available / total
		anim_w = anim_w * available / total
	}

	// Label Positions
	label_y := margin + f32(font) * 0 + 6
	box_y := label_y + f32(font) + 4
	row_h := f32(font + font / 2)
	char_bounds := rl.Rectangle{margin, box_y, char_w, row_h}
	anim_bounds := rl.Rectangle{margin + char_w + gap, box_y, anim_w, row_h}

	sprite_demo_text("Characters", char_bounds.x, label_y, font)
	sprite_demo_text("Animation", anim_bounds.x, label_y, font)

	// The open list is drawn last so it sits above the other closed box.
	if demo.characters_open {
		sprite_demo_animation_dropdown(anim_bounds)
		sprite_demo_characters_dropdown(char_bounds)
	} else {
		sprite_demo_characters_dropdown(char_bounds)
		sprite_demo_animation_dropdown(anim_bounds)
	}
}

@(private = "file")
sprite_demo_characters_dropdown :: proc(bounds: rl.Rectangle) {
	active := c.int(demo.character)
	text := sprite_demo_character_text()
	if rl.GuiDropdownBox(bounds, text, &active, demo.characters_open) {
		demo.characters_open = !demo.characters_open
		if demo.characters_open {
			demo.animation_open = false
		}
	}

	count := len(demo.entries)
	if count == 0 {
		return
	}

	if active < 0 {
		active = 0
	}

	if int(active) >= count {
		active = c.int(count - 1)
	}

	demo.character = int(active)
}

@(private = "file")
sprite_demo_animation_dropdown :: proc(bounds: rl.Rectangle) {
	active := c.int(demo.animation)
	if rl.GuiDropdownBox(bounds, "Attack;Idle", &active, demo.animation_open) {
		demo.animation_open = !demo.animation_open
		if demo.animation_open {
			demo.characters_open = false
		}
	}

	count := len(sprites.SPRITE_DEMO_ANIMATION_LABELS)
	if active < 0 {
		active = 0
	}

	if int(active) >= count {
		active = c.int(count - 1)
	}

	demo.animation = int(active)
}

@(private = "file")
sprite_demo_character_labels :: proc() -> []string {
	labels := make([]string, len(demo.entries), context.temp_allocator)
	for entry, i in demo.entries {
		labels[i] = sprites.sprite_demo_row_label(entry)
	}

	return labels
}

@(private = "file")
sprite_demo_character_text :: proc() -> cstring {
	builder := strings.builder_make(context.temp_allocator)
	for entry, i in demo.entries {
		if i > 0 {
			strings.write_string(&builder, ";")
		}

		strings.write_string(&builder, sprites.sprite_demo_row_label(entry))
	}

	return strings.to_cstring(&builder)
}

@(private = "file")
sprite_demo_menu_width :: proc(labels: []string, title: string, font: int) -> f32 {
	width := sprite_demo_text_width(title, font)
	for label in labels {
		text_w := sprite_demo_text_width(label, font)
		if text_w > width {
			width = text_w
		}
	}

	pad := f32(font / 2)
	return width + pad * 2 + f32(font)
}

@(private = "file")
sprite_demo_set_dropdown_style :: proc(font: int) {
	text_size := c.int(font)
	rl.GuiSetStyle(.DEFAULT, c.int(rl.GuiDefaultProperty.TEXT_SIZE), text_size)
	rl.GuiSetStyle(.DROPDOWNBOX, c.int(rl.GuiDefaultProperty.TEXT_SIZE), text_size)
	rl.GuiSetStyle(.DROPDOWNBOX, c.int(rl.GuiControlProperty.TEXT_PADDING), c.int(font / 2))
	rl.GuiSetStyle(.DROPDOWNBOX, c.int(rl.GuiControlProperty.TEXT_ALIGNMENT), 0)
}

@(private = "file")
sprite_demo_font :: proc(scale: f32) -> int {
	font := int(8 * scale)
	if font < 8 {
		return 8
	}

	return font
}

@(private = "file")
sprite_demo_margin :: proc(scale: f32) -> f32 {
	margin := 4 * scale
	if margin < 4 {
		return 4
	}

	return margin
}

@(private = "file")
sprite_demo_text :: proc(text: string, x, y: f32, font: int) {
	if len(text) == 0 {
		return
	}

	label := strings.clone_to_cstring(text, context.temp_allocator)
	font_size := f32(font)
	outline := f32(1)
	if font >= 16 {
		outline = 2
	}

	shadow := rl.Color{20, 20, 20, 255}
	steps := [3]f32{-outline, 0, outline}
	for dy in steps {
		for dx in steps {
			if dx == 0 && dy == 0 {
				continue
			}

			rl.DrawTextEx(rl.GetFontDefault(), label, {x + dx, y + dy}, font_size, 1, shadow)
		}
	}

	rl.DrawTextEx(rl.GetFontDefault(), label, {x, y}, font_size, 1, rl.WHITE)
}

@(private = "file")
sprite_demo_text_width :: proc(text: string, font: int) -> f32 {
	return f32(rl.MeasureText(strings.clone_to_cstring(text, context.temp_allocator), c.int(font)))
}
