package state

import game_pkg "../game"
import unit_pkg "../unit"
import rl "vendor:raylib"

import "core:log"

import "../catalog"
import "../defs"
import "../sprites"
import "../timers"


use_item_on_whom_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	slot_index := game.contexts.prompt.item_slot_index
	if slot_index < 0 || slot_index >= defs.MAX_BUCKET_SIZE {
		log.errorf("UseItemOnWhom: invalid ItemSlotIndex. Returning to UseWhichItem.")
		state_change(game, .UseWhichItem)
		return
	}

	slot := unit_pkg.item_at(current, slot_index)
	data := catalog.item_get(slot.name)
	game.state_scratch.target_count = 0
	if data.type == .Consumable &&
	   (data.effect_type == .Heal ||
			   data.effect_type == .RemovePoison ||
			   data.effect_type == .HealAllFull) {
		game.state_scratch.use_mode = .Consumable
		if data.effect_type == .HealAllFull {
			use_item_on_whom_enter_heal_all(game, current)
			return
		}

		use_item_on_whom_enter_consumable(game, current, data)
		return
	}

	if data.spell_name != .NoSpell {
		if !defs.job_is_allowed_by(current.job, data.allowed_jobs) {
			state_change(game, .UseWhichItem)
			return
		}

		game.state_scratch.use_mode = .SpellItem
		use_item_on_whom_enter_spell(game, current, catalog.magic_get(data.spell_name))
		return
	}

	state_change(game, .UseWhichItem)
}

use_item_on_whom_push_target :: proc(game: ^game_pkg.Game, target: ^unit_pkg.Unit) {
	if target == nil || game.state_scratch.target_count >= len(game.state_scratch.targets) {
		return
	}

	for i in 0 ..< game.state_scratch.target_count {
		if game.state_scratch.targets[i] == target {
			return
		}
	}

	game.state_scratch.targets[game.state_scratch.target_count] = target
	game.state_scratch.target_count += 1
}

use_item_on_whom_enter_heal_all :: proc(game: ^game_pkg.Game, current: ^unit_pkg.Unit) {
	for unit in game.units {
		if unit != nil && unit.friendly == current.friendly && !unit_pkg.is_dead(unit) {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	use_item_on_whom_confirm_consumable_targets(game)
}

use_item_on_whom_enter_consumable :: proc(
	game: ^game_pkg.Game,
	current: ^unit_pkg.Unit,
	data: catalog.Item_Data,
) {
	game_pkg.grid_calculate_item_use_range(&game.grid, current, data)
	units := game_pkg.grid_units_in_range(&game.grid)
	defer delete(units)
	for unit in units {
		if unit != nil && unit.friendly == current.friendly {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if current.on_map && game_pkg.grid_in_range(&game.grid, current.grid_x, current.grid_y) {
		use_item_on_whom_push_target(game, current)
		// Prefer self first.
		if game.state_scratch.target_count > 1 {
			game.state_scratch.targets[0], game.state_scratch.targets[game.state_scratch.target_count - 1] =
				game.state_scratch.targets[game.state_scratch.target_count - 1],
				game.state_scratch.targets[0]
		}
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	game.state_scratch.list_index = 0
	game_pkg.game_initialize_highlight(game)
	game_pkg.game_set_highlight_target(game, game.state_scratch.targets[0])
}

use_item_on_whom_enter_spell :: proc(
	game: ^game_pkg.Game,
	current: ^unit_pkg.Unit,
	magic: catalog.Magic_Data,
) {
	game_pkg.grid_calculate_magic_attack_range(&game.grid, current, magic)
	units := game_pkg.grid_units_in_range(&game.grid)
	defer delete(units)
	for unit in units {
		if unit == nil {
			continue
		}

		if magic.offensive {
			if unit.friendly != current.friendly {
				use_item_on_whom_push_target(game, unit)
			}
		} else if unit.friendly == current.friendly {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if !magic.offensive &&
	   current.on_map &&
	   game_pkg.grid_in_range(&game.grid, current.grid_x, current.grid_y) {
		use_item_on_whom_push_target(game, current)
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	game.state_scratch.list_index = 0
	game_pkg.game_initialize_highlight(game)
	game_pkg.game_set_highlight_target(game, game.state_scratch.targets[0])
}

use_item_on_whom_exit :: proc(_: ^game_pkg.Game) {}

use_item_on_whom_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_try_cycle_index(
		&game.state_scratch.list_index,
		game.state_scratch.target_count,
	) {
		target := game.state_scratch.targets[game.state_scratch.list_index]
		if target != nil && target.on_map {
			game_pkg.game_set_highlight_target(game, target)
		}
	}

	if game_pkg.input_confirm_press() {
		if game.state_scratch.use_mode == .Consumable {
			target := game.state_scratch.targets[game.state_scratch.list_index]
			game.state_scratch.target_count = 1
			game.state_scratch.targets[0] = target

			use_item_on_whom_confirm_consumable_targets(game)
		} else {
			use_item_on_whom_confirm_spell(game)
		}
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .UseWhichItem)
	}
}

use_item_on_whom_confirm_consumable_targets :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	game_pkg.item_context_init(
		&game.contexts.item_context,
		current,
		game.state_scratch.targets[:game.state_scratch.target_count],
		&game.grid,
		game.contexts.prompt.item_slot_index,
	)

	game.battle_screen_mode = .ItemConsumable
	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
	game_pkg.grid_clear_range_set(&game.grid)

	state_change(game, .EnterBattleScreen)
}

use_item_on_whom_confirm_spell :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	slot := unit_pkg.item_at(current, game.contexts.prompt.item_slot_index)
	data := catalog.item_get(slot.name)
	magic := catalog.magic_get(data.spell_name)
	selected := game.state_scratch.targets[game.state_scratch.list_index]
	game_pkg.grid_calculate_spell_effect_range(&game.grid, selected, magic)
	aoe := game_pkg.grid_units_in_range(&game.grid)

	defer delete(aoe)

	game.state_scratch.target_count = 0
	for unit in aoe {
		if unit == nil {
			continue
		}

		if magic.offensive {
			if unit.friendly != current.friendly {
				use_item_on_whom_push_target(game, unit)
			}
		} else if unit.friendly == current.friendly {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	game_pkg.magic_context_init(
		&game.contexts.magic_context,
		current,
		game.state_scratch.targets[:game.state_scratch.target_count],
		&game.grid,
	)

	game_pkg.magic_context_cast(&game.contexts.magic_context, data.spell_name, true)
	unit_pkg.item_apply_spell_item_durability(current, game.contexts.prompt.item_slot_index)
	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
	game_pkg.grid_clear_range_set(&game.grid)
	game_pkg.prompt_reset(&game.contexts.prompt)

	state_change(game, .AnimateUnitDeaths)
}

use_item_on_whom_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)

	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

use_item_on_whom_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, true)
}
