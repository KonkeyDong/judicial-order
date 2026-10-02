package sprites

import "core:fmt"
import "core:log"
import "core:reflect"

import "../defs"
import "../unit"
import rl "vendor:raylib"

// Somber-Inertia Battle.BuildKey uses PascalCase Promoted/Unpromoted, not the folder names.
battle_position_promoted :: "Promoted"
battle_position_unpromoted :: "Unpromoted"

Battle_Sprite_Position :: struct {
	key:      string,
	position: rl.Vector2,
}

// Key is Name_Promoted|Unpromoted_Weapon. battle_sprite_position looks a unit up in this table.
BATTLE_SPRITE_POSITIONS :: [?]Battle_Sprite_Position{{"LawProfessor_Unpromoted_Unarmed", {40, 50}}}

@(private)
battle_sprite_position_key :: proc(target: ^unit.Unit) -> string {
	if target == nil {
		log.panic("target is nil.")
	}

	promo := battle_position_promoted if unit.is_promoted(target) else battle_position_unpromoted
	weapon := reflect.enum_string(unit.equipped_weapon_name(target))
	return fmt.tprintf("%s_%s_%s", defs.name_base(target.name), promo, weapon)
}

battle_sprite_position :: proc(target: ^unit.Unit, fallback: rl.Vector2) -> rl.Vector2 {
	if target == nil {
		log.panic("target is nil.")
	}

	key := battle_sprite_position_key(target)
	for entry in BATTLE_SPRITE_POSITIONS {
		if entry.key == key {
			return entry.position
		}
	}

	// Heroes have no rows yet. A missing enemy row is the one worth seeing.
	if !target.friendly {
		log.warnf("No battle sprite position for %s.", key)
	}

	return fallback
}
