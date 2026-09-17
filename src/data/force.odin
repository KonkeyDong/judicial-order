package data

import "core:log"

import "../defs"
import "../unit"

HALE_DATA :: unit.Unit_Data {
	name          = .Hale,
	movement_type = .Warrior,
	movement      = 6,
	base_hp       = 15,
	base_mp       = 8,
	base_attack   = 10,
	base_defense  = 5,
	base_speed    = 5,
	friendly      = true,
	level         = 1,
	default_job   = {.Swordsman},
	attack_effect = .NormalAttack,
}

JUDY_DATA :: unit.Unit_Data {
	name          = .Judy,
	movement_type = .Warrior,
	movement      = 5,
	base_hp       = 10,
	base_mp       = 12,
	base_attack   = 3,
	base_defense  = 4,
	base_speed    = 6,
	friendly      = true,
	level         = 1,
	default_job   = {.Mage},
	attack_effect = .NormalAttack,
}

TRUDY_DATA :: unit.Unit_Data {
	name          = .Trudy,
	movement_type = .Warrior,
	movement      = 5,
	base_hp       = 10,
	base_mp       = 12,
	base_attack   = 3,
	base_defense  = 4,
	base_speed    = 6,
	friendly      = true,
	level         = 1,
	default_job   = {.Mage},
	attack_effect = .NormalAttack,
}

ANTHONY_DATA :: unit.Unit_Data {
	name          = .Anthony,
	movement_type = .Warrior,
	movement      = 6,
	base_hp       = 14,
	base_mp       = 0,
	base_attack   = 8,
	base_defense  = 6,
	base_speed    = 5,
	friendly      = true,
	level         = 1,
	default_job   = {.Knight},
	attack_effect = .NormalAttack,
}

BELLWEATHER_DATA :: unit.Unit_Data {
	name          = .Bellweather,
	movement_type = .Warrior,
	movement      = 5,
	base_hp       = 12,
	base_mp       = 0,
	base_attack   = 6,
	base_defense  = 5,
	base_speed    = 4,
	friendly      = false,
	level         = 1,
	default_job   = {.Monster},
	attack_effect = .NormalAttack,
}

init :: proc() {
}

unit_get :: proc(name: defs.Name) -> unit.Unit_Data {
	switch name {
	case .Hale:
		return HALE_DATA
	case .Judy:
		return JUDY_DATA
	case .Trudy:
		return TRUDY_DATA
	case .Anthony:
		return ANTHONY_DATA
	case .Bellweather:
		return BELLWEATHER_DATA
	}

	log.warnf("UnitDatabase.Get(): No data for [%v]. Using default template.", name)
	return unit.Unit_Data {
		name = name,
		movement_type = .Warrior,
		movement = 5,
		base_hp = 10,
		base_mp = 0,
		base_attack = 5,
		base_defense = 5,
		base_speed = 5,
		friendly = false,
		level = 1,
		default_job = defs.JOB_ANY,
		attack_effect = .NormalAttack,
	}
}

make_unit :: proc(name: defs.Name, allocator := context.allocator) -> ^unit.Unit {
	return unit.make(unit_get(name), allocator)
}
