package game

import "core:fmt"
import "core:log"

import "../defs"
import units "../unit"
import rl "vendor:raylib"

block_occupant_count :: proc(block: ^Block) -> int {
	count := 0
	if block.occupant != nil {
		count += 1
	}

	if block.visitor != nil {
		count += 1
	}

	return count
}

block_is_fully_occupied :: proc(block: ^Block) -> bool {
	return block.occupant != nil && block.visitor != nil
}

block_enter :: proc(block: ^Block, unit: ^units.Unit) -> bool {
	if block_is_fully_occupied(block) {
		log.errorf("block_enter: Block %s already has two occupants.", block_print_coords(block))
		return false
	}

	if block.occupant == nil {
		log.debugf(
			"block_enter: %s occupying %s",
			defs.name_display(unit.name),
			block_print_coords(block),
		)
		block.occupant = unit
	} else {
		log.debugf(
			"block_enter: %s visiting %s",
			defs.name_display(unit.name),
			block_print_coords(block),
		)
		block.visitor = unit
	}

	unit.grid_x = block.grid_x
	unit.grid_y = block.grid_y
	unit.on_map = true
	return true
}

block_leave :: proc(block: ^Block, unit: ^units.Unit) {
	if block.visitor == unit {
		block.visitor = nil
	} else if block.occupant == unit {
		block.occupant = nil
	} else {
		log.errorf("block_leave: Block %s has no such occupant.", block_print_coords(block))
		return
	}

	if unit.on_map && unit.grid_x == block.grid_x && unit.grid_y == block.grid_y {
		unit.on_map = false
		unit.grid_x = -1
		unit.grid_y = -1
	}
}

block_top :: proc(block: ^Block) -> ^units.Unit {
	if block.visitor != nil {
		return block.visitor
	}

	return block.occupant
}

block_pixel_coords :: proc(block: ^Block) -> rl.Vector2 {
	return {f32(block.grid_x * defs.TILE_SIZE), f32(block.grid_y * defs.TILE_SIZE)}
}

block_print_coords :: proc(block: ^Block) -> string {
	return fmt.tprintf("[%d, %d]", block.grid_x, block.grid_y)
}
