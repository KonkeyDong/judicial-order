package unit

import "core:log"
import "core:testing"

import "../catalog"
import "../defs"

TEST_ROLL_CAP :: 8

@(thread_local)
test_roll_buf: [TEST_ROLL_CAP]int
@(thread_local)
test_rolls: []int
@(thread_local)
test_roll_i: int

combat_random_from_script :: proc(lo, hi: int) -> int {
	if test_roll_i >= len(test_rolls) {
		log.errorf("combat_random_from_script: no scripted roll left (lo=%d hi=%d).", lo, hi)
		return lo
	}

	value := test_rolls[test_roll_i]
	test_roll_i += 1
	return value
}

test_install_rolls :: proc(rolls: []int) {
	count := len(rolls)
	if count > TEST_ROLL_CAP {
		log.errorf(
			"test_install_rolls: %d rolls exceeds cap %d; truncating.",
			count,
			TEST_ROLL_CAP,
		)
		count = TEST_ROLL_CAP
	}

	for i in 0 ..< count {
		test_roll_buf[i] = rolls[i]
	}

	test_rolls = test_roll_buf[:count]
	test_roll_i = 0
	combat_set_random(combat_random_from_script)
}

@(test)
test_chance_denominator_le_1 :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	testing.expect_value(test, combat_chance(1), false)
	testing.expect_value(test, combat_chance(0), false)
	testing.expect_value(test, combat_chance(-3), false)
}

@(test)
test_variance_75_100_125 :: proc(test: ^testing.T) {
	defer combat_set_random(nil)

	test_install_rolls({75})
	testing.expect_value(test, combat_apply_amount_variance(10), 7)
	test_install_rolls({100})
	testing.expect_value(test, combat_apply_amount_variance(10), 10)
	test_install_rolls({125})
	testing.expect_value(test, combat_apply_amount_variance(10), 12)
}

@(test)
test_miss_path :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	judy_hp := judy.hp.current
	test_install_rolls({0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, false)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 0)
	testing.expect_value(test, judy.hp.current, judy_hp)
}

@(test)
test_hit_min_damage_1 :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	test_install_rolls({1, 1})
	result := combat_calculate_attack_outcome(judy, hale)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 1)
	testing.expect_value(test, hale.hp.current, 14)
}

@(test)
test_variance_bounds :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	defer destroy(hale)
	defer combat_set_random(nil)
	testing.expect(test, add_item(hale, .SmallBriefcase, auto_equip_weapon = true))

	judy_low := make(test_data_judy())
	defer destroy(judy_low)
	test_install_rolls({1, 1, 75})
	result_low := combat_calculate_attack_outcome(hale, judy_low)
	testing.expect_value(test, result_low.hit, true)
	testing.expect_value(test, result_low.damage, 8)
	testing.expect(test, result_low.damage >= 1)
	testing.expect_value(test, judy_low.hp.current, 2)

	judy_high := make(test_data_judy())
	defer destroy(judy_high)
	test_install_rolls({1, 1, 125})
	result_high := combat_calculate_attack_outcome(hale, judy_high)
	testing.expect_value(test, result_high.hit, true)
	testing.expect_value(test, result_high.damage, 13)
	testing.expect_value(test, judy_high.hp.current, 0)
}

@(test)
test_crit_doubles_max_variance :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	test_install_rolls({1, 0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, true)
	testing.expect_value(test, result.damage, 12)
	testing.expect_value(test, judy.hp.current, 0)
}

@(test)
test_hale_judy_unarmed_hit :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	test_install_rolls({1, 1, 100})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 6)
	testing.expect_value(test, judy.hp.current, 4)
}

@(test)
test_blind_forces_miss :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Blind)
	judy_hp := judy.hp.current
	test_install_rolls({0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, false)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 0)
	testing.expect_value(test, judy.hp.current, judy_hp)
}

