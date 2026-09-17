package game

import "core:log"

import "catalog"
import "defs"
import "timers"
import unit_pkg "unit"
import rl "vendor:raylib"

enter_battle_screen_enter :: proc(game: ^Game) {
	game.state_scratch.battle_item_mode = game.battle_screen_mode == .ItemConsumable
	game.state_scratch.battle_progress = 0
	if game.state_scratch.battle_item_mode && !game.item_context.active {
		log.errorf("EnterBattleScreen (item): ItemContext inactive.")
		state_change(game, .EndTurn)
	}
}

enter_battle_screen_exit :: proc(_: ^Game) {}
enter_battle_screen_handle_input :: proc(_: ^Game) {}

enter_battle_screen_update :: proc(game: ^Game) {
	timers.delay_tick(&game.state_scratch.delay)
	if game.state_scratch.battle_progress < 1 {
		game.state_scratch.battle_progress += 1 / f32(defs.BATTLE.transition_frames)
		game.state_scratch.battle_progress = min(1, game.state_scratch.battle_progress)
		return
	}

	if game.state_scratch.battle_item_mode {
		state_change(game, .UseConsumableBattle)
		return
	}

	if program_log_in_debug_mode() {
		state_change(game, .BattleResolutionDebug)
	} else {
		state_change(game, .BattleResolution)
	}
}

enter_battle_screen_draw :: proc(game: ^Game, scale: f32) {
	eased := renderer_ease_in_out(game.state_scratch.battle_progress)
	if game.state_scratch.battle_progress < 0.5 {
		alpha := int(255 * (1 - eased * 2))
		debug_draw := game.renderer.debug_draw
		renderer_draw_background(scale, &game.grid, alpha, debug_draw)
		renderer_draw_units(scale, game.units[:], game.flip_flop.is_on, alpha, debug_draw)
	} else {
		rl.ClearBackground(rl.BLACK)
		if game.attack_context.active {
			renderer_draw_unit_info_box(
				scale,
				attack_context_monster(&game.attack_context),
				defs.BATTLE.positions.unfriendly_stats,
			)
			renderer_draw_unit_info_box(
				scale,
				attack_context_force_member(&game.attack_context),
				defs.BATTLE.positions.friendly_stats,
			)
		}
	}
}

battle_resolution_enter :: proc(game: ^Game) {
	game.state_scratch.resolution_frame = 0
	timers.delay_init(&game.state_scratch.delay, defs.ANIMATIONS.idle_delay)
}

battle_resolution_exit :: proc(_: ^Game) {}
battle_resolution_handle_input :: proc(_: ^Game) {}

battle_resolution_update :: proc(game: ^Game) {
	timers.delay_tick(&game.state_scratch.delay)
	game.state_scratch.resolution_frame += 1
	if game.state_scratch.resolution_frame > defs.BATTLE.transition_frames {
		state_change(game, .ExitBattleScreen)
	}
}

battle_resolution_draw :: proc(game: ^Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	if game.attack_context.active {
		renderer_draw_unit_info_box(
			scale,
			attack_context_monster(&game.attack_context),
			defs.BATTLE.positions.unfriendly_stats,
		)
		renderer_draw_unit_info_box(
			scale,
			attack_context_force_member(&game.attack_context),
			defs.BATTLE.positions.friendly_stats,
		)
	}
}

battle_resolution_debug_enter :: proc(game: ^Game) {
	game.state_scratch.resolution_frame = 0
}

battle_resolution_debug_exit :: proc(_: ^Game) {}

battle_resolution_debug_handle_input :: proc(game: ^Game) {
	if input_key_pressed(.RIGHT) {
		game.state_scratch.resolution_frame += 1
	}

	if input_key_pressed(.LEFT) {
		game.state_scratch.resolution_frame = max(0, game.state_scratch.resolution_frame - 1)
	}

	if input_confirm_press() || input_cancel_press() {
		state_change(game, .ExitBattleScreen)
	}
}

battle_resolution_debug_update :: proc(_: ^Game) {}
battle_resolution_debug_draw :: proc(game: ^Game, scale: f32) {
	battle_resolution_draw(game, scale)
}

exit_battle_screen_enter :: proc(game: ^Game) {
	game.state_scratch.battle_progress = 0
	game.state_scratch.battle_item_mode = game.battle_screen_mode == .ItemConsumable
}

exit_battle_screen_exit :: proc(_: ^Game) {}
exit_battle_screen_handle_input :: proc(_: ^Game) {}

exit_battle_screen_update :: proc(game: ^Game) {
	timers.delay_tick(&game.state_scratch.delay)
	timers.flip_flop_tick(&game.flip_flop)
	if game.state_scratch.battle_progress < 1 {
		game.state_scratch.battle_progress += 1 / f32(defs.BATTLE.transition_frames)
		game.state_scratch.battle_progress = min(1, game.state_scratch.battle_progress)
		return
	}

	if game.state_scratch.battle_item_mode {
		item_context_reset(&game.item_context)
		game.battle_screen_mode = .Combat
		state_change(game, .EndTurn)
	} else {
		state_change(game, .AnimateUnitDeaths)
	}
}

exit_battle_screen_draw :: proc(game: ^Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	_ = game
	_ = scale
}

use_consumable_battle_enter :: proc(game: ^Game) {
	if !game.item_context.active || game.item_context.caster == nil {
		log.errorf("UseConsumableBattle: ItemContext inactive. Exiting to EndTurn.")
		state_change(game, .EndTurn)
		return
	}

	slot := unit_pkg.item_at(game.item_context.caster, game.item_context.item_slot_index)
	data := catalog.item_get(slot.name)
	for i in 0 ..< game.item_context.target_count {
		unit_pkg.item_apply_consumable_to_target(
			data,
			game.item_context.caster,
			game.item_context.targets[i],
		)
	}

	unit_pkg.item_consume_item(game.item_context.caster, game.item_context.item_slot_index)
	game.state_scratch.battle_progress = 0
}

use_consumable_battle_exit :: proc(_: ^Game) {}
use_consumable_battle_handle_input :: proc(_: ^Game) {}

use_consumable_battle_update :: proc(game: ^Game) {
	game.state_scratch.battle_progress += 1 / f32(defs.BATTLE.transition_frames)
	if game.state_scratch.battle_progress >= 1 {
		state_change(game, .ExitBattleScreen)
	}
}

use_consumable_battle_draw :: proc(game: ^Game, scale: f32) {
	battle_resolution_draw(game, scale)
}
