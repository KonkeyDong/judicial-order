package sprites

import "../defs"
import rl "vendor:raylib"

RADIAL_Y_FACTOR :: 0.75
RADIAL_INFO_BOX_OFFSET_X :: 65
RADIAL_MENU_MESSAGE_OFFSET_Y :: 18

command_icon_display_name :: proc(icon: defs.Command_Icon) -> string {
	switch icon {
	case .Yes:
		return "Yes"
	case .No:
		return "No"
	case .Talk:
		return "Talk"
	case .Magic:
		return "Magic"
	case .Item:
		return "Item"
	case .Search:
		return "Search"
	case .Attack:
		return "Attack"
	case .Stay:
		return "Stay"
	case .Use:
		return "Use"
	case .Give:
		return "Give"
	case .Equip:
		return "Equip"
	case .Drop:
		return "Drop"
	case .Map:
		return "Map"
	case .Speed:
		return "Speed"
	case .Message:
		return "Message"
	case .Quit:
		return "Quit"
	case .Save:
		return "Save"
	case .Cure:
		return "Cure"
	case .Raise:
		return "Raise"
	case .Promote:
		return "Promote"
	case .Buy:
		return "Buy"
	case .Deals:
		return "Deals"
	case .Sell:
		return "Sell"
	case .Repair:
		return "Repair"
	}

	return "Command"
}

direction_menu_offset :: proc(direction: defs.Direction) -> rl.Vector2 {
	switch direction {
	case .Up:
		return {0, -1}
	case .Left:
		return {-1, 0}
	case .Right:
		return {1, 0}
	case .Down:
		return {0, 1}
	}

	return {}
}

radial_index_for_direction :: proc(direction: defs.Direction) -> int {
	switch direction {
	case .Up:
		return 0
	case .Left:
		return 1
	case .Right:
		return 2
	case .Down:
		return 3
	}

	return -1
}

radial_center :: proc(window: defs.Window_View, y_factor := f32(RADIAL_Y_FACTOR)) -> rl.Vector2 {
	if window.scale == 0 {
		return {}
	}

	return {f32(window.width) / 2 / window.scale, f32(window.height) * y_factor / window.scale}
}

radial_icon_position :: proc(center: rl.Vector2, direction: defs.Direction) -> rl.Vector2 {
	offset := direction_menu_offset(direction)
	return center + offset * f32(defs.TILE_SIZE)
}

radial_info_box_position :: proc(center: rl.Vector2) -> rl.Vector2 {
	return {center.x + RADIAL_INFO_BOX_OFFSET_X, center.y}
}

radial_menu_message_position :: proc(center: rl.Vector2) -> rl.Vector2 {
	return {center.x + RADIAL_INFO_BOX_OFFSET_X, center.y + RADIAL_MENU_MESSAGE_OFFSET_Y}
}

Command_Radial_Slot :: struct {
	direction: defs.Direction,
	icon:      defs.Command_Icon,
}

BATTLE_ACTION_COMMANDS :: [4]Command_Radial_Slot {
	{.Up, .Attack},
	{.Left, .Magic},
	{.Right, .Item},
	{.Down, .Stay},
}

BATTLE_ITEM_COMMANDS :: [4]Command_Radial_Slot {
	{.Up, .Use},
	{.Left, .Give},
	{.Right, .Equip},
	{.Down, .Drop},
}

radial_draw_command_icons :: proc(
	scale: f32,
	center: rl.Vector2,
	commands: [4]Command_Radial_Slot,
) {
	for slot in commands {
		renderer_draw_command_icon(scale, slot.icon, radial_icon_position(center, slot.direction))
	}
}
