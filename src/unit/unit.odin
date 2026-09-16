package unit

import "core:fmt"
import "core:log"

import "../defs"
import "../sprites"
import "../timers"
import rl "vendor:raylib"

Stat :: struct {
	current: int,
	max:     int,
}

stat_init :: proc(max: int) -> Stat {
	return Stat{current = max, max = max}
}

stat_string :: proc(stat: Stat) -> string {
	if stat.max == 0 {
		return "0 / 0"
	}

	return fmt.tprintf("%d / %d", stat.current, stat.max)
}

Movement_Origin :: struct {
	grid_x, grid_y: int,
}

MOVEMENT_ORIGIN_INVALID :: Movement_Origin {
	grid_x = -1,
	grid_y = -1,
}

movement_origin_valid :: proc(origin: Movement_Origin) -> bool {
	return origin.grid_x >= 0 && origin.grid_y >= 0
}

Unit_Data :: struct {
	name:          defs.Name,
	movement_type: defs.Movement_Type,
	movement:      int,
	base_hp:       int,
	base_mp:       int,
	base_attack:   int,
	base_defense:  int,
	base_speed:    int,
	friendly:      bool,
	level:         int,
	default_job:   defs.Job,
}

Item_Slot :: struct {
	name:    defs.Item_Name,
	damaged: bool,
}

ITEM_SLOT_EMPTY :: Item_Slot {
	name    = .NoItem,
	damaged = false,
}

item_slot_is_empty :: proc(slot: Item_Slot) -> bool {
	return slot.name == .NoItem
}

Status_Effect_Slot :: struct {
	type:     defs.Status_Effect,
	duration: int,
}

STATUS_EFFECT_EMPTY :: Status_Effect_Slot {
	type     = .None,
	duration = 0,
}

Unit :: struct {
	name:                  defs.Name,
	job:                   defs.Job,
	level:                 int,
	exp:                   int,
	hp:                    Stat,
	mp:                    Stat,
	attack:                int,
	defense:               int,
	speed:                 int,
	movement:              int,
	friendly:              bool,
	facing_direction:      defs.Direction,
	grid_x, grid_y:        int,
	on_map:                bool,
	movement_type:         defs.Movement_Type,
	promoted:              bool,
	items:                 [defs.MAX_BUCKET_SIZE]Item_Slot,
	equipped_weapon_index: int,
	magic_family_buckets:  [defs.MAX_BUCKET_SIZE]defs.Magic_Family,
	known_spells:          [defs.MAX_BUCKET_SIZE][defs.MAX_BUCKET_SIZE]defs.Magic_Name,
	known_spell_counts:    [defs.MAX_BUCKET_SIZE]int,
	status_effects:        [defs.MAX_STATUS_EFFECTS]Status_Effect_Slot,
	status_count:          int,
	movement_origin:       Movement_Origin,
	world_position:        rl.Vector2,
	target_world_position: rl.Vector2,
	start_world_position:  rl.Vector2,
	movement_timer:        f32,
	is_animating:          bool,
	movement_flip_flop:    timers.Flip_Flop,
	walk_animations:       [defs.Direction][defs.WALK_FRAME_COUNT]sprites.Sprite,
	walk_frames_loaded:    int,
}

init :: proc(unit: ^Unit, data: Unit_Data) {
	unit.name = data.name
	unit.movement_type = data.movement_type
	unit.movement = data.movement
	unit.hp = stat_init(data.base_hp)
	unit.mp = stat_init(data.base_mp)
	unit.attack = data.base_attack
	unit.defense = data.base_defense
	unit.speed = data.base_speed
	unit.friendly = data.friendly
	unit.level = data.level
	unit.exp = 0
	unit.job = data.default_job if data.friendly else {}
	unit.promoted = false
	unit.facing_direction = .Down
	unit.equipped_weapon_index = defs.UNARMED_INDEX
	unit.movement_origin = MOVEMENT_ORIGIN_INVALID
	unit.status_count = 0
	unit.walk_frames_loaded = 0
	unit.is_animating = false
	unit.movement_timer = 0
	unit.on_map = false
	unit.grid_x = -1
	unit.grid_y = -1

	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		unit.items[i] = ITEM_SLOT_EMPTY
		unit.magic_family_buckets[i] = .NoSpell
		unit.known_spell_counts[i] = 0
	}

	timers.init(&unit.movement_flip_flop, defs.ANIMATIONS.flip_flop_delay / 7)
	load_walk_animations(unit)

	log.infof(
		"Unit created → %s (%v), Friendly: %v, Lvl %d, Job: %v, Movement: %d",
		defs.name_display(unit.name),
		unit.movement_type,
		unit.friendly,
		unit.level,
		unit.job,
		unit.movement,
	)
}

make :: proc(data: Unit_Data, allocator := context.allocator) -> ^Unit {
	unit := new(Unit, allocator)
	init(unit, data)
	return unit
}

destroy :: proc(unit: ^Unit, allocator := context.allocator) {
	if unit == nil {
		return
	}

	free(unit, allocator)
}

is_promoted :: proc(unit: ^Unit) -> bool {
	return unit.friendly && unit.promoted
}

promote :: proc(unit: ^Unit) {
	log.warn("Promotion still needs to change job class! Expect crashes until implemented.")
	if !unit.friendly {
		unit.promoted = false
		return
	}

	unit.promoted = true
	load_walk_animations(unit)
}

to_string :: proc(unit: ^Unit) -> string {
	coords := "[null]"
	if unit.on_map {
		coords = fmt.tprintf("[%d, %d]", unit.grid_x, unit.grid_y)
	}

	return fmt.tprintf(
		"%s (%v) HP = [%d / %d] at %s",
		defs.name_display(unit.name),
		unit.movement_type,
		unit.hp.current,
		unit.hp.max,
		coords,
	)
}
