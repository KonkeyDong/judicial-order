package game

import "core:log"
import "core:math"

import "defs"
import "timers"
import unit_pkg "unit"
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
	grid:                         Grid,
	units:                        [dynamic]^unit_pkg.Unit,
	friendly_units_in_range:      [dynamic]^unit_pkg.Unit,
	unfriendly_units_in_range:    [dynamic]^unit_pkg.Unit,
	flip_flop:                    timers.Flip_Flop,
	battle_screen_mode:           defs.Battle_Screen_Mode,
	prompt:                       Prompt_Context,
	give:                         Give_Context,
	message_notice:               Message_Notice_Context,
	first_unit_died_from_poison:  bool,
	unit_that_died_from_poison:   ^unit_pkg.Unit,
	highlight_current_position:   rl.Vector2,
	highlight_target_position:    rl.Vector2,
	highlight_animation_complete: bool,
	state:                        defs.State_Kind,
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

game_init :: proc(game: ^Game, width, height: int) {
	grid_init(&game.grid, width, height)
	timers.flip_flop_init(&game.flip_flop, defs.ANIMATIONS.flip_flop_delay)
	game.battle_screen_mode = .Combat
	give_reset(&game.give)
	prompt_reset(&game.prompt)
	message_notice_reset(&game.message_notice)
	game.first_unit_died_from_poison = false
	game.unit_that_died_from_poison = nil
	game.state = .CalculateUnitMovementRange
	game.highlight_current_position = {}
	game.highlight_target_position = {}
	game.highlight_animation_complete = false
}

game_destroy :: proc(game: ^Game) {
	grid_destroy(&game.grid)
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
	game.highlight_current_position = pixel
	game.highlight_target_position = pixel
	game.highlight_animation_complete = false
}

game_set_highlight_target :: proc(game: ^Game, target_unit: ^unit_pkg.Unit) {
	if target_unit == nil || !target_unit.on_map {
		log.errorf("game_set_highlight_target: target unit is not on the map.")
		return
	}

	game.highlight_target_position = unit_pkg.tile_pixel(target_unit)
	game.highlight_animation_complete = false
}

game_update_highlight :: proc(game: ^Game, delta_time: f32) {
	delta := game.highlight_target_position - game.highlight_current_position
	distance := math.sqrt(delta.x * delta.x + delta.y * delta.y)
	if distance > GAME_HIGHLIGHT_SETTLE_DISTANCE {
		direction := delta * (1.0 / distance)
		move_distance := defs.ANIMATIONS.highlight_transition_speed * delta_time
		if move_distance > distance {
			move_distance = distance
		}

		game.highlight_current_position += direction * move_distance
	} else {
		game.highlight_current_position = game.highlight_target_position
		game.highlight_animation_complete = true
	}
}
