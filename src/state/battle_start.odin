package state

import "core:log"

import game_pkg "../game"
import unit_pkg "../unit"
import rl "vendor:raylib"

import "../defs"
import "../sprites"
import "../timers"

// part 1 of 3: dissolve overworld map into battle background and lerp units into frame

@(private)
battle_friendly_start :: proc(base: rl.Vector2) -> rl.Vector2 {
	return {base.x + defs.BATTLE.slide_pixels, base.y}
}

@(private)
battle_unfriendly_start :: proc(base: rl.Vector2) -> rl.Vector2 {
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
@(private)
battle_foreground_position :: proc(eased: f32) -> rl.Vector2 {
	start := defs.BATTLE.positions.foreground
	start.x += defs.BATTLE.foreground_slide
	return sprites.renderer_vector_lerp(start, defs.BATTLE.positions.foreground, eased)
}

@(private)
battle_start_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	game.state_scratch.battle_item_mode = game.battle_screen_mode == .ItemConsumable
	game.state_scratch.battle_progress = 0
	timers.delay_init(&game.state_scratch.delay, defs.ANIMATIONS.idle_delay)
	if game.state_scratch.battle_item_mode && !game.contexts.item_context.active {
		log.errorf("EnterBattleScreen (item): ItemContext inactive.")
		state_change(game, .EndTurn)
	}
}

@(private)
battle_start_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
battle_start_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private)
battle_start_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

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

@(private)
battle_start_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	rl.ClearBackground(rl.BLACK)
	eased := sprites.renderer_ease_in_out(game.state_scratch.battle_progress)
	if game.state_scratch.battle_progress < 0.5 {
		alpha := int(255 * (1 - eased * 2))
		debug_draw := game.renderer.debug_draw
		sprites.renderer_draw_background(scale, &game.grid, alpha, debug_draw)
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
		caster_base := game.contexts.item_context.caster_sprites.base_position
		pos := sprites.renderer_vector_lerp(battle_friendly_start(caster_base), caster_base, slide)
		sprites.renderer_draw_unit_info_box(
			scale,
			caster,
			defs.BATTLE.positions.friendly_stats,
			alpha,
		)
		sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
		battle_draw_combatant(
			scale,
			caster,
			&game.contexts.item_context.caster_sprites,
			pos,
			alpha,
			game.state_scratch.delay.current_index,
			0,
			0,
			0,
			0,
			game.renderer.debug_draw,
		)
		return
	}

	if game.contexts.attack_context.active {
		monster_base := game.contexts.attack_context.monster_sprites.base_position
		force_base := game.contexts.attack_context.force_sprites.base_position
		unfriendly := sprites.renderer_vector_lerp(
			battle_unfriendly_start(monster_base),
			monster_base,
			slide,
		)
		friendly := sprites.renderer_vector_lerp(
			battle_friendly_start(force_base),
			force_base,
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
		idle_index := game.state_scratch.delay.current_index
		debug_draw := game.renderer.debug_draw
		battle_draw_combatant(
			scale,
			game_pkg.attack_context_monster(&game.contexts.attack_context),
			&game.contexts.attack_context.monster_sprites,
			unfriendly,
			alpha,
			idle_index,
			0,
			0,
			0,
			0,
			debug_draw,
		)
		sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
		battle_draw_combatant(
			scale,
			game_pkg.attack_context_force_member(&game.contexts.attack_context),
			&game.contexts.attack_context.force_sprites,
			friendly,
			alpha,
			idle_index,
			0,
			0,
			0,
			0,
			debug_draw,
		)
		return
	}

	sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
}
