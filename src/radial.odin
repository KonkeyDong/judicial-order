package game

import "defs"
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

radial_center :: proc(game: ^Game, y_factor := f32(RADIAL_Y_FACTOR)) -> rl.Vector2 {
	if game.window.scale == 0 {
		return {}
	}

	return {
		f32(game.window.width) / 2 / game.window.scale,
		f32(game.window.height) * y_factor / game.window.scale,
	}
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
