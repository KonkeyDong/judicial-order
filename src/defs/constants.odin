package defs

import rl "vendor:raylib"

TILE_SIZE :: 24
TILES_DIR :: "assets/tiles"
WORLD_MAP_SPRITE_SIZE :: 24
MAX_BUCKET_SIZE :: 4
MAX_CONTEXT_TARGETS :: 64
MAX_OCCUPANT_SIZE :: 2
UNARMED_INDEX :: -1
WALK_FRAME_COUNT :: 2
MAX_STATUS_EFFECTS :: 4
STATUS_DURATION_PERMANENT :: max(int)

Debug :: struct {
	color:                       rl.Color,
	font_size:                   int,
	spacing:                     int,
	battle_grid_logical_spacing: int,
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
	width:  i32,
	height: i32,
	scale:  f32,
}

WINDOW :: Window {
	width  = 256,
	height = 224,
	scale  = 3.0,
}

Files :: struct {
	grass_tile:  string,
	forest_tile: string,
}

FILES :: Files {
	grass_tile  = "grass.png",
	forest_tile = "forest.png",
}

Combat_Amounts :: struct {
	min_variance: int,
	max_variance: int,
}

COMBAT_AMOUNTS :: Combat_Amounts {
	min_variance = 75,
	max_variance = 100,
}

Animations :: struct {
	highlight_transition_speed: f32,
	range_tint_frame_delay:     int,
	countdown_timer_delay:      int,
	movement_duration:          f32,
	flip_flop_delay:            int,
	blink_delay:                int,
	idle_delay:                 int,
	attack_delay:               int,
	jitter_offset:              int,
	artillery_tick_delay:       int,
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
	poison_damage_denominator: int,
	sleep_duration:            int,
	shield_duration:           int,
}

STATUS_EFFECTS :: Status_Effects {
	poison_damage_denominator = 8,
	sleep_duration            = 3,
	shield_duration           = 3,
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

Paths :: struct {
	assets:           string,
	sprites:          string,
	force_members:    string,
	monsters:         string,
	overworld:        string,
	promoted:         string,
	unpromoted:       string,
	frame_data:       string,
	placeholder_png:  string,
	placeholder_json: string,
	tiles:            string,
	grass_tile:       string,
	forest_tile:      string,
	shared:           string,
	item_icons:       string,
	magic_icons:      string,
	command_icons:    string,
	effects:          string,
}

PATHS :: Paths {
	assets           = "assets",
	sprites          = "assets/sprites",
	force_members    = "assets/sprites/force",
	monsters         = "assets/sprites/monsters",
	overworld        = "overworld",
	promoted         = "promoted",
	unpromoted       = "unpromoted",
	frame_data       = "FrameData.json",
	placeholder_png  = "assets/sprites/weasel_lawyer.png",
	placeholder_json = "assets/sprites/weasel_lawyer.json",
	tiles            = TILES_DIR,
	grass_tile       = TILES_DIR + "/" + FILES.grass_tile,
	forest_tile      = TILES_DIR + "/" + FILES.forest_tile,
	shared           = "assets/sprites/shared",
	item_icons       = "assets/sprites/shared/item_icons",
	magic_icons      = "assets/sprites/shared/magic_icons",
	command_icons    = "assets/sprites/shared/command_icons",
	effects          = "assets/sprites/shared/effects",
}

Give :: struct {
	trade_prompt_column_gap:       f32,
	trade_prompt_name_to_icon_gap: f32,
	trade_prompt_yes_no_y_factor:  f32,
	positions:                     struct {
		recipient_info_box:         rl.Vector2,
		recipient_inventory_center: rl.Vector2,
		trade_inventory_center:     rl.Vector2,
		trade_prompt_box:           rl.Vector2,
	},
}

GIVE :: Give {
	trade_prompt_column_gap = 24,
	trade_prompt_name_to_icon_gap = 6,
	trade_prompt_yes_no_y_factor = 0.82,
	positions = {
		recipient_info_box = {200, 160},
		recipient_inventory_center = {200, 110},
		trade_inventory_center = {128, 168},
		trade_prompt_box = {72, 70},
	},
}

Battle :: struct {
	transition_frames:  int,
	slide_pixels:       f32,
	attack_pose_frames: int,
	positions:          struct {
		unfriendly_stats:   rl.Vector2,
		friendly_stats:     rl.Vector2,
		unfriendly_standin: rl.Vector2,
		friendly_standin:   rl.Vector2,
		foreground:         rl.Vector2,
	},
}

BATTLE :: Battle {
	transition_frames = 60,
	slide_pixels = 140,
	attack_pose_frames = 20,
	positions = {
		unfriendly_stats = {15, 180},
		friendly_stats = {200, 15},
		unfriendly_standin = {50, 75},
		friendly_standin = {145, 90},
		foreground = {127, 150},
	},
}

// Process-lifetime backing store for Grid.range_tint. Slice this; do not delete the slice.
range_tint_levels := ANIMATIONS.range_tint_levels
