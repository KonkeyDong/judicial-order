package sprites

import "core:fmt"
import "core:log"
import "core:os"
import "core:slice"

import "../defs"

// One character whose battle folder exists. hero is true when that folder is under heroes.
Sprite_Demo_Entry :: struct {
	name:    defs.Name,
	display: string,
	hero:    bool,
}

// Alphabetical. Attack is before Idle.
SPRITE_DEMO_ANIMATION_LABELS := [?]string{"Attack", "Idle"}

SPRITE_DEMO_ANIMATION_ATTACK :: 0
SPRITE_DEMO_ANIMATION_IDLE :: 1

sprite_demo_row_label :: proc(entry: Sprite_Demo_Entry) -> string {
	side := "H" if entry.hero else "M"
	return fmt.tprintf("%s %s", side, entry.display)
}

sprite_demo_sort :: proc(entries: []Sprite_Demo_Entry) {
	slice.sort_by(entries, proc(a, b: Sprite_Demo_Entry) -> bool {
		return a.display < b.display
	})
}

// Sara when her battle folder is listed. Otherwise the first sorted name.
sprite_demo_default_character :: proc(entries: []Sprite_Demo_Entry) -> int {
	for entry, i in entries {
		if entry.name == .Sara {
			return i
		}
	}

	if len(entries) == 0 {
		log.warn("Sprite demo: no characters with a battle folder.")
		return 0
	}

	log.warnf("Sprite demo: Sara has no battle folder. Showing %s.", entries[0].display)
	return 0
}

// Names that have heroes/{name}/battle or monsters/{name}/battle. Sorted by display name.
sprite_demo_collect :: proc() -> [dynamic]Sprite_Demo_Entry {
	entries := make([dynamic]Sprite_Demo_Entry)
	for name in defs.Name {
		file := defs.name_file(defs.name_base(name))
		if file == "" {
			continue
		}

		hero_dir := join_path({defs.PATHS.heroes, file, defs.PATHS.battle})
		monster_dir := join_path({defs.PATHS.monsters, file, defs.PATHS.battle})
		hero := os.is_directory(hero_dir)
		if !hero && !os.is_directory(monster_dir) {
			continue
		}

		append(
			&entries,
			Sprite_Demo_Entry {
				name = name,
				display = defs.name_display(name),
				hero = hero,
			},
		)
	}

	sprite_demo_sort(entries[:])
	return entries
}

// Loads whichever of the idle and attack sheets exist. A missing sheet is an empty list.
sprite_demo_load_sheets :: proc(entry: Sprite_Demo_Entry) -> (idle, attack: [dynamic]Sprite) {
	idle = sprite_demo_load_sheet(entry, false)
	attack = sprite_demo_load_sheet(entry, true)
	return
}

@(private)
sprite_demo_load_sheet :: proc(entry: Sprite_Demo_Entry, attack: bool) -> [dynamic]Sprite {
	file := defs.name_file(defs.name_base(entry.name))
	if file == "" {
		return nil
	}

	root := defs.PATHS.heroes if entry.hero else defs.PATHS.monsters
	dir := join_path({root, file, defs.PATHS.battle})
	png_name := defs.PATHS.attack_png if attack else defs.PATHS.idle_png
	json_name := defs.PATHS.attack_json if attack else defs.PATHS.idle_json
	return battle_load_sheet(join_path({dir, png_name}), join_path({dir, json_name}))
}