@(test)
test_blind_hit_skips_miss_roll :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Blind)
	// 1 is the blind hit. 0 is the crit roll, not a 1/16 miss.
	test_install_rolls({1, 0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, true)
	testing.expect_value(test, result.damage, 12)
	testing.expect_value(test, judy.hp.current, 0)
}

@(test)
test_blind_hit :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Blind)
	test_install_rolls({1, 1, 100})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 6)
	testing.expect_value(test, judy.hp.current, 4)
}

@(test)
test_blind_misses_sleeping_defender :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Blind)
	apply_status(judy, .Sleep)
	judy_hp := judy.hp.current
	test_install_rolls({0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, false)
	testing.expect_value(test, result.damage, 0)
	testing.expect_value(test, judy.hp.current, judy_hp)
}

@(test)
test_sleep_auto_hit_uses_zero_as_crit :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(judy, .Sleep)
	test_install_rolls({0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, true)
	testing.expect_value(test, result.damage, 12)
	testing.expect_value(test, judy.hp.current, 0)
}

@(test)
test_quick_versus_slow_auto_hit :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Quick)
	apply_status(judy, .Slow)
	test_install_rolls({0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, true)
	testing.expect_value(test, result.damage, 12)
	testing.expect_value(test, judy.hp.current, 0)
}

@(test)
test_quick_alone_can_miss :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Quick)
	judy_hp := judy.hp.current
	test_install_rolls({0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, false)
	testing.expect_value(test, result.damage, 0)
	testing.expect_value(test, judy.hp.current, judy_hp)
}

@(test)
test_slow_alone_can_miss :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(judy, .Slow)
	judy_hp := judy.hp.current
	test_install_rolls({0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, false)
	testing.expect_value(test, result.damage, 0)
	testing.expect_value(test, judy.hp.current, judy_hp)
}

@(test)
test_boost_adds_before_defense :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Boost)
	test_install_rolls({1, 1, 100})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 21)
	testing.expect_value(test, judy.hp.current, 0)
}

@(test)
test_boost_still_minimum_1 :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Boost)
	judy.defense = total_offense(hale) + defs.COMBAT_AMOUNTS.boost_bonus + 1
	test_install_rolls({1, 1})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 1)
	testing.expect_value(test, judy.hp.current, 9)
}

@(test)
test_poison_attacker_uses_minimum_variance :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Poison)
	test_install_rolls({1, 1, 125})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, false)
	testing.expect_value(test, result.damage, 4)
	testing.expect_value(test, judy.hp.current, 6)
}

@(test)
test_poison_overrides_crit_damage :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(hale, .Poison)
	test_install_rolls({1, 0})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, true)
	testing.expect_value(test, result.damage, 4)
	testing.expect_value(test, judy.hp.current, 6)
}

@(test)
test_crit_roll_does_not_double_floor_damage :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	test_install_rolls({1, 0})
	result := combat_calculate_attack_outcome(judy, hale)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.crit, true)
	testing.expect_value(test, result.damage, 1)
	testing.expect_value(test, hale.hp.current, 14)
}

@(test)
test_shield_blocks_magic :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	hale.friendly = false
	apply_status(hale, .Shield)
	hp := hale.hp.current
	test_install_rolls({125})
	combat_magic_attack(judy, hale, 7, .Fire)
	testing.expect_value(test, hale.hp.current, hp)
}

@(test)
test_shield_does_not_block_physical :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	apply_status(judy, .Shield)
	test_install_rolls({1, 1, 100})
	result := combat_calculate_attack_outcome(hale, judy)
	testing.expect_value(test, result.hit, true)
	testing.expect_value(test, result.damage, 6)
	testing.expect_value(test, judy.hp.current, 4)
}

@(test)
test_magic_attack_never_miss :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	hale.friendly = false
	test_install_rolls({100})
	combat_magic_attack(judy, hale, 7, .Fire)
	testing.expect_value(test, hale.hp.current, 8)
}

