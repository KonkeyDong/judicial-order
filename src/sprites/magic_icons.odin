package sprites

import "../defs"

magic_icons: Icon_Set(defs.Magic_Family)

magic_icons_init :: proc() {
	// C# default(MagicFamily) is Blaze (enum zero), not NoSpell.
	icon_set_init(&magic_icons, defs.PATHS.magic_icons, defs.Magic_Family.Blaze)
}

magic_icons_destroy :: proc() {
	icon_set_destroy(&magic_icons)
}

magic_icons_load :: proc() {
	icon_set_load(&magic_icons)
}

magic_icons_tick :: proc() {
	icon_set_tick(&magic_icons)
}

magic_icons_set_selected :: proc(family: defs.Magic_Family) {
	icon_set_set_selected(&magic_icons, family)
}

magic_icons_get :: proc(family: defs.Magic_Family) -> Sprite {
	return icon_set_get(&magic_icons, family)
}

magic_icons_reset :: proc() {
	icon_set_reset(&magic_icons)
}
