package sprites

import "../defs"

item_icons: Icon_Set(defs.Item_Name)

item_icons_init :: proc() {
	icon_set_init(&item_icons, defs.PATHS.item_icons, defs.Item_Name.NoItem)
}

item_icons_destroy :: proc() {
	icon_set_destroy(&item_icons)
}

item_icons_load :: proc() {
	icon_set_load(&item_icons)
}

item_icons_tick :: proc() {
	icon_set_tick(&item_icons)
}

item_icons_set_selected :: proc(name: defs.Item_Name) {
	icon_set_set_selected(&item_icons, name)
}

item_icons_clear_selection :: proc() {
	icon_set_set_selected(&item_icons, defs.Item_Name.NoItem)
}

item_icons_get :: proc(name: defs.Item_Name) -> Sprite {
	return icon_set_get(&item_icons, name)
}

item_icons_get_selected :: proc(name: defs.Item_Name, is_selected: bool) -> Sprite {
	return icon_set_get_selected(&item_icons, name, is_selected)
}

item_icons_reset :: proc() {
	icon_set_reset(&item_icons)
}
