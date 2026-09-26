package grid

import "../defs"
import "../timers"
import units "../unit"
import rl "vendor:raylib"

// Grid lives outside package game so package sprites can draw it.
// game already imports sprites, so sprites cannot import game.

Grid_Coord :: struct {
	x, y: int,
}

Block :: struct {
	texture:        rl.Texture2D,
	terrain:        defs.Terrain,
	grid_x, grid_y: int,
	occupant:       ^units.Unit,
	visitor:        ^units.Unit,
}

Grid :: struct {
	width, height: int,
	block_size:    int,
	blocks:        []Block,
	range_mask:    []bool,
	range_coords:  [dynamic]Grid_Coord,
	range_tint:    timers.Oscillator(rl.Color),
}
