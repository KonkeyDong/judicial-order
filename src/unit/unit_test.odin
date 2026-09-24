package unit

import "core:testing"

import "../catalog"
import "../defs"

test_data_hale :: proc() -> Unit_Data {
	return Unit_Data {
		name = .Hale,
		movement_type = .Warrior,
		movement = 6,
		base_hp = 15,
		base_mp = 8,
		base_attack = 10,
		base_defense = 5,
		base_speed = 5,
		friendly = true,
		level = 1,
		default_job = {.Swordsman},
		attack_effect = .NormalAttack,
	}
}

test_data_judy :: proc() -> Unit_Data {
	return Unit_Data {
		name = .Judy,
		movement_type = .Warrior,
		movement = 5,
		base_hp = 10,
		base_mp = 12,
		base_attack = 3,
		base_defense = 4,
		base_speed = 6,
		friendly = true,
		level = 1,
		default_job = {.Mage},
		attack_effect = .NormalAttack,
	}
}

@(test)
test_add_remove_equipped_shift :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	testing.expect(test, add_item(unit, .SmallBriefcase, auto_equip_weapon = true))
	testing.expect(test, add_item(unit, .Hotdog))
	testing.expect(test, add_item(unit, .SmallBriefcase))
	testing.expect_value(test, unit.equipped_weapon_index, 0)
	testing.expect(test, remove_item_at(unit, 0))
	testing.expect_value(test, unit.equipped_weapon_index, defs.UNARMED_INDEX)
	testing.expect_value(test, unit.items[0].name, defs.Item_Name.Hotdog)
}

@(test)
test_swap_unequips_and_does_not_re_equip :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)

	testing.expect(test, add_item(hale, .SmallBriefcase, auto_equip_weapon = true))
	testing.expect(test, add_item(judy, .Hotdog))
	testing.expect_value(test, hale.equipped_weapon_index, 0)
	testing.expect(test, swap_item_with(hale, judy, 0, 0))
	testing.expect_value(test, hale.equipped_weapon_index, defs.UNARMED_INDEX)
	testing.expect_value(test, judy.equipped_weapon_index, defs.UNARMED_INDEX)
	testing.expect_value(test, hale.items[0].name, defs.Item_Name.Hotdog)
	testing.expect_value(test, judy.items[0].name, defs.Item_Name.SmallBriefcase)
}

@(test)
test_reject_unarmed_and_full_add :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	testing.expect(test, !add_item(unit, .Unarmed))
	testing.expect(test, add_item(unit, .SmallBriefcase))
	testing.expect(test, add_item(unit, .Hotdog))
	testing.expect(test, add_item(unit, .SmallBriefcase))
	testing.expect(test, add_item(unit, .Hotdog))
	testing.expect(test, !add_item(unit, .SmallBriefcase))
}

@(test)
test_damage_heal_clamp :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	take_damage(unit, 100)
	testing.expect_value(test, unit.hp.current, 0)
	testing.expect(test, is_dead(unit))
	actual := heal(unit, 4)
	testing.expect_value(test, actual, 4)
	testing.expect_value(test, unit.hp.current, 4)
	over := heal(unit, 100)
	testing.expect_value(test, over, 11)
	testing.expect_value(test, unit.hp.current, 15)
	testing.expect_value(test, heal(unit, -5), 0)
}

@(test)
test_poison_damage :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Poison)
	process_poison(unit)
	testing.expect_value(test, unit.hp.current, 13)
}

@(test)
test_sleep_expires :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Sleep)
	testing.expect(test, has_status(unit, .Sleep))
	for _ in 0 ..< defs.STATUS_EFFECTS.base_duration + 1 {
		process_sleep(unit)
	}

	testing.expect(test, !has_status(unit, .Sleep))
}

@(test)
test_status_durations :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Poison)
	testing.expect_value(test, status_duration(unit, .Poison), defs.STATUS_EFFECTS.permanent_duration)
	apply_status(unit, .Blind)
	testing.expect_value(test, status_duration(unit, .Blind), defs.STATUS_EFFECTS.permanent_duration)
	apply_status(unit, .Shield)
	testing.expect_value(test, status_duration(unit, .Shield), defs.STATUS_EFFECTS.base_duration)
	apply_status(unit, .Boost)
	testing.expect_value(test, status_duration(unit, .Boost), defs.STATUS_EFFECTS.base_duration)
	apply_status(unit, .Quick)
	testing.expect_value(test, status_duration(unit, .Quick), defs.STATUS_EFFECTS.base_duration)
	apply_status(unit, .Muddle)
	testing.expect_value(test, status_duration(unit, .Muddle), defs.STATUS_EFFECTS.base_duration)

	other := make(test_data_judy())
	defer destroy(other)
	apply_status(other, .Slow)
	testing.expect_value(test, status_duration(other, .Slow), defs.STATUS_EFFECTS.base_duration)

	apply_status(unit, .Sleep)
	sleep_duration := status_duration(unit, .Sleep)
	testing.expect(test, sleep_duration >= 0)
	testing.expect(test, sleep_duration < defs.STATUS_EFFECTS.base_duration)
}