@(test)
test_magic_from_item_skips_mp :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	hale.friendly = false
	judy.mp.current = 0
	test_install_rolls({100})
	magic_cast(.Blaze1, judy, {hale}, true)
	testing.expect_value(test, judy.mp.current, 0)
	testing.expect_value(test, hale.hp.current, 8)
}

@(test)
test_magic_not_from_item_deducts_mp :: proc(test: ^testing.T) {
	catalog.init()
	judy := make(test_data_judy())
	defer destroy(judy)
	defer combat_set_random(nil)

	judy.hp.current = 4
	test_install_rolls({100})
	magic_cast(.Heal1, judy, {judy})
	testing.expect_value(test, judy.mp.current, 9)
}

@(test)
test_magic_not_enough_mp_no_effect :: proc(test: ^testing.T) {
	catalog.init()
	judy := make(test_data_judy())
	defer destroy(judy)

	judy.hp.current = 4
	judy.mp.current = 1
	magic_cast(.Heal1, judy, {judy})
	testing.expect_value(test, judy.hp.current, 4)
	testing.expect_value(test, judy.mp.current, 1)
}

@(test)
test_magic_damage_skips_same_team :: proc(test: ^testing.T) {
	catalog.init()
	judy := make(test_data_judy())
	defer destroy(judy)
	defer combat_set_random(nil)

	test_install_rolls({100})
	magic_cast(.Blaze1, judy, {judy})
	testing.expect_value(test, judy.mp.current, 10)
	testing.expect_value(test, judy.hp.current, 10)
}

@(test)
test_magic_heal_same_team :: proc(test: ^testing.T) {
	catalog.init()
	judy := make(test_data_judy())
	defer destroy(judy)
	defer combat_set_random(nil)

	judy.hp.current = 4
	test_install_rolls({100})
	magic_cast(.Heal1, judy, {judy})
	testing.expect_value(test, judy.hp.current, 10)
}

@(test)
test_magic_get_blaze1_stats :: proc(test: ^testing.T) {
	data := catalog.magic_get(.Blaze1)
	testing.expect_value(test, data.mp_cost, 2)
	testing.expect_value(test, data.effect_value, 7)
	testing.expect_value(test, data.effect_type, defs.Magic_Effect.Damage)
	testing.expect_value(test, data.magic_type, defs.Magic_Type.Fire)
}

@(test)
test_magic_heal_skips_enemy :: proc(test: ^testing.T) {
	catalog.init()
	judy := make(test_data_judy())
	defer destroy(judy)
	defer combat_set_random(nil)

	hale := make(test_data_hale())
	defer destroy(hale)
	judy.friendly = false
	judy.hp.current = 4
	test_install_rolls({100})
	magic_cast(.Heal1, hale, {judy})
	testing.expect_value(test, judy.hp.current, 4)
}

@(test)
test_magic_nil_caster :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	hale := make(test_data_hale())
	defer destroy(hale)
	hp := hale.hp.current
	mp := hale.mp.current
	magic_cast_data(catalog.magic_get(.Blaze1), nil, {hale})
	testing.expect_value(test, hale.hp.current, hp)
	testing.expect_value(test, hale.mp.current, mp)
}

@(test)
test_consumable_heal_same_team :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	judy.hp.current = 2
	test_install_rolls({100})
	herb := catalog.Item_Data {
		name         = .Hotdog,
		type         = .Consumable,
		effect_type  = .Heal,
		effect_value = 4,
	}
	item_apply_consumable_to_target(herb, hale, judy)
	testing.expect_value(test, judy.hp.current, 6)
}

@(test)
test_consumable_heal_rejects_enemy :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)

	judy.friendly = false
	judy.hp.current = 2
	testing.expect(test, add_item(hale, .Hotdog))
	item_use_item(.Hotdog, hale, {judy}, 0)
	testing.expect_value(test, judy.hp.current, 2)
	testing.expect(test, item_slot_is_empty(item_at(hale, 0)))
}

