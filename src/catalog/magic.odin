package catalog

import "core:log"

import "../defs"

Magic_Data :: struct {
	name:           defs.Magic_Name,
	level:          int,
	mp_cost:        int,
	magic_type:     defs.Magic_Type,
	distance_range: defs.Tile_Range,
	target_range:   defs.Tile_Range,
	offensive:      bool,
	effect_type:    defs.Magic_Effect,
	effect_value:   int,
}

NO_SPELL_DATA :: Magic_Data {
	name           = .NoSpell,
	level          = 1,
	mp_cost        = 0,
	magic_type     = .Misc,
	distance_range = {0, 0},
	target_range   = {0, 0},
	offensive      = false,
	effect_type    = .None,
	effect_value   = 0,
}

magic_make :: proc(
	name: defs.Magic_Name,
	level: int,
	mp_cost: int,
	magic_type: defs.Magic_Type,
	distance: defs.Tile_Range,
	target: defs.Tile_Range,
	offensive: bool,
	effect_type: defs.Magic_Effect,
	effect_value: int,
) -> Magic_Data {
	return Magic_Data {
		name = name,
		level = level,
		mp_cost = mp_cost,
		magic_type = magic_type,
		distance_range = distance,
		target_range = target,
		offensive = offensive,
		effect_type = effect_type,
		effect_value = effect_value,
	}
}

magic_name_to_family :: proc(name: defs.Magic_Name) -> defs.Magic_Family {
	#partial switch name {
	case .Blaze1, .Blaze2, .Blaze3, .Blaze4:
		return .Blaze
	case .Freeze1, .Freeze2, .Freeze3, .Freeze4:
		return .Freeze
	case .Bolt1, .Bolt2, .Bolt3, .Bolt4:
		return .Bolt
	case .Heal1, .Heal2, .Heal3, .Heal4:
		return .Heal
	case .Aura1, .Aura2, .Aura3, .Aura4:
		return .Aura
	case .Slow1, .Slow2:
		return .Slow
	case .Quick1, .Quick2:
		return .Quick
	case .Desoul1, .Desoul2:
		return .Desoul
	case .Dispel1:
		return .Dispel
	case .Muddle1:
		return .Muddle
	case .Sleep1:
		return .Sleep
	case .Egress1:
		return .Egress
	case .Detox1:
		return .Detox
	case .Shield1:
		return .Shield
	case .Boost1:
		return .Boost
	case .NoSpell:
		return .NoSpell
	}

	log.errorf("magic_name_to_family: unknown %v", name)
	return .NoSpell
}

magic_data_family :: proc(data: Magic_Data) -> defs.Magic_Family {
	return magic_name_to_family(data.name)
}

magic_get :: proc(name: defs.Magic_Name) -> Magic_Data {
	switch name {
	case .NoSpell:
		return NO_SPELL_DATA
	case .Blaze1:
		return magic_make(.Blaze1, 1, 2, .Fire, {1, 2}, {0, 0}, true, .Damage, 7)
	case .Blaze2:
		return magic_make(.Blaze2, 2, 5, .Fire, {1, 2}, {0, 1}, true, .Damage, 8)
	case .Blaze3:
		return magic_make(.Blaze3, 3, 8, .Fire, {1, 2}, {0, 1}, true, .Damage, 12)
	case .Blaze4:
		return magic_make(.Blaze4, 4, 8, .Fire, {1, 2}, {0, 0}, true, .Damage, 32)
	case .Freeze1:
		return magic_make(.Freeze1, 1, 3, .Ice, {1, 2}, {0, 0}, true, .Damage, 8)
	case .Freeze2:
		return magic_make(.Freeze2, 2, 7, .Ice, {1, 2}, {0, 1}, true, .Damage, 10)
	case .Freeze3:
		return magic_make(.Freeze3, 3, 10, .Ice, {1, 3}, {0, 1}, true, .Damage, 15)
	case .Freeze4:
		return magic_make(.Freeze4, 4, 10, .Ice, {1, 4}, {0, 0}, true, .Damage, 40)
	case .Bolt1:
		return magic_make(.Bolt1, 1, 8, .Lightning, {1, 2}, {0, 1}, true, .Damage, 12)
	case .Bolt2:
		return magic_make(.Bolt2, 2, 15, .Lightning, {1, 3}, {0, 2}, true, .Damage, 13)
	case .Bolt3:
		return magic_make(.Bolt3, 3, 20, .Lightning, {1, 3}, {0, 2}, true, .Damage, 20)
	case .Bolt4:
		return magic_make(.Bolt4, 4, 20, .Lightning, {1, 3}, {0, 0}, true, .Damage, 48)
	case .Heal1:
		return magic_make(.Heal1, 1, 3, .Heal, {0, 1}, {0, 0}, false, .Heal, 12)
	case .Heal2:
		return magic_make(.Heal2, 2, 6, .Heal, {0, 2}, {0, 0}, false, .Heal, 12)
	case .Heal3:
		return magic_make(.Heal3, 3, 10, .Heal, {0, 3}, {0, 0}, false, .Heal, 24)
	case .Heal4:
		return magic_make(.Heal4, 4, 15, .Heal, {0, 1}, {0, 0}, false, .Heal, 1000)
	case .Aura1:
		return magic_make(.Aura1, 1, 7, .Heal, {0, 3}, {0, 1}, false, .Heal, 12)
	case .Aura2:
		return magic_make(.Aura2, 2, 11, .Heal, {0, 3}, {0, 2}, false, .Heal, 12)
	case .Aura3:
		return magic_make(.Aura3, 3, 15, .Heal, {0, 3}, {0, 2}, false, .Heal, 24)
	case .Aura4:
		return magic_make(.Aura4, 4, 18, .Heal, {0, 1000}, {0, 1000}, false, .Heal, 1000)
	case .Egress1:
		return magic_make(.Egress1, 1, 8, .Misc, {0, 0}, {0, 0}, false, .Egress, 0)
	case .Desoul1:
		return magic_make(.Desoul1, 1, 8, .Misc, {1, 2}, {0, 0}, true, .Desoul, 0)
	case .Desoul2:
		return magic_make(.Desoul2, 2, 15, .Misc, {1, 2}, {0, 1}, true, .Desoul, 0)
	case .Dispel1, .Muddle1, .Sleep1, .Detox1, .Shield1, .Boost1, .Slow1, .Slow2, .Quick1, .Quick2:
		return Magic_Data {
			name = name,
			level = 0,
			mp_cost = 0,
			magic_type = .Misc,
			distance_range = {0, 0},
			target_range = {0, 0},
			offensive = false,
			effect_type = .None,
			effect_value = 0,
		}
	}

	log.errorf("MagicDatabase.Get(): Unknown spell [%v]. Returning NoSpell.", name)
	return NO_SPELL_DATA
}
