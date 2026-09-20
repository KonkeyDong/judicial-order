package game

import "core:log"
import "core:math"

import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"
import rl "vendor:raylib"

GAME_HIGHLIGHT_SETTLE_DISTANCE :: 0.1
GAME_STUB_WIDTH :: 11
GAME_STUB_HEIGHT :: 10

Give_Context :: struct {
	giver_slot_index:     int,
	recipient:            ^unit_pkg.Unit,
	recipient_slot_index: int,
}

Prompt_Context :: struct {
	action:              defs.Prompt_Action,
	return_state_on_no:  defs.State_Kind,
	return_state_on_yes: defs.State_Kind,
	item_slot_index:     int,
}

Message_Notice_Context :: struct {
	message:      string,
	return_state: defs.State_Kind,
}

Game :: struct {
	renderer:                    sprites.Renderer,
	grid:                        Grid,
	units:                       [dynamic]^unit_pkg.Unit,
	friendly_units_in_range:     [dynamic]^unit_pkg.Unit,
	unfriendly_units_in_range:   [dynamic]^unit_pkg.Unit,
	overworld_idle_flip_flop:    timers.Flip_Flop,
	battle_screen_mode:          defs.Battle_Screen_Mode,
	contexts:                    State_Contexts,
	first_unit_died_from_poison: bool,
	unit_that_died_from_poison:  ^unit_pkg.Unit,
	highlight:                   Highlight,
	state:                       defs.State_Kind,
	window:                      defs.Window_View,
	state_scratch:               State_Scratch,
	magic_ui:                    sprites.Magic_UI,
	item_ui:                     sprites.Item_UI,
}

State_Contexts :: struct {
	prompt:         Prompt_Context,
	give:           Give_Context,
	message_notice: Message_Notice_Context,
	attack_context: Attack_Context,
	item_context:   Item_Context,
	magic_context:  Magic_Context,
}

// stores the coordinates of the highlight box
Highlight :: struct {
	current_position:   rl.Vector2,
	target_position:    rl.Vector2,
	animation_complete: bool,
}

// temporary data
State_Scratch :: struct {
	countdown:             timers.Countdown_Timer,
	blinker:               timers.Flip_Flop,
	delay:                 timers.Delay,
	selected_command:      defs.Command_Icon,
	list_index:            int,
	yes_selected:          bool,
	is_poisoned:           bool,
	is_sleeping:           bool,
	battle_progress:       f32,
	battle_item_mode:      bool,
	death_direction_index: int,
	death_phase_done:      bool,
	death_delay:           int,
	resolution_frame:      int,
	targets:               [defs.MAX_CONTEXT_TARGETS]^unit_pkg.Unit,
	target_count:          int,
	use_mode:              defs.Use_Mode,
	equip_unarmed:         bool,
}

give_reset :: proc(give: ^Give_Context) {
	give.giver_slot_index = -1
	give.recipient = nil
	give.recipient_slot_index = -1
}

prompt_reset :: proc(prompt: ^Prompt_Context) {
	prompt.action = .None
	prompt.item_slot_index = -1
	prompt.return_state_on_no = .BattleActionMenu
	prompt.return_state_on_yes = .BattleActionMenu
}

message_notice_reset :: proc(notice: ^Message_Notice_Context) {
	notice.message = ""
	notice.return_state = .BattleActionMenu
}

message_notice_set :: proc(
	notice: ^Message_Notice_Context,
	message: string,
	return_state: defs.State_Kind,
) {
	notice.message = message
	notice.return_state = return_state
}

highlight_reset :: proc(highlight: ^Highlight) {
	highlight.current_position = {}
	highlight.target_position = {}
	highlight.animation_complete = false
}

state_contexts_reset :: proc(contexts: ^State_Contexts) {
	give_reset(&contexts.give)
	prompt_reset(&contexts.prompt)
	message_notice_reset(&contexts.message_notice)
	attack_context_reset(&contexts.attack_context)
	item_context_reset(&contexts.item_context)
	magic_context_reset(&contexts.magic_context)
}

game_init :: proc(game: ^Game, width, height: int) {
	grid_init(&game.grid, width, height)
	sprites.renderer_init(&game.renderer)
	timers.flip_flop_init(&game.overworld_idle_flip_flop, defs.ANIMATIONS.flip_flop_delay)
	game.battle_screen_mode = .Combat
	state_contexts_reset(&game.contexts)
	game.first_unit_died_from_poison = false
	game.unit_that_died_from_poison = nil
	game.state = .CalculateUnitMovementRange
	highlight_reset(&game.highlight)
	game.window = defs.window_view_from_scale(defs.WINDOW.scale)
	state_scratch_init(&game.state_scratch)
	sprites.magic_ui_reset(&game.magic_ui)
	sprites.magic_ui_reset_layout_center(&game.magic_ui, game.window)
	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
}

state_scratch_init :: proc(scratch: ^State_Scratch) {
	timers.countdown_timer_init(&scratch.countdown, defs.ANIMATIONS.switch_state_countdown)
	timers.flip_flop_init(&scratch.blinker, defs.ANIMATIONS.blink_delay)
	timers.delay_init(&scratch.delay, defs.ANIMATIONS.idle_delay)
	scratch.selected_command = .Attack
	scratch.list_index = 0
	scratch.yes_selected = true
	scratch.target_count = 0
}

game_destroy :: proc(game: ^Game) {
	grid_destroy(&game.grid)
	sprites.renderer_destroy(&game.renderer)
	delete(game.units)
	delete(game.friendly_units_in_range)
	delete(game.unfriendly_units_in_range)
	game.units = nil
	game.friendly_units_in_range = nil
	game.unfriendly_units_in_range = nil
}

