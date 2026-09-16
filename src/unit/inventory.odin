package unit

import "core:fmt"
import "core:log"

import "../catalog"
import "../defs"

item_is_giveable :: proc(name: defs.Item_Name) -> bool {
	return name != .NoItem && name != .Unarmed
}

item_slot_is_giveable :: proc(slot: Item_Slot) -> bool {
	return item_is_giveable(slot.name)
}

item_display_name :: proc(name: defs.Item_Name) -> defs.Item_Name {
	return .NoItem if name == .Unarmed else name
}

item_is_usable :: proc(name: defs.Item_Name, unit_job: defs.Job) -> bool {
	if name == .NoItem || name == .Unarmed {
		return false
	}

	data := catalog.item_get(name)
	if !defs.job_is_allowed_by(unit_job, data.allowed_jobs) {
		return false
	}

	return data.effect_type != .None || data.spell_name != .NoSpell
}

add_item :: proc(
	unit: ^Unit,
	item_name: defs.Item_Name,
	damaged := false,
	auto_equip_weapon := false,
) -> bool {
	if item_name == .Unarmed {
		log.warnf(
			"Unit [%s] cannot add unarmed to item list because being unarmed is without an item.",
			defs.name_display(unit.name),
		)
		return false
	}

	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		if item_slot_is_empty(unit.items[i]) {
			unit.items[i] = Item_Slot {
				name    = item_name,
				damaged = damaged,
			}
			if auto_equip_weapon && unit.equipped_weapon_index < 0 {
				data := catalog.item_get(item_name)
				if can_equip_weapon(unit, data) {
					unit.equipped_weapon_index = i
				}
			}

			return true
		}
	}

	return false
}

remove_item_at :: proc(unit: ^Unit, index: int) -> bool {
	if index < 0 || index >= defs.MAX_BUCKET_SIZE {
		log.errorf("RemoveItemAtIndex(): index [%d] out of range.", index)
		return false
	}

	if item_slot_is_empty(unit.items[index]) {
		log.warnf("RemoveItemAtIndex(): slot [%d] is already empty.", index)
		return false
	}

	if unit.equipped_weapon_index == index {
		unit.equipped_weapon_index = defs.UNARMED_INDEX
	} else if unit.equipped_weapon_index > index {
		unit.equipped_weapon_index -= 1
	}

	for i in index ..< defs.MAX_BUCKET_SIZE - 1 {
		unit.items[i] = unit.items[i + 1]
	}

	unit.items[defs.MAX_BUCKET_SIZE - 1] = ITEM_SLOT_EMPTY
	return true
}

set_item_damaged :: proc(unit: ^Unit, index: int, damaged := true) -> bool {
	if index < 0 || index >= defs.MAX_BUCKET_SIZE || item_slot_is_empty(unit.items[index]) {
		log.errorf("SetItemDamaged(): invalid slot [%d].", index)
		return false
	}

	slot := unit.items[index]
	unit.items[index] = Item_Slot {
		name    = slot.name,
		damaged = damaged,
	}
	log.infof("%s's [%v] Damaged set to %v.", defs.name_display(unit.name), slot.name, damaged)
	return true
}

item_at :: proc(unit: ^Unit, index: int) -> Item_Slot {
	if index < 0 || index >= defs.MAX_BUCKET_SIZE {
		return ITEM_SLOT_EMPTY
	}

	return unit.items[index]
}

has_empty_item_slot :: proc(unit: ^Unit) -> bool {
	return find_first_empty_item_slot(unit) >= 0
}

find_first_empty_item_slot :: proc(unit: ^Unit) -> int {
	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		if item_slot_is_empty(unit.items[i]) {
			return i
		}
	}

	return -1
}

find_first_giveable_item_slot :: proc(unit: ^Unit) -> int {
	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		if item_slot_is_giveable(unit.items[i]) {
			return i
		}
	}

	return -1
}

has_giveable_item :: proc(unit: ^Unit) -> bool {
	return find_first_giveable_item_slot(unit) >= 0
}

has_usable_item :: proc(unit: ^Unit) -> bool {
	for i in 0 ..< defs.MAX_BUCKET_SIZE {
		if item_is_usable(unit.items[i].name, unit.job) {
			return true
		}
	}

	return false
}

give_item_to :: proc(giver, recipient: ^Unit, giver_slot_index: int) -> bool {
	if recipient == nil {
		log.error("GiveItemTo(): recipient is null.")
		return false
	}

	if giver_slot_index < 0 || giver_slot_index >= defs.MAX_BUCKET_SIZE {
		log.errorf("GiveItemTo(): giver slot [%d] out of range.", giver_slot_index)
		return false
	}

	item_slot := giver.items[giver_slot_index]
	if !item_slot_is_giveable(item_slot) {
		log.warnf(
			"GiveItemTo(): slot [%d] is not giveable (%v).",
			giver_slot_index,
			item_slot.name,
		)
		return false
	}

	if !has_empty_item_slot(recipient) {
		log.warn("GiveItemTo(): recipient inventory is full.")
		return false
	}

	if !add_item(recipient, item_slot.name, item_slot.damaged, auto_equip_weapon = false) {
		log.error("GiveItemTo(): failed to add item to recipient.")
		return false
	}

	remove_item_at(giver, giver_slot_index)
	log.infof(
		"%s gave [%v] to %s.",
		defs.name_display(giver.name),
		item_slot.name,
		defs.name_display(recipient.name),
	)
	return true
}

