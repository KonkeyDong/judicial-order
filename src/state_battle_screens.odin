package game

import "core:log"

import "catalog"
import "defs"
import "timers"
import unit_pkg "unit"
import rl "vendor:raylib"

battle_friendly_start :: proc() -> rl.Vector2 {
	base := defs.BATTLE.positions.friendly_standin
	return {base.x + defs.BATTLE.slide_pixels, base.y}
}

battle_unfriendly_start :: proc() -> rl.Vector2 {
	base := defs.BATTLE.positions.unfriendly_standin
	return {base.x - defs.BATTLE.slide_pixels, base.y}
}

battle_slide_amount :: proc(progress: f32) -> f32 {
	eased := renderer_ease_in_out(progress)
	if eased <= 0.5 {
		return 0
	}

	return clamp((eased - 0.5) * 2, 0, 1)
}

enter_battle_screen_enter :: proc(game: ^Game) {
	game.state_scratch.battle_item_mode = game.battle_screen_mode == .ItemConsumable
	game.state_scratch.battle_progress = 0
	timers.delay_init(&game.state_scratch.delay, defs.ANIMATIONS.idle_delay)
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
	rl.ClearBackground(rl.BLACK)
	eased := renderer_ease_in_out(game.state_scratch.battle_progress)
	if game.state_scratch.battle_progress < 0.5 {
		alpha := int(255 * (1 - eased * 2))
		debug_draw := game.renderer.debug_draw
		renderer_draw_background(scale, &game.grid, alpha, debug_draw)
		renderer_draw_units(scale, game.units[:], game.flip_flop.is_on, alpha, debug_draw)
		return
	}

	alpha := int(255 * ((eased - 0.5) * 2))
	slide := battle_slide_amount(game.state_scratch.battle_progress)
	renderer_draw_battle_ground(scale, alpha)
	if game.state_scratch.battle_item_mode {
		caster := game.item_context.caster
		pos := renderer_vector_lerp(
			battle_friendly_start(),
			defs.BATTLE.positions.friendly_standin,
			slide,
		)
		renderer_draw_battle_standin(scale, caster, pos, alpha)
		renderer_draw_unit_info_box(scale, caster, defs.BATTLE.positions.friendly_stats, alpha)
		return
	}

	if game.attack_context.active {
		unfriendly := renderer_vector_lerp(
			battle_unfriendly_start(),
			defs.BATTLE.positions.unfriendly_standin,
			slide,
		)
		friendly := renderer_vector_lerp(
			battle_friendly_start(),
			defs.BATTLE.positions.friendly_standin,
			slide,
		)
		renderer_draw_unit_info_box(
			scale,
			attack_context_monster(&game.attack_context),
			defs.BATTLE.positions.unfriendly_stats,
			alpha,
		)
		renderer_draw_unit_info_box(
			scale,
			attack_context_force_member(&game.attack_context),
			defs.BATTLE.positions.friendly_stats,
			alpha,
		)
		renderer_draw_battle_standin(
			scale,
			attack_context_monster(&game.attack_context),
			unfriendly,
			alpha,
		)
		renderer_draw_battle_standin(
			scale,
			attack_context_force_member(&game.attack_context),
			friendly,
			alpha,
		)
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

battle_resolution_jitter :: proc(game: ^Game) -> int {
	if !game.attack_context.active || !game.attack_context.hit {
		return 0
	}

	if game.state_scratch.resolution_frame >= defs.BATTLE.attack_pose_frames {
		return 0
	}

	if (game.state_scratch.resolution_frame / 2) % 2 == 0 {
		return defs.ANIMATIONS.jitter_offset
	}

	return -defs.ANIMATIONS.jitter_offset
}

battle_resolution_draw :: proc(game: ^Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	renderer_draw_battle_ground(scale, 255)
	if !game.attack_context.active {
		return
	}

	monster := attack_context_monster(&game.attack_context)
	force := attack_context_force_member(&game.attack_context)
	renderer_draw_unit_info_box(scale, monster, defs.BATTLE.positions.unfriendly_stats)
	renderer_draw_unit_info_box(scale, force, defs.BATTLE.positions.friendly_stats)
	jitter := battle_resolution_jitter(game)
	unfriendly := defs.BATTLE.positions.unfriendly_standin
	friendly := defs.BATTLE.positions.friendly_standin
	if game.state_scratch.resolution_frame < defs.BATTLE.attack_pose_frames {
		friendly.x -= 8
		unfriendly.x += 8
	}

	if monster != nil && !unit_pkg.is_dead(monster) {
		renderer_draw_battle_standin(scale, monster, unfriendly, 255, jitter)
	}

	if force != nil && !unit_pkg.is_dead(force) {
		renderer_draw_battle_standin(scale, force, friendly, 255)
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
	eased := renderer_ease_in_out(game.state_scratch.battle_progress)
	if game.state_scratch.battle_progress < 0.5 {
		alpha := int(255 * (1 - eased * 2))
		renderer_draw_battle_ground(scale, alpha)
		if game.state_scratch.battle_item_mode {
			renderer_draw_battle_standin(
				scale,
				game.item_context.caster,
				defs.BATTLE.positions.friendly_standin,
				alpha,
			)
			renderer_draw_unit_info_box(
				scale,
				game.item_context.caster,
				defs.BATTLE.positions.friendly_stats,
				alpha,
			)
		} else if game.attack_context.active {
			renderer_draw_battle_standin(
				scale,
				attack_context_monster(&game.attack_context),
				defs.BATTLE.positions.unfriendly_standin,
				alpha,
			)
			renderer_draw_battle_standin(
				scale,
				attack_context_force_member(&game.attack_context),
				defs.BATTLE.positions.friendly_standin,
				alpha,
			)
		}
		return
	}

	alpha := int(255 * ((eased - 0.5) * 2))
	debug_draw := game.renderer.debug_draw
	renderer_draw_background(scale, &game.grid, alpha, debug_draw)
	renderer_draw_units(scale, game.units[:], game.flip_flop.is_on, alpha, debug_draw)
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
	game.state_scratch.resolution_frame = 0
}

use_consumable_battle_exit :: proc(_: ^Game) {}
use_consumable_battle_handle_input :: proc(_: ^Game) {}

use_consumable_battle_update :: proc(game: ^Game) {
	game.state_scratch.resolution_frame += 1
	game.state_scratch.battle_progress += 1 / f32(defs.BATTLE.transition_frames)
	if game.state_scratch.battle_progress >= 1 {
		state_change(game, .ExitBattleScreen)
	}
}

use_consumable_battle_draw :: proc(game: ^Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	renderer_draw_battle_ground(scale, 255)
	caster := game.item_context.caster
	renderer_draw_battle_standin(scale, caster, defs.BATTLE.positions.friendly_standin)
	renderer_draw_unit_info_box(scale, caster, defs.BATTLE.positions.friendly_stats)
	if game.item_context.target_count > 0 {
		target := game.item_context.targets[0]
		if target != nil && target != caster {
			renderer_draw_battle_standin(scale, target, defs.BATTLE.positions.unfriendly_standin)
			renderer_draw_unit_info_box(scale, target, defs.BATTLE.positions.unfriendly_stats)
		}
	}
}
