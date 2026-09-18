package sprites

import "../defs"

command_icons: Icon_Set(defs.Command_Icon)

command_icons_init :: proc() {
	icon_set_init(&command_icons, defs.PATHS.command_icons, defs.Command_Icon.Attack)
}

command_icons_destroy :: proc() {
	icon_set_destroy(&command_icons)
}

command_icons_load :: proc() {
	icon_set_load(&command_icons)
}

command_icons_tick :: proc() {
	icon_set_tick(&command_icons)
}

command_icons_set_selected :: proc(icon: defs.Command_Icon) {
	icon_set_set_selected(&command_icons, icon)
}

command_icons_get :: proc(icon: defs.Command_Icon) -> Sprite {
	return icon_set_get(&command_icons, icon)
}

command_icons_reset :: proc() {
	icon_set_reset(&command_icons)
}