@(test)
test_heal_all_full_no_variance :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)
	defer combat_set_random(nil)

	judy.hp.current = 2
	test_install_rolls({75})
	shower := catalog.Item_Data {
		name         = .Hotdog,
		type         = .Consumable,
		effect_type  = .HealAllFull,
		effect_value = 4,
	}
	item_apply_consumable_to_target(shower, hale, judy)
	testing.expect_value(test, judy.hp.current, 6)
}

@(test)
test_poison_cure :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)

	apply_status(judy, .Poison)
	testing.expect(test, has_status(judy, .Poison))
	antidote := catalog.Item_Data {
		name        = .Hotdog,
		type        = .Consumable,
		effect_type = .RemovePoison,
	}
	item_apply_consumable_to_target(antidote, hale, judy)
	testing.expect(test, !has_status(judy, .Poison))
}

@(test)
test_poison_cure_noop :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)

	testing.expect(test, !has_status(judy, .Poison))
	antidote := catalog.Item_Data {
		name        = .Hotdog,
		type        = .Consumable,
		effect_type = .RemovePoison,
	}
	item_apply_consumable_to_target(antidote, hale, judy)
	testing.expect(test, !has_status(judy, .Poison))
}

@(test)
test_escape_unimplemented :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)

	testing.expect(test, add_item(hale, .Hotdog))
	hp := judy.hp.current
	escape := catalog.Item_Data {
		name        = .Hotdog,
		type        = .Consumable,
		effect_type = .Escape,
	}
	item_use_data(escape, hale, {judy}, 0)
	testing.expect_value(test, judy.hp.current, hp)
	testing.expect(test, item_slot_is_empty(item_at(hale, 0)))
}

@(test)
test_durability_already_damaged_removes :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	defer destroy(hale)

	testing.expect(test, add_item(hale, .SmallBriefcase, damaged = true))
	item_apply_spell_item_durability(hale, 0)
	testing.expect(test, item_slot_is_empty(item_at(hale, 0)))
}

@(test)
test_durability_break :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	defer destroy(hale)
	defer combat_set_random(nil)

	testing.expect(test, add_item(hale, .SmallBriefcase))
	test_install_rolls({0})
	item_apply_spell_item_durability(hale, 0)
	testing.expect(test, !item_slot_is_empty(item_at(hale, 0)))
	testing.expect_value(test, item_at(hale, 0).damaged, true)
}

@(test)
test_durability_intact :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	defer destroy(hale)
	defer combat_set_random(nil)

	testing.expect(test, add_item(hale, .SmallBriefcase))
	test_install_rolls({1})
	item_apply_spell_item_durability(hale, 0)
	testing.expect_value(test, item_at(hale, 0).damaged, false)
}

@(test)
test_consume_removes_at_index :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	defer destroy(hale)

	testing.expect(test, add_item(hale, .Hotdog))
	testing.expect(test, add_item(hale, .SmallBriefcase))
	item_consume_item(hale, 0)
	testing.expect_value(test, item_at(hale, 0).name, defs.Item_Name.SmallBriefcase)
}

@(test)
test_spell_item_use_is_stub :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)

	judy.friendly = false
	hp := judy.hp.current
	mp := hale.mp.current
	spell_item := catalog.Item_Data {
		name       = .SmallBriefcase,
		type       = .Briefcase,
		spell_name = .Blaze1,
	}
	testing.expect(test, add_item(hale, .SmallBriefcase))
	item_use_data(spell_item, hale, {judy}, 0)
	testing.expect_value(test, judy.hp.current, hp)
	testing.expect_value(test, hale.mp.current, mp)
	testing.expect_value(test, item_at(hale, 0).name, defs.Item_Name.SmallBriefcase)
}

@(test)
test_nil_attack_units :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	result := combat_calculate_attack_outcome(nil, nil)
	testing.expect_value(test, result.hit, false)
	testing.expect_value(test, result.damage, 0)
}
