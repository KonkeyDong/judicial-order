package state

import game_pkg "../game"

import "core:log"

import "../catalog"
import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"
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
	eased := sprites.renderer_ease_in_out(progress)
	if eased <= 0.5 {
		return 0
	}

	return clamp((eased - 0.5) * 2, 0, 1)
}

// Somber-Inertia lerps the foreground with the full eased progress, not the unit slide.
battle_foreground_position :: proc(eased: f32) -> rl.Vector2 {
	start := defs.BATTLE.positions.foreground
	start.x += defs.BATTLE.foreground_slide
	return sprites.renderer_vector_lerp(start, defs.BATTLE.positions.foreground, eased)
}

enter_battle_screen_enter :: proc(game: ^game_pkg.Game) {
	game.state_scratch.battle_item_mode = game.battle_screen_mode == .ItemConsumable
	game.state_scratch.battle_progress = 0
	timers.delay_init(&game.state_scratch.delay, defs.ANIMATIONS.idle_delay)
	if game.state_scratch.battle_item_mode && !game.contexts.item_context.active {
		log.errorf("EnterBattleScreen (item): ItemContext inactive.")
		state_change(game, .EndTurn)
	}
}

enter_battle_screen_exit :: proc(_: ^game_pkg.Game) {}
enter_battle_screen_handle_input :: proc(_: ^game_pkg.Game) {}

enter_battle_screen_update :: proc(game: ^game_pkg.Game) {
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

	if game.renderer.debug_draw {
		state_change(game, .BattleResolutionDebug)
	} else {
		state_change(game, .BattleResolution)
	}
}

enter_battle_screen_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	eased := sprites.renderer_ease_in_out(game.state_scratch.battle_progress)
	if game.state_scratch.battle_progress < 0.5 {
		alpha := int(255 * (1 - eased * 2))
		debug_draw := game.renderer.debug_draw
		game_pkg.renderer_draw_background(scale, &game.grid, alpha, debug_draw)
		sprites.renderer_draw_units(
			scale,
			game.units[:],
			game.overworld_idle_flip_flop.is_on,
			alpha,
			debug_draw,
		)
		return
	}

	alpha := int(255 * ((eased - 0.5) * 2))
	slide := battle_slide_amount(game.state_scratch.battle_progress)
	foreground := battle_foreground_position(eased)
	sprites.renderer_draw_battle_background(scale, alpha)
	if game.state_scratch.battle_item_mode {
		caster := game.contexts.item_context.caster
		pos := sprites.renderer_vector_lerp(
			battle_friendly_start(),
			defs.BATTLE.positions.friendly_standin,
			slide,
		)
		sprites.renderer_draw_unit_info_box(
			scale,
			caster,
			defs.BATTLE.positions.friendly_stats,
			alpha,
		)
		sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
		sprites.renderer_draw_battle_standin(scale, caster, pos, alpha)
		return
	}

	if game.contexts.attack_context.active {
		unfriendly := sprites.renderer_vector_lerp(
			battle_unfriendly_start(),
			defs.BATTLE.positions.unfriendly_standin,
			slide,
		)
		friendly := sprites.renderer_vector_lerp(
			battle_friendly_start(),
			defs.BATTLE.positions.friendly_standin,
			slide,
		)
		sprites.renderer_draw_unit_info_box(
			scale,
			game_pkg.attack_context_monster(&game.contexts.attack_context),
			defs.BATTLE.positions.unfriendly_stats,
			alpha,
		)
		sprites.renderer_draw_unit_info_box(
			scale,
			game_pkg.attack_context_force_member(&game.contexts.attack_context),
			defs.BATTLE.positions.friendly_stats,
			alpha,
		)
		sprites.renderer_draw_battle_standin(
			scale,
			game_pkg.attack_context_monster(&game.contexts.attack_context),
			unfriendly,
			alpha,
		)
		sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
		sprites.renderer_draw_battle_standin(
			scale,
			game_pkg.attack_context_force_member(&game.contexts.attack_context),
			friendly,
			alpha,
		)
		return
	}

	sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
}

