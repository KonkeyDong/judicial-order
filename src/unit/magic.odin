package unit

import "core:log"

import "../catalog"
import "../defs"

has_spells :: proc(unit: ^Unit) -> bool {
	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		if unit.magic_family_buckets[i] != .NoSpell {
			return true
		}
	}

	return false
}

learn_spell :: proc(unit: ^Unit, spell_name: defs.Magic_Name) {
	if spell_name == .NoSpell {
		log.warn("learn_spell: NoSpell is not a learnable spell.")
		return
	}

	family := catalog.magic_name_to_family(spell_name)
	if family == .NoSpell {
		log.errorf("learn_spell: unknown family for %v", spell_name)
		return
	}

	index := find_family_bucket(unit, family)
	if index < 0 {
		index = fill_first_available_bucket(unit, family)
		if index < 0 {
			return
		}
	}

	count := unit.known_spell_counts[index]
	for i in 0 ..< count {
		if unit.known_spells[index][i] == spell_name {
			return
		}
	}

	if count >= defs.MAX_BUCKET_SIZE {
		log.errorf("learn_spell: bucket for [%v] is full.", family)
		return
	}

	unit.known_spells[index][count] = spell_name
	unit.known_spell_counts[index] = count + 1
}

find_family_bucket :: proc(unit: ^Unit, family: defs.Magic_Family) -> int {
	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		if unit.magic_family_buckets[i] == family {
			return i
		}
	}

	return -1
}

fill_first_available_bucket :: proc(unit: ^Unit, family: defs.Magic_Family) -> int {
	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		if unit.magic_family_buckets[i] == .NoSpell {
			unit.magic_family_buckets[i] = family
			return i
		}
	}

	log.errorf(
		"magic family [%v] could not be added to bucket as bucket as reached capacity.",
		family,
	)
	return -1
}

magic_list_in_bucket :: proc(unit: ^Unit, family: defs.Magic_Family) -> []defs.Magic_Name {
	index := find_family_bucket(unit, family)
	if index < 0 {
		log.errorf("Magic family [%v] not found.", family)
		return unit.known_spells[0][:0]
	}

	return unit.known_spells[index][:unit.known_spell_counts[index]]
}

highest_magic_in_bucket :: proc(unit: ^Unit, family: defs.Magic_Family) -> defs.Magic_Name {
	list := magic_list_in_bucket(unit, family)
	if len(list) == 0 {
		return .NoSpell
	}

	return list[len(list) - 1]
}

highest_magic_data_in_bucket :: proc(
	unit: ^Unit,
	family: defs.Magic_Family,
) -> catalog.Magic_Data {
	return catalog.magic_get(highest_magic_in_bucket(unit, family))
}

magic_mp_cost :: proc(name: defs.Magic_Name, from_item := false) -> int {
	if from_item {
		return 0
	}

	return catalog.magic_get(name).mp_cost
}

magic_execute_effect :: proc(data: catalog.Magic_Data, caster: ^Unit, targets: []^Unit) {
	if caster == nil {
		log.errorf("magic_execute_effect: caster is nil.")
		return
	}

	switch data.effect_type {
	case .Damage:
		for target in targets {
			if target == nil {
				continue
			}

			if caster.friendly != target.friendly {
				combat_magic_attack(caster, target, data.effect_value, data.magic_type)
			}
		}
	case .Heal:
		for target in targets {
			if target == nil {
				continue
			}

			if caster.friendly == target.friendly {
				rolled := combat_apply_amount_variance(data.effect_value)
				heal(target, max(rolled, 1))
			}
		}
	case .Egress:
		log.info("Egress: escaping battle (not yet implemented).")
	case .Desoul:
		log.info("Desoul: not yet implemented.")
	case .None:
		log.warnf("No effect for spell [%v].", data.name)
	}
}

magic_cast_data :: proc(
	data: catalog.Magic_Data,
	caster: ^Unit,
	targets: []^Unit,
	from_item := false,
) {
	if caster == nil {
		log.errorf("magic_cast_data: caster is nil.")
		return
	}

	if !from_item && caster.mp.current < data.mp_cost {
		log.warnf("Not enough MP to cast [%v].", data.name)
		return
	}

	if !from_item && data.mp_cost > 0 {
		caster.mp.current -= data.mp_cost
	}

	magic_execute_effect(data, caster, targets)
}

magic_cast :: proc(name: defs.Magic_Name, caster: ^Unit, targets: []^Unit, from_item := false) {
	magic_cast_data(catalog.magic_get(name), caster, targets, from_item)
}
