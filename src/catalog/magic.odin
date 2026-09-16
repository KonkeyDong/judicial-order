package catalog

import "core:log"

import "../defs"

Magic_Data :: struct {
	name:           defs.Magic_Name,
	level:          int,
	mp_cost:        int,
	magic_type:     defs.Magic_Type,
	distance_range: Tile_Range,
	target_range:   Tile_Range,
	offensive:      bool,
	effect_type:    defs.Magic_Effect,
	effect_value:   int,
}

NO_SPELL_DATA :: Magic_Data {
	name           = .NoSpell,
	level          = 0,
	mp_cost        = 0,
	magic_type     = .Misc,
	distance_range = {0, 0},
	target_range   = {0, 0},
	offensive      = false,
	effect_type    = .None,
	effect_value   = 0,
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
	if name == .NoSpell {
		return NO_SPELL_DATA
	}

	#partial switch name {
	case .Blaze1,
	     .Blaze2,
	     .Blaze3,
	     .Blaze4,
	     .Freeze1,
	     .Freeze2,
	     .Freeze3,
	     .Freeze4,
	     .Bolt1,
	     .Bolt2,
	     .Bolt3,
	     .Bolt4,
	     .Desoul1,
	     .Desoul2,
	     .Dispel1,
	     .Muddle1,
	     .Sleep1,
	     .Egress1,
	     .Detox1,
	     .Shield1,
	     .Boost1,
	     .Slow1,
	     .Slow2,
	     .Quick1,
	     .Quick2,
	     .Heal1,
	     .Heal2,
	     .Heal3,
	     .Heal4,
	     .Aura1,
	     .Aura2,
	     .Aura3,
	     .Aura4:
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
