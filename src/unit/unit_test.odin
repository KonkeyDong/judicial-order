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
	}
}

@(test)
test_add_remove_equipped_shift :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	testing.expect(test, add_item(unit, .ShortSword, auto_equip_weapon = true))
	testing.expect(test, add_item(unit, .MedicalHerb))
	testing.expect(test, add_item(unit, .ShortSword))
	testing.expect_value(test, unit.equipped_weapon_index, 0)
	testing.expect(test, remove_item_at(unit, 0))
	testing.expect_value(test, unit.equipped_weapon_index, defs.UNARMED_INDEX)
	testing.expect_value(test, unit.items[0].name, defs.Item_Name.MedicalHerb)
}

@(test)
test_swap_unequips_and_does_not_re_equip :: proc(test: ^testing.T) {
	catalog.init()
	hale := make(test_data_hale())
	judy := make(test_data_judy())
	defer destroy(hale)
	defer destroy(judy)

	testing.expect(test, add_item(hale, .ShortSword, auto_equip_weapon = true))
	testing.expect(test, add_item(judy, .MedicalHerb))
	testing.expect_value(test, hale.equipped_weapon_index, 0)
	testing.expect(test, swap_item_with(hale, judy, 0, 0))
	testing.expect_value(test, hale.equipped_weapon_index, defs.UNARMED_INDEX)
	testing.expect_value(test, judy.equipped_weapon_index, defs.UNARMED_INDEX)
	testing.expect_value(test, hale.items[0].name, defs.Item_Name.MedicalHerb)
	testing.expect_value(test, judy.items[0].name, defs.Item_Name.ShortSword)
}

@(test)
test_reject_unarmed_and_full_add :: proc(test: ^testing.T) {
	catalog.init()
	unit := make(test_data_hale())
	defer destroy(unit)

	testing.expect(test, !add_item(unit, .Unarmed))
	testing.expect(test, add_item(unit, .ShortSword))
	testing.expect(test, add_item(unit, .MedicalHerb))
	testing.expect(test, add_item(unit, .ShortSword))
	testing.expect(test, add_item(unit, .MedicalHerb))
	testing.expect(test, !add_item(unit, .ShortSword))
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
	for _ in 0 ..< defs.STATUS_EFFECTS.sleep_duration + 1 {
		process_sleep(unit)
	}

	testing.expect(test, !has_status(unit, .Sleep))
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
