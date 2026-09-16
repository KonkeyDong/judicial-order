package unit

import "core:log"

import "../defs"

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
