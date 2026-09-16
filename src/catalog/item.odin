package catalog

import "core:log"

import "../defs"

Tile_Range :: struct {
	min, max: int,
}

Item_Data :: struct {
	name:           defs.Item_Name,
	type:           defs.Item_Type,
	price:          int,
	attack:         int,
	distance_range: Tile_Range,
	allowed_jobs:   defs.Job,
	cursed:         bool,
	effect_type:    defs.Item_Effect,
	effect_value:   int,
	spell_name:     defs.Magic_Name,
}

NO_ITEM_DATA :: Item_Data {
	name           = .NoItem,
	type           = .Consumable,
	price          = 0,
	attack         = 0,
	distance_range = {0, 0},
	allowed_jobs   = defs.JOB_ANY,
	cursed         = false,
	effect_type    = .None,
	effect_value   = 0,
	spell_name     = .NoSpell,
}

UNARMED_DATA :: Item_Data {
	name           = .Unarmed,
	type           = .Unarmed,
	price          = 0,
	attack         = 0,
	distance_range = {1, 1},
	allowed_jobs   = defs.JOB_ANY,
	cursed         = false,
	effect_type    = .None,
	effect_value   = 0,
	spell_name     = .NoSpell,
}

SHORT_SWORD_DATA :: Item_Data {
	name           = .ShortSword,
	type           = .Sword,
	price          = 100,
	attack         = 5,
	distance_range = {1, 1},
	allowed_jobs   = {.Swordsman, .Warrior, .Birdman},
	cursed         = false,
	effect_type    = .None,
	effect_value   = 0,
	spell_name     = .NoSpell,
}

MEDICAL_HERB_DATA :: Item_Data {
	name           = .MedicalHerb,
	type           = .Consumable,
	price          = 10,
	attack         = 0,
	distance_range = {0, 1},
	allowed_jobs   = defs.JOB_ANY,
	cursed         = false,
	effect_type    = .Heal,
	effect_value   = 10,
	spell_name     = .NoSpell,
}

init :: proc() {
}

item_get :: proc(name: defs.Item_Name) -> Item_Data {
	switch name {
	case .NoItem:
		return NO_ITEM_DATA
	case .Unarmed:
		return UNARMED_DATA
	case .ShortSword:
		return SHORT_SWORD_DATA
	case .MedicalHerb:
		return MEDICAL_HERB_DATA
	}

	log.errorf("ItemDatabase.Get(): Unknown item [%v]. Returning NoItem.", name)
	return NO_ITEM_DATA
}

item_sell_price :: proc(data: Item_Data) -> int {
	return int(f32(data.price) * 0.75)
}

item_type_is_weapon :: proc(item_type: defs.Item_Type) -> bool {
	#partial switch item_type {
	case .Unarmed, .Sword, .Axe, .Staff, .Arrow, .Spear, .Lance:
		return true
	}

	return false
}
