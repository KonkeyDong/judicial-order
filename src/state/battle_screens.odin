package state

import "core:log"

import game_pkg "../game"
import unit_pkg "../unit"
import rl "vendor:raylib"

import "../catalog"
import "../defs"
import "../sprites"
import "../timers"

// TODO: remove this file

// Idle sheet when one is loaded. Sequence frames while the shared timeline is playing.
// A missing sheet keeps the colored stand-in, including its lunge and jitter.
@(private)
battle_draw_combatant :: proc(
	scale: f32,
	unit: ^unit_pkg.Unit,
	set: ^sprites.Battle_Unit_Sprite_Set,
	position: rl.Vector2,
	alpha: int,
	idle_index, sequence_index, sequence_limit: int,
	standin_dx: f32,
	standin_jitter: int,
	debug_draw: bool,
) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	if set == nil {
		log.panic("set is nil.")
	}

	playing :=
		sequence_limit > 0 && sequence_index < sequence_limit && len(set.battle_sequence) > 0
	if playing {
		if sprite, ok := sprites.battle_sequence_frame(set, sequence_index); ok {
			sprites.renderer_draw(scale, sprite, position, alpha, debug_draw)
			return
		}
	}

	if sprite, ok := sprites.battle_idle_frame(set, idle_index); ok {
		sprites.renderer_draw(scale, sprite, position, alpha, debug_draw)
		return
	}

	standin := position
	standin.x += standin_dx
	sprites.renderer_draw_battle_standin(scale, unit, standin, alpha, standin_jitter)
}


@(private)
use_consumable_battle_enter :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

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

@(private)
use_consumable_battle_exit :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}
@(private)
use_consumable_battle_handle_input :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}
}

@(private)
use_consumable_battle_update :: proc(game: ^game_pkg.Game) {
	if game == nil {
		log.panic("game is nil.")
	}

	timers.delay_tick(&game.state_scratch.delay)
	game.state_scratch.resolution_frame += 1
	game.state_scratch.battle_progress += 1 / f32(defs.BATTLE.transition_frames)
	if game.state_scratch.battle_progress >= 1 {
		state_change(game, .ExitBattleScreen)
	}
}

@(private)
use_consumable_battle_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	if game == nil {
		log.panic("game is nil.")
	}

	rl.ClearBackground(rl.BLACK)
	sprites.renderer_draw_battle_background(scale, 255)
	sprites.renderer_draw_battle_foreground(scale, defs.BATTLE.positions.foreground, 255)
	caster := game.contexts.item_context.caster
	idle_index := game.state_scratch.delay.current_index
	debug_draw := game.renderer.debug_draw
	battle_draw_combatant(
		scale,
		caster,
		&game.contexts.item_context.caster_sprites,
		game.contexts.item_context.caster_sprites.base_position,
		255,
		idle_index,
		0,
		0,
		0,
		0,
		debug_draw,
	)
	sprites.renderer_draw_unit_info_box(scale, caster, defs.BATTLE.positions.friendly_stats)
	if game.contexts.item_context.target_count > 0 {
		target := game.contexts.item_context.targets[0]
		if target != nil && target != caster {
			sprites.renderer_draw_battle_standin(
				scale,
				target,
				sprites.battle_sprite_position(target, defs.BATTLE.positions.unfriendly_standin),
			)
			sprites.renderer_draw_unit_info_box(
				scale,
				target,
				defs.BATTLE.positions.unfriendly_stats,
			)
		}
	}
}