battle_resolution_enter :: proc(game: ^game_pkg.Game) {
	game.state_scratch.resolution_frame = 0
	timers.delay_init(&game.state_scratch.delay, defs.ANIMATIONS.idle_delay)
}

battle_resolution_exit :: proc(_: ^game_pkg.Game) {}
battle_resolution_handle_input :: proc(_: ^game_pkg.Game) {}

battle_resolution_update :: proc(game: ^game_pkg.Game) {
	timers.delay_tick(&game.state_scratch.delay)
	game.state_scratch.resolution_frame += 1
	if game.state_scratch.resolution_frame > defs.BATTLE.transition_frames {
		state_change(game, .ExitBattleScreen)
	}
}

battle_resolution_jitter :: proc(game: ^game_pkg.Game) -> int {
	if !game.contexts.attack_context.active || !game.contexts.attack_context.hit {
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

battle_resolution_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	sprites.renderer_draw_battle_background(scale, 255)
	sprites.renderer_draw_battle_foreground(scale, defs.BATTLE.positions.foreground, 255)
	if !game.contexts.attack_context.active {
		return
	}

	monster := game_pkg.attack_context_monster(&game.contexts.attack_context)
	force := game_pkg.attack_context_force_member(&game.contexts.attack_context)
	sprites.renderer_draw_unit_info_box(scale, monster, defs.BATTLE.positions.unfriendly_stats)
	sprites.renderer_draw_unit_info_box(scale, force, defs.BATTLE.positions.friendly_stats)
	jitter := battle_resolution_jitter(game)
	unfriendly := defs.BATTLE.positions.unfriendly_standin
	friendly := defs.BATTLE.positions.friendly_standin
	if game.state_scratch.resolution_frame < defs.BATTLE.attack_pose_frames {
		friendly.x -= 8
		unfriendly.x += 8
	}

	if monster != nil && !unit_pkg.is_dead(monster) {
		sprites.renderer_draw_battle_standin(scale, monster, unfriendly, 255, jitter)
	}

	if force != nil && !unit_pkg.is_dead(force) {
		sprites.renderer_draw_battle_standin(scale, force, friendly, 255)
	}
}

battle_resolution_debug_enter :: proc(game: ^game_pkg.Game) {
	game.state_scratch.resolution_frame = 0
}

battle_resolution_debug_exit :: proc(_: ^game_pkg.Game) {}

battle_resolution_debug_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_key_pressed(.RIGHT) {
		game.state_scratch.resolution_frame += 1
	}

	if game_pkg.input_key_pressed(.LEFT) {
		game.state_scratch.resolution_frame = max(0, game.state_scratch.resolution_frame - 1)
	}

	if game_pkg.input_confirm_press() || game_pkg.input_cancel_press() {
		state_change(game, .ExitBattleScreen)
	}
}

battle_resolution_debug_update :: proc(_: ^game_pkg.Game) {}
battle_resolution_debug_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	battle_resolution_draw(game, scale)
}

exit_battle_screen_enter :: proc(game: ^game_pkg.Game) {
	game.state_scratch.battle_progress = 0
	game.state_scratch.battle_item_mode = game.battle_screen_mode == .ItemConsumable
}

exit_battle_screen_exit :: proc(_: ^game_pkg.Game) {}
exit_battle_screen_handle_input :: proc(_: ^game_pkg.Game) {}

exit_battle_screen_update :: proc(game: ^game_pkg.Game) {
	timers.delay_tick(&game.state_scratch.delay)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	if game.state_scratch.battle_progress < 1 {
		game.state_scratch.battle_progress += 1 / f32(defs.BATTLE.transition_frames)
		game.state_scratch.battle_progress = min(1, game.state_scratch.battle_progress)
		return
	}

	if game.state_scratch.battle_item_mode {
		game_pkg.item_context_reset(&game.contexts.item_context)
		game.battle_screen_mode = .Combat
		state_change(game, .EndTurn)
	} else {
		state_change(game, .AnimateUnitDeaths)
	}
}