@(test)
test_status_duplicate_ignored :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Boost)
	apply_status(unit, .Boost)
	testing.expect_value(test, unit.status_count, 1)
	testing.expect(test, has_status(unit, .Boost))
}

@(test)
test_quick_replaces_slow :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Slow)
	apply_status(unit, .Quick)
	testing.expect_value(test, unit.status_count, 1)
	testing.expect(test, has_status(unit, .Quick))
	testing.expect(test, !has_status(unit, .Slow))
}

@(test)
test_slow_replaces_quick :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Quick)
	apply_status(unit, .Slow)
	testing.expect_value(test, unit.status_count, 1)
	testing.expect(test, has_status(unit, .Slow))
	testing.expect(test, !has_status(unit, .Quick))
}

@(test)
test_quick_duplicate_does_not_remove :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Quick)
	duration := status_duration(unit, .Quick)
	apply_status(unit, .Quick)
	testing.expect_value(test, unit.status_count, 1)
	testing.expect(test, has_status(unit, .Quick))
	testing.expect_value(test, status_duration(unit, .Quick), duration)
}

@(test)
test_status_full_rejects :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	unit.status_count = defs.MAX_STATUS_EFFECTS
	apply_status(unit, .Muddle)
	testing.expect_value(test, unit.status_count, defs.MAX_STATUS_EFFECTS)
	testing.expect(test, !has_status(unit, .Muddle))
}

// The capacity check runs before Quick/Slow cancellation, so a full list keeps Slow.
@(test)
test_full_array_keeps_slow_when_quick_is_rejected :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	unit.status_effects[0] = Status_Effect_Slot {
		type     = .Slow,
		duration = defs.STATUS_EFFECTS.base_duration,
	}
	for i in 1 ..< defs.MAX_STATUS_EFFECTS {
		unit.status_effects[i] = Status_Effect_Slot {
			type     = .Shield,
			duration = defs.STATUS_EFFECTS.base_duration,
		}
	}
	unit.status_count = defs.MAX_STATUS_EFFECTS

	apply_status(unit, .Quick)
	testing.expect_value(test, unit.status_count, defs.MAX_STATUS_EFFECTS)
	testing.expect(test, has_status(unit, .Slow))
	testing.expect(test, !has_status(unit, .Quick))
}

@(test)
test_remove_status_swaps_with_last :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Shield)
	apply_status(unit, .Blind)
	apply_status(unit, .Boost)
	remove_status(unit, .Blind)
	testing.expect_value(test, unit.status_count, 2)
	testing.expect(test, has_status(unit, .Shield))
	testing.expect(test, !has_status(unit, .Blind))
	testing.expect(test, has_status(unit, .Boost))
	testing.expect_value(test, unit.status_effects[0].type, defs.Status_Effect.Shield)
	testing.expect_value(test, unit.status_effects[1].type, defs.Status_Effect.Boost)
	testing.expect_value(test, unit.status_effects[2].type, defs.Status_Effect.None)
}

@(test)
test_process_new_statuses_are_stubs :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	apply_status(unit, .Shield)
	apply_status(unit, .Blind)
	apply_status(unit, .Boost)
	apply_status(unit, .Quick)
	apply_status(unit, .Muddle)
	hp := unit.hp.current
	count := unit.status_count

	process_shield(unit)
	process_blind(unit)
	process_boost(unit)
	process_quick(unit)
	process_slow(unit)
	process_muddle(unit)
	process_all_statuses(unit)

	testing.expect_value(test, unit.status_count, count)
	testing.expect_value(test, unit.hp.current, hp)
	testing.expect_value(test, status_duration(unit, .Shield), defs.STATUS_EFFECTS.base_duration)
	testing.expect_value(test, status_duration(unit, .Blind), defs.STATUS_EFFECTS.permanent_duration)
	testing.expect_value(test, status_duration(unit, .Boost), defs.STATUS_EFFECTS.base_duration)
	testing.expect_value(test, status_duration(unit, .Quick), defs.STATUS_EFFECTS.base_duration)
	testing.expect_value(test, status_duration(unit, .Muddle), defs.STATUS_EFFECTS.base_duration)
	testing.expect_value(test, status_duration(unit, .Slow), -1)
}

@(test)
test_fifth_family_dropped_and_nospell :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_judy())
	defer destroy(unit)

	learn_spell(unit, .NoSpell)
	testing.expect(test, !has_spells(unit))

	learn_spell(unit, .Blaze1)
	learn_spell(unit, .Freeze1)
	learn_spell(unit, .Bolt1)
	learn_spell(unit, .Heal1)
	testing.expect(test, has_spells(unit))
	testing.expect_value(test, highest_magic_in_bucket(unit, .Heal), defs.Magic_Name.Heal1)
	testing.expect_value(test, find_family_bucket(unit, .Aura), -1)

	learn_spell(unit, .Blaze3)
	learn_spell(unit, .Blaze1)
	testing.expect_value(test, highest_magic_in_bucket(unit, .Blaze), defs.Magic_Name.Blaze3)
}
