package state

import "core:log"

import game_pkg "../game"
import unit_pkg "../unit"
import rl "vendor:raylib"

import "../defs"
import "../sprites"
import "../timers"

// part 2 of 3 of battle: the attacking animations

@(private = "file")
battle_sequence_limit :: proc(game: ^game_pkg.Game) -> int {
	if game == nil {
		log.panic("game is nil.")
	}

	if !game.contexts.attack_context.active {
		return 0
	}

	return max(
		len(game.contexts.attack_context.force_sprites.battle_sequence),
		len(game.contexts.attack_context.monster_sprites.battle_sequence),
	)
}

@(private)
battle_resolution_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	game.state_scratch.resolution_frame = 0
	timers.delay_init(&game.state_scratch.delay, defs.ANIMATIONS.idle_delay)
}

@(private)
battle_resolution_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
battle_resolution_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private)
battle_resolution_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	timers.delay_tick(&game.state_scratch.delay)
	game.state_scratch.resolution_frame += 1
	limit := battle_sequence_limit(game)
	hold := defs.BATTLE.transition_frames
	if limit > 0 {
		if game.state_scratch.resolution_frame > limit + hold {
			state_change(game, .ExitBattleScreen)
		}

		return
	}

	if game.state_scratch.resolution_frame > hold {
		state_change(game, .ExitBattleScreen)
	}
}

@(private)
battle_resolution_jitter :: proc(game: ^game_pkg.Game) -> int {
	if game == nil {
		log.panic("game is nil.")
	}

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

@(private)
battle_resolution_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

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
	frame := game.state_scratch.resolution_frame
	standin_dx := f32(0)
	jitter := 0
	if frame < defs.BATTLE.attack_pose_frames {
		standin_dx = 8
		jitter = battle_resolution_jitter(game)
	}

	limit := battle_sequence_limit(game)
	idle_index := game.state_scratch.delay.current_index
	debug_draw := game.renderer.debug_draw
	if monster != nil && !unit_pkg.is_dead(monster) {
		battle_draw_combatant(
			scale,
			monster,
			&game.contexts.attack_context.monster_sprites,
			game.contexts.attack_context.monster_sprites.base_position,
			255,
			idle_index,
			frame,
			limit,
			standin_dx,
			jitter,
			debug_draw,
		)
	}

	if force != nil && !unit_pkg.is_dead(force) {
		battle_draw_combatant(
			scale,
			force,
			&game.contexts.attack_context.force_sprites,
			game.contexts.attack_context.force_sprites.base_position,
			255,
			idle_index,
			frame,
			limit,
			-standin_dx,
			0,
			debug_draw,
		)
	}
}

@(private)
battle_resolution_debug_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	game.state_scratch.resolution_frame = 0
}

@(private)
battle_resolution_debug_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private)
battle_resolution_debug_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

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

@(private)
battle_resolution_debug_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
battle_resolution_debug_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	battle_resolution_draw(game, scale)
}
