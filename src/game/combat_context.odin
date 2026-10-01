package game

import "core:log"

import "../catalog"
import "../defs"
import "../sprites"
import unit_pkg "../unit"

Attack_Context :: struct {
	attacker, defender: ^unit_pkg.Unit,
	effect:             defs.Attack_Effect,
	hit, crit:          bool,
	damage:             int,
	damage_apply_frame: int,
	active:             bool,
	force_sprites:      sprites.Battle_Unit_Sprite_Set,
	monster_sprites:    sprites.Battle_Unit_Sprite_Set,
}

Item_Context :: struct {
	caster:          ^unit_pkg.Unit,
	targets:         [defs.MAX_CONTEXT_TARGETS]^unit_pkg.Unit,
	target_count:    int,
	grid:            ^Grid,
	item_slot_index: int,
	active:          bool,
	caster_sprites:  sprites.Battle_Unit_Sprite_Set,
}

Magic_Context :: struct {
	caster:       ^unit_pkg.Unit,
	targets:      [defs.MAX_CONTEXT_TARGETS]^unit_pkg.Unit,
	target_count: int,
	grid:         ^Grid,
	active:       bool,
}

@(private = "file")
context_copy_targets :: proc(dest: []^unit_pkg.Unit, dest_count: ^int, src: []^unit_pkg.Unit) {
	dest_count^ = 0
	for target in src {
		if target == nil {
			continue
		}

		if dest_count^ >= len(dest) {
			log.errorf(
				"context_copy_targets: overflow (%d targets, cap %d); truncating.",
				len(src),
				len(dest),
			)
			return
		}

		dest[dest_count^] = target
		dest_count^ += 1
	}
}

@(private = "file")
context_clear_targets :: proc(targets: []^unit_pkg.Unit, dest_count: ^int) {
	for i in 0 ..< len(targets) {
		targets[i] = nil
	}

	dest_count^ = 0
}

@(private)
attack_context_reset :: proc(ctx: ^Attack_Context) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	ctx.attacker = nil
	ctx.defender = nil
	ctx.effect = .NormalAttack
	ctx.hit = false
	ctx.crit = false
	ctx.damage = 0
	ctx.damage_apply_frame = 0
	ctx.active = false
	sprites.battle_unit_sprite_set_reset(&ctx.force_sprites)
	sprites.battle_unit_sprite_set_reset(&ctx.monster_sprites)
}

attack_context_init :: proc(
	ctx: ^Attack_Context,
	attacker, defender: ^unit_pkg.Unit,
	debug_draw := false,
) {
	if attacker == nil {
		log.panic("attacker is nil.")
	}

	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if defender == nil {
		log.panic("defender is nil.")
	}

	attack_context_reset(ctx)
	ctx.attacker = attacker
	ctx.defender = defender
	ctx.active = true
	ctx.damage_apply_frame = 0
	ctx.effect = unit_pkg.combat_attack_effect_for(attacker)
	result := unit_pkg.combat_calculate_attack_outcome(attacker, defender)
	ctx.hit = result.hit
	ctx.crit = result.crit
	ctx.damage = result.damage
	attack_context_assign_sprites(ctx, attacker, defender, debug_draw)
}

attack_context_monster :: proc(ctx: ^Attack_Context) -> ^unit_pkg.Unit {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if ctx.defender == nil {
		return ctx.attacker
	}

	if ctx.defender.friendly {
		return ctx.attacker
	}

	return ctx.defender
}

attack_context_force_member :: proc(ctx: ^Attack_Context) -> ^unit_pkg.Unit {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if ctx.defender == nil {
		return nil
	}

	if ctx.defender.friendly {
		return ctx.defender
	}

	return ctx.attacker
}

@(private)
attack_context_assign_sprites :: proc(
	ctx: ^Attack_Context,
	attacker, defender: ^unit_pkg.Unit,
	debug_draw: bool,
) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if attacker == nil {
		log.panic("attacker is nil.")
	}

	if defender == nil {
		log.panic("defender is nil.")
	}

	attacker_set: sprites.Battle_Unit_Sprite_Set
	defender_set: sprites.Battle_Unit_Sprite_Set
	if sprites.battle_sprites_ready() {
		attacker_set = sprites.battle_unit_sprite_set_load(attacker)
		defender_set = sprites.battle_unit_sprite_set_load(defender)
	}

	attacker_set.base_position = sprites.battle_sprite_position(
		attacker,
		defs.BATTLE.positions.friendly_standin if attacker.friendly else defs.BATTLE.positions.unfriendly_standin,
	)
	defender_set.base_position = sprites.battle_sprite_position(
		defender,
		defs.BATTLE.positions.friendly_standin if defender.friendly else defs.BATTLE.positions.unfriendly_standin,
	)
	if defender.friendly {
		ctx.force_sprites = defender_set
		ctx.monster_sprites = attacker_set
	} else {
		ctx.monster_sprites = defender_set
		ctx.force_sprites = attacker_set
	}

	if !sprites.battle_sprites_ready() {
		return
	}

	attacker_sprites := &ctx.force_sprites if attacker.friendly else &ctx.monster_sprites
	defender_sprites := &ctx.monster_sprites if attacker.friendly else &ctx.force_sprites
	killed := ctx.hit && defender.hp.current <= 0
	ctx.damage_apply_frame = sprites.battle_build_normal_attack_scene(
		attacker_sprites,
		defender_sprites,
		ctx.hit,
		killed,
		debug_draw,
	)
}

