package game

import rl "vendor:raylib"

TILE_SIZE :: 24
WORLD_MAP_SPRITE_SIZE :: 24
MAX_BUCKET_SIZE :: 4 // items or spell families

Debug :: struct {
	color:                       rl.Color,
	font_size:                   int,
	spacing:                     int,
	battle_grid_logical_spacing: int, // screen step = value * scale
	battle_grid_color:           rl.Color,
}

DEBUG :: Debug {
	color                       = rl.YELLOW,
	font_size                   = 16,
	spacing                     = 1,
	battle_grid_logical_spacing = 20,
	battle_grid_color           = {180, 40, 40, 255},
}

Window :: struct {
	width:  int, // pixels
	height: int, // pixels
	scale:  f32,
}

WINDOW :: Window {
	width  = 256,
	height = 224,
	scale  = 3.0,
}

Animations :: struct {
	highlight_transition_speed: f32, // lower = slower
	range_tint_frame_delay:     int,
	countdown_timer_delay:      int,
	movement_duration:          f32, // seconds
	flip_flop_delay:            int,
	blink_delay:                int,
	idle_delay:                 int,
	attack_delay:               int, // frames
	jitter_offset:              int, // pixels
	artillery_tick_delay:       int, // frames
	switch_state_countdown:     int,
	range_tint_levels:          [4]rl.Color,
	dissolve:                   struct {
		group_size:             int,
		number_of_frame_copies: int,
	},
}

ANIMATIONS :: Animations {
	highlight_transition_speed = 200,
	range_tint_frame_delay = 6,
	countdown_timer_delay = 60,
	movement_duration = 0.20,
	flip_flop_delay = 30,
	blink_delay = 7,
	idle_delay = 10,
	attack_delay = 10,
	jitter_offset = 3,
	artillery_tick_delay = 3,
	switch_state_countdown = 180,
	range_tint_levels = {
		{255, 255, 255, 255},
		{200, 220, 255, 200},
		{140, 180, 255, 180},
		{80, 120, 255, 160},
	},
	dissolve = {group_size = 6, number_of_frame_copies = 3},
}

Textures :: struct {
	base_origin:   rl.Vector2,
	base_rotation: f32,
	clear_color:   rl.Color,
	blue:          rl.Color,
	dark_orange:   rl.Color,
	light_orange:  rl.Color,
	off_white:     rl.Color,
	dark_red:      rl.Color,
}

TEXTURES :: Textures {
	base_origin   = {0, 0},
	base_rotation = 0,
	clear_color   = {255, 255, 255, 255},
	blue          = {38, 74, 220, 255},
	dark_orange   = {177, 82, 24, 255},
	light_orange  = {255, 203, 94, 255},
	off_white     = {248, 235, 244, 255},
	dark_red      = {180, 40, 40, 255},
}

Status_Effects :: struct {
	poison_damage_denominator: int, // max HP / this
	sleep_duration:            int, // 1 to 3 turns
}

STATUS_EFFECTS :: Status_Effects {
	poison_damage_denominator = 8,
	sleep_duration            = 3,
}

Items :: struct {
	break_chance: int,
}

ITEMS :: Items {
	break_chance = 8,
}

World_Map :: struct {
	max_movement_cost: int,
	positions:         struct {
		no_target_message_box: rl.Vector2,
	},
}

WORLD_MAP :: World_Map {
	max_movement_cost = 255,
	positions = {no_target_message_box = {100, 100}},
}

Message_Notice :: struct {
	no_magic:  string,
	no_item:   string,
	no_target: string,
}

MESSAGE_NOTICE :: Message_Notice {
	no_magic  = "No magic",
	no_item   = "No Item",
	no_target = "No target",
}
