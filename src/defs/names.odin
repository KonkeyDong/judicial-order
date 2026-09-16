package defs

import "core:reflect"

name_display :: proc(name: Name) -> string {
	switch name {
	case .Hale:
		return "Hale"
	case .Judy:
		return "Judy"
	case .Trudy:
		return "Trudy"
	case .Anthony:
		return "Anthony"
	case .Bellweather:
		return "Bellweather"
	}

	return "Unknown"
}

name_base :: proc(name: Name) -> string {
	return reflect.enum_string(name)
}

direction_walk_image :: proc(direction: Direction) -> string {
	switch direction {
	case .Up:
		return "WalkUp.png"
	case .Right:
		return "WalkRight.png"
	case .Down:
		return "WalkDown.png"
	case .Left:
		return "WalkLeft.png"
	}

	return "WalkDown.png"
}
