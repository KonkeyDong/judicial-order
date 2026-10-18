package state

import "core:log"

import game_pkg "../game"
import unit_pkg "../unit"
import rl "vendor:raylib"

import "../defs"
import "../sprites"
import "../timers"

// part 3 of 3: dissolve battle background back into overworld

@(private)
battle_end_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	game.state_scratch.battle_progress = 0
	game.state_scratch.battle_item_mode = game.battle_screen_mode == .ItemConsumable
}

@(private)
battle_end_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
battle_end_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private)
battle_end_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

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

@(private)
battle_end_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	rl.ClearBackground(rl.BLACK)
	eased := sprites.renderer_ease_in_out(game.state_scratch.battle_progress)
	if game.state_scratch.battle_progress < 0.5 {
		alpha := int(255 * (1 - eased * 2))
		foreground := defs.BATTLE.positions.foreground
		sprites.renderer_draw_battle_background(scale, alpha)
		idle_index := game.state_scratch.delay.current_index
		debug_draw := game.renderer.debug_draw
		if game.state_scratch.battle_item_mode {
			sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
			battle_draw_combatant(
				scale,
				game.contexts.item_context.caster,
				&game.contexts.item_context.caster_sprites,
				game.contexts.item_context.caster_sprites.base_position,
				alpha,
				idle_index,
				0,
				0,
				0,
				0,
				debug_draw,
			)
			sprites.renderer_draw_unit_info_box(
				scale,
				game.contexts.item_context.caster,
				defs.BATTLE.positions.friendly_stats,
				alpha,
			)
		} else if game.contexts.attack_context.active {
			battle_draw_combatant(
				scale,
				game_pkg.attack_context_monster(&game.contexts.attack_context),
				&game.contexts.attack_context.monster_sprites,
				game.contexts.attack_context.monster_sprites.base_position,
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
				game.contexts.attack_context.force_sprites.base_position,
				alpha,
				idle_index,
				0,
				0,
				0,
				0,
				debug_draw,
			)
		} else {
			sprites.renderer_draw_battle_foreground(scale, foreground, alpha)
		}
		return
	}

	alpha := int(255 * ((eased - 0.5) * 2))
	debug_draw := game.renderer.debug_draw
	sprites.renderer_draw_background(scale, &game.grid, alpha, debug_draw)
	sprites.renderer_draw_units(
		scale,
		game.units[:],
		game.overworld_idle_flip_flop.is_on,
		alpha,
		debug_draw,
	)
}
