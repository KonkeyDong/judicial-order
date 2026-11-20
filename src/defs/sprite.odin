package defs

import rl "vendor:raylib"

Frame_Rect :: struct {
	x:        int `json:"x"`,
	y:        int `json:"y"`,
	w:        int `json:"w"`,
	h:        int `json:"h"`,
	offset_x: int `json:"offsetX"`,
	offset_y: int `json:"offsetY"`,
}

Sprite :: struct {
	texture:      rl.Texture2D,
	frame:        Frame_Rect,
	owns_texture: bool,
}
