package unit

import "core:log"
import "core:math/rand"

import "../defs"

Combat_Random_Inclusive :: #type proc(lo, hi: int) -> int

combat_random_inclusive_default :: proc(lo, hi: int) -> int {
	if hi < lo {
		log.errorf("combat_random_inclusive: hi (%d) < lo (%d).", hi, lo)
		return lo
	}

	span := hi - lo + 1
	return lo + rand.int_max(span)
}

@(thread_local)
combat_random_override: Combat_Random_Inclusive

combat_random_inclusive :: proc(lo, hi: int) -> int {
	if combat_random_override != nil {
		return combat_random_override(lo, hi)
	}

	return combat_random_inclusive_default(lo, hi)
}

combat_set_random :: proc(random_proc: Combat_Random_Inclusive) {
	combat_random_override = random_proc
}

combat_chance :: proc(denominator: int) -> bool {
	if denominator <= 1 {
		log.errorf("CombatSystem::Chance(): denominator must be greater than 1.")
		return false
	}

	result := combat_random_inclusive(0, denominator - 1)
	log.infof("CombatSystem::Chance() roll: [%d] (need 0 of %d).", result, denominator)
	return result == 0
}

combat_miss :: proc() -> bool {
	return combat_chance(defs.COMBAT_AMOUNTS.base_chance)
}

combat_crit :: proc() -> bool {
	return combat_chance(defs.COMBAT_AMOUNTS.base_chance)
}

combat_apply_amount_variance :: proc(base_amount: int) -> int {
	log.infof("  Base amount: [%d].", base_amount)

	variance := combat_random_inclusive(
		defs.COMBAT_AMOUNTS.min_variance,
		defs.COMBAT_AMOUNTS.max_variance,
	)
	variant_amount := (base_amount * variance) / 100

	log.infof("  Variant amount: [%d].", variant_amount)

	return variant_amount
}

combat_apply_minimum_variance :: proc(base_amount: int) -> int {
	return (base_amount * defs.COMBAT_AMOUNTS.min_variance) / 100
}

combat_apply_maximum_variance :: proc(base_amount: int) -> int {
	return (base_amount * defs.COMBAT_AMOUNTS.max_variance) / 100
}

Combat_Attack_Result :: struct {
	hit, crit: bool,
	damage:    int,
}

combat_apply_attack_damage :: proc(defender: ^Unit, result: Combat_Attack_Result) {
	if defender == nil || !result.hit {
		return
	}

	take_damage(defender, result.damage)
}

// A blind attacker uses only the 1/2 roll. A miss ends the attack. A hit skips
// sleep, quick versus slow, and the normal 1/16 miss roll.
combat_attack_misses :: proc(attacker, defender: ^Unit) -> bool {
	if has_status(attacker, defs.Status_Effect.Blind) {
		if combat_chance(2) {
			log.info("   Attack missed!")
			return true
		}

		return false
	}

	if has_status(defender, defs.Status_Effect.Sleep) {
		log.info("Defender is asleep; attack automatically hits!")
		return false
	}

	if has_status(attacker, defs.Status_Effect.Quick) &&
	   has_status(defender, defs.Status_Effect.Slow) {
		log.info(
			"Attack has the quick status while defender has the slow status; attack automatically hits!",
		)
		return false
	}

	return combat_miss()
}

// crit is the crit roll. Poison and the damage floor ignore it for the amount.
combat_roll_attack_damage :: proc(attacker, defender: ^Unit, crit: bool) -> int {
	boost_amount :=
		has_status(attacker, defs.Status_Effect.Boost) ? defs.COMBAT_AMOUNTS.boost_bonus : 0
	base := (total_offense(attacker) + boost_amount) - defender.defense
	if base <= 0 {
		log.infof(
			"%s's attack [%d] is less than or equal to %s's defense [%d]. Minimum damage is 1",
			defs.name_display(attacker.name),
			total_offense(attacker),
			defs.name_display(defender.name),
			defender.defense,
		)
		return 1
	}

	if has_status(attacker, defs.Status_Effect.Poison) {
		// A poisoned attacker is weak and always hits the minimum amount
		return max(combat_apply_minimum_variance(base), 1)
	}

	if crit {
		// A well-aimed attack always hits at max value and then doubled!
		return max(combat_apply_maximum_variance(base), 1) * 2
	}

	return max(combat_apply_amount_variance(base), 1)
}

combat_calculate_attack_outcome :: proc(attacker, defender: ^Unit) -> Combat_Attack_Result {
	result: Combat_Attack_Result
	if attacker == nil || defender == nil {
		log.errorf("combat_calculate_attack_outcome: attacker or defender is nil.")
		return result
	}

	if combat_attack_misses(attacker, defender) {
		return result
	}

	result.hit = true
	result.crit = combat_crit()
	log.info("   Attack hits!")
	result.damage = combat_roll_attack_damage(attacker, defender, result.crit)
	combat_apply_attack_damage(defender, result)
	return result
}

combat_magic_attack :: proc(
	attacker, defender: ^Unit,
	base_damage: int,
	magic_type: defs.Magic_Type,
) {
	if attacker == nil || defender == nil {
		log.errorf("combat_magic_attack: attacker or defender is nil.")
		return
	}

	if has_status(defender, defs.Status_Effect.Shield) {
		log.infof(
			"%s attack has no effect due to %s having the shield status.",
			defs.name_display(attacker.name),
			defs.name_display(defender.name),
		)
		log.warn("need to return a magic context to determine magic message.")
		return
	}

	log.infof(
		"%s performs a %v magic attack upon %s.",
		defs.name_display(attacker.name),
		magic_type,
		defs.name_display(defender.name),
	)
	variant := combat_apply_amount_variance(base_damage)
	take_damage(defender, max(variant, 1))
}

combat_attack_effect_for :: proc(unit: ^Unit) -> defs.Attack_Effect {
	if unit == nil {
		return .NormalAttack
	}

	return unit.attack_effect
}

take_damage :: proc(unit: ^Unit, amount: int) {
	log.debugf("Unit::TakeDamage(%d)", amount)
	log.infof("Unit [%s] has been damaged for %d.", defs.name_display(unit.name), amount)

	unit.hp.current -= amount
	if unit.hp.current < 0 {
		unit.hp.current = 0
	}

	log.infof("\tUnit's current health: %d / %d.", unit.hp.current, unit.hp.max)
}

heal :: proc(unit: ^Unit, amount: int) -> int {
	requested := max(amount, 0)
	missing := unit.hp.max - unit.hp.current
	actual := min(requested, missing)
	unit.hp.current += actual
	log.infof(
		"Unit [%s] healed for %d (requested %d, missing was %d). HP now %d/%d.",
		defs.name_display(unit.name),
		actual,
		requested,
		missing,
		unit.hp.current,
		unit.hp.max,
	)
	return actual
}

is_dead :: proc(unit: ^Unit) -> bool {
	return unit.hp.current == 0
}