exit_battle_screen_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	eased := sprites.renderer_ease_in_out(game.state_scratch.battle_progress)
	if game.state_scratch.battle_progress < 0.5 {
		alpha := int(255 * (1 - eased * 2))
		foreground := defs.BATTLE.positions.foreground
		sprites.renderer_draw_battle_background(scale, alpha)
		if game.state_scratch.battle_item_mode {
			sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
			sprites.renderer_draw_battle_standin(
				scale,
				game.contexts.item_context.caster,
				defs.BATTLE.positions.friendly_standin,
				alpha,
			)
			sprites.renderer_draw_unit_info_box(
				scale,
				game.contexts.item_context.caster,
				defs.BATTLE.positions.friendly_stats,
				alpha,
			)
		} else if game.contexts.attack_context.active {
			sprites.renderer_draw_battle_standin(
				scale,
				game_pkg.attack_context_monster(&game.contexts.attack_context),
				defs.BATTLE.positions.unfriendly_standin,
				alpha,
			)
			sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
			sprites.renderer_draw_battle_standin(
				scale,
				game_pkg.attack_context_force_member(&game.contexts.attack_context),
				defs.BATTLE.positions.friendly_standin,
				alpha,
			)
		} else {
			sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
		}
		return
	}

	alpha := int(255 * ((eased - 0.5) * 2))
	debug_draw := game.renderer.debug_draw
	game_pkg.renderer_draw_background(scale, &game.grid, alpha, debug_draw)
	sprites.renderer_draw_units(
		scale,
		game.units[:],
		game.overworld_idle_flip_flop.is_on,
		alpha,
		debug_draw,
	)
}

use_consumable_battle_enter :: proc(game: ^game_pkg.Game) {
	if !game.contexts.item_context.active || game.contexts.item_context.caster == nil {
		log.errorf("UseConsumableBattle: ItemContext inactive. Exiting to EndTurn.")
		state_change(game, .EndTurn)
		return
	}

	slot := unit_pkg.item_at(
		game.contexts.item_context.caster,
		game.contexts.item_context.item_slot_index,
	)
	data := catalog.item_get(slot.name)
	for i in 0 ..< game.contexts.item_context.target_count {
		unit_pkg.item_apply_consumable_to_target(
			data,
			game.contexts.item_context.caster,
			game.contexts.item_context.targets[i],
		)
	}

	unit_pkg.item_consume_item(
		game.contexts.item_context.caster,
		game.contexts.item_context.item_slot_index,
	)
	game.state_scratch.battle_progress = 0
	game.state_scratch.resolution_frame = 0
}

use_consumable_battle_exit :: proc(_: ^game_pkg.Game) {}
use_consumable_battle_handle_input :: proc(_: ^game_pkg.Game) {}

use_consumable_battle_update :: proc(game: ^game_pkg.Game) {
	game.state_scratch.resolution_frame += 1
	game.state_scratch.battle_progress += 1 / f32(defs.BATTLE.transition_frames)
	if game.state_scratch.battle_progress >= 1 {
		state_change(game, .ExitBattleScreen)
	}
}

use_consumable_battle_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	rl.ClearBackground(rl.BLACK)
	sprites.renderer_draw_battle_background(scale, 255)
	sprites.renderer_draw_battle_foreground(scale, defs.BATTLE.positions.foreground, 255)
	caster := game.contexts.item_context.caster
	sprites.renderer_draw_battle_standin(scale, caster, defs.BATTLE.positions.friendly_standin)
	sprites.renderer_draw_unit_info_box(scale, caster, defs.BATTLE.positions.friendly_stats)
	if game.contexts.item_context.target_count > 0 {
		target := game.contexts.item_context.targets[0]
		if target != nil && target != caster {
			sprites.renderer_draw_battle_standin(
				scale,
				target,
				defs.BATTLE.positions.unfriendly_standin,
			)
			sprites.renderer_draw_unit_info_box(
				scale,
				target,
				defs.BATTLE.positions.unfriendly_stats,
			)
		}
	}
}