game_add_unit :: proc(game: ^Game, unit: ^unit_pkg.Unit, x, y: int) -> bool {
	if unit == nil {
		log.errorf("game_add_unit: unit parameter is nil; aborting.")
		return false
	}

	if !grid_place_unit(&game.grid, unit, x, y) {
		return false
	}

	append(&game.units, unit)
	return true
}

game_current_unit :: proc(game: ^Game) -> ^unit_pkg.Unit {
	if len(game.units) == 0 {
		log.errorf("game_current_unit: list of units is empty! Aborting...")
		return nil
	}

	return game.units[0]
}

game_next_unit :: proc(game: ^Game) -> ^unit_pkg.Unit {
	if len(game.units) == 0 {
		log.errorf("List of units is empty. Aborting...")
		return nil
	}

	if len(game.units) < 2 {
		log.warnf("game_next_unit: list of units is less than two.")
		return game.units[0]
	}

	return game.units[1]
}

game_move_first_unit_to_end :: proc(game: ^Game) {
	if len(game.units) <= 1 {
		log.warnf("game_move_first_unit_to_end: Units list is empty.")
		return
	}

	first := game.units[0]
	ordered_remove(&game.units, 0)
	append(&game.units, first)
}

game_set_first_unit_died_from_poison :: proc(game: ^Game, unit: ^unit_pkg.Unit) {
	log.info("About to set poison flag to true.")
	game.first_unit_died_from_poison = true
	game.unit_that_died_from_poison = unit
}

game_reset_first_unit_died_from_poison :: proc(game: ^Game) {
	log.info("About to set poison flag to false.")
	game.first_unit_died_from_poison = false
	game.unit_that_died_from_poison = nil
}

game_reset_units_in_range :: proc(game: ^Game) {
	clear(&game.friendly_units_in_range)
	clear(&game.unfriendly_units_in_range)
}

game_separate_units_in_range :: proc(
	game: ^Game,
	current_unit: ^unit_pkg.Unit,
	units_in_range: []^unit_pkg.Unit,
) {
	if current_unit == nil {
		log.errorf("game_separate_units_in_range: current unit is nil.")
		return
	}

	log.debug(
		"Game::SeparateListOfUnitsInRange(): resetting FriendlyUnitsInRange and UnfriendlyUnitsInRange lists.",
	)
	game_reset_units_in_range(game)
	for unit_in_range in units_in_range {
		if unit_in_range == nil {
			continue
		}

		if current_unit.friendly == unit_in_range.friendly {
			append(&game.friendly_units_in_range, unit_in_range)
		} else {
			append(&game.unfriendly_units_in_range, unit_in_range)
		}
	}

	log.infof(
		"FriendlyUnitsInRange.Count = %d; UnfriendlyUnitsInRange.Count = %d.",
		len(game.friendly_units_in_range),
		len(game.unfriendly_units_in_range),
	)
}

game_find_all_dead_units :: proc(game: ^Game, allocator := context.allocator) -> []^unit_pkg.Unit {
	log.debug("Game::FindAllDeadUnits(): removing all units that have 0 (current) HP.")
	dead := make([dynamic]^unit_pkg.Unit, allocator)
	for unit in game.units {
		if unit_pkg.is_dead(unit) {
			append(&dead, unit)
		}
	}

	log.infof("Number of dead units FOUND: [%d].", len(dead))
	result := make([]^unit_pkg.Unit, len(dead), allocator)
	copy(result, dead[:])
	delete(dead)
	return result
}

game_remove_all_dead_units :: proc(
	game: ^Game,
	allocator := context.allocator,
) -> []^unit_pkg.Unit {
	log.debug("Game::RemoveAllDeadUnits(): removing all units that have 0 (current) HP.")
	dead := game_find_all_dead_units(game, allocator)
	kept := 0
	for unit in game.units {
		if !unit_pkg.is_dead(unit) {
			game.units[kept] = unit
			kept += 1
		}
	}

	resize(&game.units, kept)
	grid_remove_dead_units(&game.grid, dead)
	for unit in dead {
		unit_pkg.remove_all_status(unit)
	}

	log.infof("Number of dead units REMOVED: [%d].", len(dead))
	return dead
}

game_initialize_highlight :: proc(game: ^Game) {
	current := game_current_unit(game)
	if current == nil || !current.on_map {
		log.errorf("game_initialize_highlight: current unit is not on the map.")
		return
	}

	pixel := unit_pkg.tile_pixel(current)
	game.highlight.current_position = pixel
	game.highlight.target_position = pixel
	game.highlight.animation_complete = false
}

game_set_highlight_target :: proc(game: ^Game, target_unit: ^unit_pkg.Unit) {
	if target_unit == nil || !target_unit.on_map {
		log.errorf("game_set_highlight_target: target unit is not on the map.")
		return
	}

	game.highlight.target_position = unit_pkg.tile_pixel(target_unit)
	game.highlight.animation_complete = false
}

game_update_highlight :: proc(game: ^Game, delta_time: f32) {
	h := &game.highlight
	delta := h.target_position - h.current_position
	distance := math.sqrt(delta.x * delta.x + delta.y * delta.y)
	if distance > GAME_HIGHLIGHT_SETTLE_DISTANCE {
		direction := delta * (1.0 / distance)
		move_distance := defs.ANIMATIONS.highlight_transition_speed * delta_time
		if move_distance > distance {
			move_distance = distance
		}

		h.current_position += direction * move_distance
	} else {
		h.current_position = h.target_position
		h.animation_complete = true
	}
}