item_context_reset :: proc(ctx: ^Item_Context) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	ctx.caster = nil
	context_clear_targets(ctx.targets[:], &ctx.target_count)
	ctx.grid = nil
	ctx.item_slot_index = -1
	ctx.active = false
	sprites.battle_unit_sprite_set_reset(&ctx.caster_sprites)
}

item_context_init :: proc(
	ctx: ^Item_Context,
	caster: ^unit_pkg.Unit,
	targets: []^unit_pkg.Unit,
	grid: ^Grid,
	item_slot_index: int,
) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if caster == nil {
		log.panic("caster is nil.")
	}

	if grid == nil {
		log.panic("grid is nil.")
	}

	item_context_reset(ctx)
	ctx.caster = caster
	context_copy_targets(ctx.targets[:], &ctx.target_count, targets)
	ctx.grid = grid
	ctx.item_slot_index = item_slot_index
	ctx.active = true
	ctx.caster_sprites = sprites.battle_unit_sprite_set_load(caster)
	ctx.caster_sprites.base_position = sprites.battle_sprite_position(
		caster,
		defs.BATTLE.positions.friendly_standin if caster.friendly else defs.BATTLE.positions.unfriendly_standin,
	)
}

@(private)
item_context_target :: proc(ctx: ^Item_Context) -> ^unit_pkg.Unit {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if ctx.target_count > 0 {
		return ctx.targets[0]
	}

	return ctx.caster
}

@(private)
item_context_is_self_target :: proc(ctx: ^Item_Context) -> bool {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	return ctx.target_count == 1 && ctx.targets[0] == ctx.caster
}

@(private)
item_context_is_party_wide :: proc(ctx: ^Item_Context) -> bool {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	return ctx.target_count > 1
}

@(private)
item_context_use_item :: proc(ctx: ^Item_Context) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if !ctx.active || ctx.caster == nil {
		log.errorf("item_context_use_item: inactive context or nil caster.")
		return
	}

	slot := unit_pkg.item_at(ctx.caster, ctx.item_slot_index)
	if unit_pkg.item_slot_is_empty(slot) {
		log.errorf("item_context_use_item: empty or OOB slot [%d].", ctx.item_slot_index)
		return
	}

	unit_pkg.item_use_item(
		slot.name,
		ctx.caster,
		ctx.targets[:ctx.target_count],
		ctx.item_slot_index,
	)
}

@(private)
magic_context_reset :: proc(ctx: ^Magic_Context) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	ctx.caster = nil
	context_clear_targets(ctx.targets[:], &ctx.target_count)
	ctx.grid = nil
	ctx.active = false
}

magic_context_init :: proc(
	ctx: ^Magic_Context,
	caster: ^unit_pkg.Unit,
	targets: []^unit_pkg.Unit,
	grid: ^Grid,
) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if caster == nil {
		log.panic("caster is nil.")
	}

	if grid == nil {
		log.panic("grid is nil.")
	}

	magic_context_reset(ctx)
	ctx.caster = caster
	context_copy_targets(ctx.targets[:], &ctx.target_count, targets)
	ctx.grid = grid
	ctx.active = true
}

magic_context_cast :: proc(ctx: ^Magic_Context, name: defs.Magic_Name, from_item := false) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if !ctx.active || ctx.caster == nil {
		log.errorf("magic_context_cast: inactive context or nil caster.")
		return
	}

	unit_pkg.magic_cast(name, ctx.caster, ctx.targets[:ctx.target_count], from_item)
}

@(private = "file")
magic_context_cast_data :: proc(
	ctx: ^Magic_Context,
	data: catalog.Magic_Data,
	from_item := false,
) {
	if ctx == nil {
		log.panic("ctx is nil.")
	}

	if !ctx.active || ctx.caster == nil {
		log.errorf("magic_context_cast_data: inactive context or nil caster.")
		return
	}

	unit_pkg.magic_cast_data(data, ctx.caster, ctx.targets[:ctx.target_count], from_item)
}
