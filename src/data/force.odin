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
}

init :: proc() {
}

unit_get :: proc(name: defs.Name) -> unit.Unit_Data {
	#partial switch name {
	case .Hale:
		return HALE_DATA
	case .Judy:
		return JUDY_DATA
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
	}
}

make_unit :: proc(name: defs.Name, allocator := context.allocator) -> ^unit.Unit {
	return unit.make(unit_get(name), allocator)
}
