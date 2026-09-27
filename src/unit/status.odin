package unit

import "core:log"
import "core:math/rand"

import "../defs"

status_create :: proc(type: defs.Status_Effect) -> Status_Effect_Slot {
	base_duration := defs.STATUS_EFFECTS.base_duration
	permanent_duration := defs.STATUS_EFFECTS.permanent_duration

	switch type {
	case .Poison:
		return Status_Effect_Slot{type = .Poison, duration = permanent_duration}
	case .Sleep:
		return Status_Effect_Slot{type = .Sleep, duration = rand.int_max(base_duration)}
	case .Shield:
		return Status_Effect_Slot{type = .Shield, duration = base_duration}
	case .Blind:
		return Status_Effect_Slot{type = .Blind, duration = permanent_duration}
	case .Boost:
		return Status_Effect_Slot{type = .Boost, duration = base_duration}
	case .Quick:
		return Status_Effect_Slot{type = .Quick, duration = base_duration}
	case .Slow:
		return Status_Effect_Slot{type = .Slow, duration = base_duration}
	case .Muddle:
		return Status_Effect_Slot{type = .Muddle, duration = base_duration}
	case .None:
		return STATUS_EFFECT_EMPTY
	}

	return STATUS_EFFECT_EMPTY
}

apply_status :: proc(unit: ^Unit, type: defs.Status_Effect) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	if has_status(unit, type) {
		log.infof("Unit [%s] already has [%v]. Ignoring.", defs.name_display(unit.name), type)
		return
	}

	if unit.status_count == defs.MAX_STATUS_EFFECTS {
		log.errorf("apply_status: status array full for [%s].", defs.name_display(unit.name))
		return
	}

	if has_status(unit, .Slow) && type == .Quick {
		log.debug("Unit no longer will have the slow status due to having quick status applied.")
		remove_status(unit, .Slow)
	}

	if has_status(unit, .Quick) && type == .Slow {
		log.debug("Unit no longer will have the quick status due to having slow status applied.")
		remove_status(unit, .Quick)
	}

	unit.status_effects[unit.status_count] = status_create(type)
	unit.status_count += 1
	log.infof("Applied [%v] to [%s].", type, defs.name_display(unit.name))
}

has_status :: proc(unit: ^Unit, type: defs.Status_Effect) -> bool {
	if unit == nil {
		log.panic("unit is nil.")
	}

	return find_status_index(unit, type) >= 0
}

find_status_index :: proc(unit: ^Unit, type: defs.Status_Effect) -> int {
	if unit == nil {
		log.panic("unit is nil.")
	}

	for i in 0 ..< unit.status_count {
		if unit.status_effects[i].type == type {
			return i
		}
	}

	return -1
}

remove_status :: proc(unit: ^Unit, type: defs.Status_Effect) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	index := find_status_index(unit, type)
	if index < 0 {
		return
	}

	last := unit.status_count - 1
	unit.status_effects[index] = unit.status_effects[last]
	unit.status_effects[last] = STATUS_EFFECT_EMPTY
	unit.status_count -= 1
	log.infof("Removed [%v] from [%s].", type, defs.name_display(unit.name))
}

remove_all_status :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	unit.status_count = 0
}

status_duration_remaining :: proc(unit: ^Unit, type: defs.Status_Effect) -> int {
	if unit == nil {
		log.panic("unit is nil.")
	}

	index := find_status_index(unit, type)
	if index < 0 {
		return -1
	}

	return unit.status_effects[index].duration
}

// process_all_statuses :: proc(unit: ^Unit) {
// 	process_poison(unit)
// 	process_sleep(unit)
// 	process_shield(unit)
// 	process_blind(unit)
// 	process_boost(unit)
// 	process_quick(unit)
// 	process_slow(unit)
// 	process_muddle(unit)
// }

process_poison :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	log.debugf("Processing [poison] for unit %s", defs.name_display(unit.name))
	if !has_status(unit, .Poison) {
		return
	}

	damage := unit.hp.max / defs.STATUS_EFFECTS.poison_damage_denominator
	final_damage := max(2, damage)
	log.infof(
		"Poison damage dealt to unit [%s] is [%d].",
		defs.name_display(unit.name),
		final_damage,
	)

	take_damage(unit, final_damage)
}

process_sleep :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	log.debugf("Processing [sleep] for unit %s", defs.name_display(unit.name))
	process_duration_status_effect(unit, .Sleep)
}

process_shield :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	log.debugf("Processing [shield] for unit %s", defs.name_display(unit.name))
	process_duration_status_effect(unit, .Shield)
}

process_blind :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}
}

process_boost :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	log.debugf("Processing [boost] for unit %s", defs.name_display(unit.name))
	process_duration_status_effect(unit, .Boost)
}

process_quick :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	log.debugf("Processing [quick] for unit %s", defs.name_display(unit.name))
	process_duration_status_effect(unit, .Quick)
}

process_slow :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	log.debugf("Processing [slow] for unit %s", defs.name_display(unit.name))
	process_duration_status_effect(unit, .Slow)
}

process_muddle :: proc(unit: ^Unit) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	log.debugf("Processing [muddle] for unit %s", defs.name_display(unit.name))
	process_duration_status_effect(unit, .Muddle)
}

@(private = "file")
process_duration_status_effect :: proc(unit: ^Unit, status: defs.Status_Effect) {
	if unit == nil {
		log.panic("unit is nil.")
	}

	if status == .Poison || status == .Blind {
		log.debug("Poison/Blind do not have a set duration; returning early.")
		return
	}

	index := find_status_index(unit, status)
	if index < 0 {
		return
	}

	unit.status_effects[index].duration -= 1
	if unit.status_effects[index].duration < 0 {
		log.infof(
			"%s status on unit [%s] has exhausted; removing.",
			status,
			defs.name_display(unit.name),
		)
		remove_status(unit, status)
	}
}