swap_item_with :: proc(unit, other: ^Unit, my_index, other_index: int) -> bool {
	if other == nil {
		log.error("SwapItemWith(): other unit is null.")
		return false
	}

	if my_index < 0 ||
	   my_index >= defs.MAX_BUCKET_SIZE ||
	   other_index < 0 ||
	   other_index >= defs.MAX_BUCKET_SIZE {
		log.errorf(
			"SwapItemWith(): index out of range (mine=%d, other=%d).",
			my_index,
			other_index,
		)
		return false
	}

	my_item_slot := unit.items[my_index]
	other_item_slot := other.items[other_index]
	if !item_slot_is_giveable(my_item_slot) || !item_slot_is_giveable(other_item_slot) {
		log.warnf(
			"SwapItemWith(): one or both slots are not giveable (%v / %v).",
			my_item_slot.name,
			other_item_slot.name,
		)
		return false
	}

	if unit.equipped_weapon_index == my_index {
		unequip_weapon(unit)
	}

	if other.equipped_weapon_index == other_index {
		unequip_weapon(other)
	}

	unit.items[my_index] = other_item_slot
	other.items[other_index] = my_item_slot
	log.infof(
		"%s swapped [%v] with %s's [%v].",
		defs.name_display(unit.name),
		my_item_slot.name,
		defs.name_display(other.name),
		other_item_slot.name,
	)
	return true
}

unequip_weapon :: proc(unit: ^Unit) {
	unit.equipped_weapon_index = defs.UNARMED_INDEX
}

can_equip_weapon :: proc(unit: ^Unit, data: catalog.Item_Data) -> bool {
	if !unit.friendly {
		return false
	}

	if !catalog.item_type_is_weapon(data.type) {
		return false
	}

	return defs.job_is_allowed_by(unit.job, data.allowed_jobs)
}

equip_weapon_at :: proc(unit: ^Unit, index: int) -> bool {
	if index < 0 || index >= defs.MAX_BUCKET_SIZE {
		log.errorf("EquipWeaponAtIndex(): index [%d] out of range.", index)
		return false
	}

	slot := unit.items[index]
	if item_slot_is_empty(slot) {
		log.warn("EquipWeaponAtIndex(): slot is empty.")
		return false
	}

	data := catalog.item_get(slot.name)
	if !can_equip_weapon(unit, data) {
		log.warnf(
			"EquipWeaponAtIndex(): [%s] cannot equip [%v] (Friendly=%v, Job=%v).",
			defs.name_display(unit.name),
			slot.name,
			unit.friendly,
			unit.job,
		)
		return false
	}

	unit.equipped_weapon_index = index
	log.infof("Equipped [%v] from slot [%d].", slot.name, index)
	return true
}

equipped_weapon_name :: proc(unit: ^Unit) -> defs.Item_Name {
	if unit.equipped_weapon_index < 0 || unit.equipped_weapon_index >= defs.MAX_BUCKET_SIZE {
		return .Unarmed
	}

	slot := unit.items[unit.equipped_weapon_index]
	if item_slot_is_empty(slot) {
		return .Unarmed
	}

	return slot.name
}

equipped_weapon_slot :: proc(unit: ^Unit) -> Item_Slot {
	if unit.equipped_weapon_index < 0 || unit.equipped_weapon_index >= defs.MAX_BUCKET_SIZE {
		return Item_Slot{name = .Unarmed, damaged = false}
	}

	return unit.items[unit.equipped_weapon_index]
}

equipped_weapon_data :: proc(unit: ^Unit) -> catalog.Item_Data {
	return catalog.item_get(equipped_weapon_name(unit))
}

total_offense :: proc(unit: ^Unit) -> int {
	return unit.attack + equipped_weapon_data(unit).attack
}

can_use_weapon_as_item :: proc(item_name: defs.Item_Name, job: defs.Job) -> bool {
	data := catalog.item_get(item_name)
	if data.spell_name == .NoSpell {
		return false
	}

	return defs.job_is_allowed_by(job, data.allowed_jobs)
}

combat_string :: proc(unit: ^Unit) -> string {
	weapon_data := equipped_weapon_data(unit)
	weapon_slot := equipped_weapon_slot(unit)
	return fmt.tprintf(
		"   %s:\n   HP            = [%s]\n   MP            = [%s]\n   Eq. Weapon    = [%v] (Damaged: %v)\n   Offense       = [%d]\n   Defense       = [%d]\n   Speed         = [%d]\n   Movement Type = [%v]\n",
		defs.name_display(unit.name),
		stat_string(unit.hp),
		stat_string(unit.mp),
		weapon_data.name,
		weapon_slot.damaged,
		total_offense(unit),
		unit.defense,
		unit.speed,
		unit.movement_type,
	)
}
