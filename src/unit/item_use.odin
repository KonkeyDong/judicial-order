package unit

import "core:log"

import "../catalog"
import "../defs"

item_apply_consumable_to_target :: proc(data: catalog.Item_Data, caster, target: ^Unit) {
	if caster == nil || target == nil {
		return
	}

	if caster.friendly != target.friendly {
		return
	}

	switch data.effect_type {
	case .Heal:
		rolled := combat_apply_amount_variance(data.effect_value)
		heal(target, rolled)
	case .HealAllFull:
		heal(target, data.effect_value)
	case .RemovePoison:
		if has_status(target, .Poison) {
			remove_status(target, .Poison)
			log.infof("%s was cured of poison by an item.", defs.name_display(target.name))
		} else {
			log.infof(
				"%s was not poisoned; antidote had no effect.",
				defs.name_display(target.name),
			)
		}
	case .Escape:
		log.warn("ItemEffectType.Escape not implemented.")
	case .None:
		log.warnf("No consumable effect for [%v] (%v).", data.name, data.effect_type)
	}
}

item_consume_item :: proc(caster: ^Unit, item_slot_index: int) {
	if caster == nil {
		log.errorf("ConsumeItem: caster is nil.")
		return
	}

	remove_item_at(caster, item_slot_index)
}

item_use_data :: proc(
	data: catalog.Item_Data,
	caster: ^Unit,
	targets: []^Unit,
	item_slot_index: int,
) {
	if data.type == .Consumable {
		for target in targets {
			item_apply_consumable_to_target(data, caster, target)
		}

		item_consume_item(caster, item_slot_index)
		return
	}

	if data.spell_name != .NoSpell {
		log.warn(
			"item_use_item: spell item should be cast via UseItemOnWhom (MagicContext + Cast(from_item = true)).",
		)
	}
}

item_use_item :: proc(
	name: defs.Item_Name,
	caster: ^Unit,
	targets: []^Unit,
	item_slot_index: int,
) {
	item_use_data(catalog.item_get(name), caster, targets, item_slot_index)
}

item_apply_spell_item_durability :: proc(caster: ^Unit, item_slot_index: int) {
	if caster == nil {
		log.errorf("ApplySpellItemDurability: caster is nil.")
		return
	}

	slot := item_at(caster, item_slot_index)
	if item_slot_is_empty(slot) {
		log.warn("ApplySpellItemDurability: slot empty (already removed?).")
		return
	}

	if slot.damaged {
		log.infof(
			"%s's [%v] was already damaged and breaks.",
			defs.name_display(caster.name),
			slot.name,
		)
		remove_item_at(caster, item_slot_index)
		return
	}

	if combat_chance(defs.ITEMS.break_chance) {
		set_item_damaged(caster, item_slot_index, true)
		log.infof(
			"%s's [%v] is now damaged (1/%d).",
			defs.name_display(caster.name),
			slot.name,
			defs.ITEMS.break_chance,
		)
	} else {
		log.infof(
			"%s's [%v] remains intact after spell cast.",
			defs.name_display(caster.name),
			slot.name,
		)
	}
}
