package game

import "core:log"

import "../catalog"
import "../defs"
import "../sprites"
import "../timers"
import units "../unit"
import rl "vendor:raylib"

Grid_Coord :: struct {
	x, y: int,
}

Grid :: struct {
	width, height: int,
	block_size:    int,
	blocks:        []Block,
	range_mask:    []bool,
	range_coords:  [dynamic]Grid_Coord,
	range_tint:    timers.Oscillator(rl.Color),
}

GRID_ADJACENT_OFFSETS :: [4]Grid_Coord{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

GRID_GIVE_DISTANCE_RANGE :: defs.Tile_Range {
	min = 1,
	max = 1,
}

// 0 = undefined. Warrior row only this batch. C# Overgrowth → Marsh.
grid_movement_cost := [defs.Movement_Type][defs.Terrain]int {
	.Warrior = {
		.Road = 1,
		.Plains = 1,
		.Marsh = 1,
		.Forest = 2,
		.Hill = 3,
		.Mountain = 0,
		.Sand = 2,
		.Impassable = 0,
		.Water = 0,
		.Floor = 0,
	},
	.Flyer = {},
	.Horse = {},
	.Mage = {},
	.Thief = {},
	.Archer = {},
	.Werewolf = {},
}

grid_init :: proc(grid: ^Grid, width, height: int) {
	if width <= 0 || height <= 0 {
		log.errorf("grid_init: invalid size %dx%d.", width, height)
		return
	}

	log.infof("Creating %dx%d grid...", width, height)
	grid.width = width
	grid.height = height
	grid.block_size = int(f32(defs.TILE_SIZE) * defs.WINDOW.scale)

	count := width * height
	grid.blocks = make([]Block, count)
	grid.range_mask = make([]bool, count)
	grid.range_coords = make([dynamic]Grid_Coord)

	timers.oscillator_init(
		&grid.range_tint,
		defs.range_tint_levels[:],
		defs.ANIMATIONS.range_tint_frame_delay,
	)

	sprites_ready := sprites.cache.textures.allocator.procedure != nil
	grass: rl.Texture2D
	forest: rl.Texture2D
	if sprites_ready {
		grass = sprites.load(defs.PATHS.grass_tile)
		forest = sprites.load(defs.PATHS.forest_tile)
	}

	for x in 0 ..< width {
		for y in 0 ..< height {
			block := grid_block_at(grid, x, y)
			block.texture = grass
			block.terrain = .Plains
			block.grid_x = x
			block.grid_y = y
		}
	}

	if grid_in_bounds(grid, 0, 1) {
		block := grid_block_at(grid, 0, 1)
		block.texture = forest
		block.terrain = .Forest
	}

	if grid_in_bounds(grid, 0, 2) {
		block := grid_block_at(grid, 0, 2)
		block.texture = forest
		block.terrain = .Forest
	}

	log.info("Grid initialization complete.")
}

grid_destroy :: proc(grid: ^Grid) {
	delete(grid.blocks)
	delete(grid.range_mask)
	delete(grid.range_coords)

	grid.blocks = nil
	grid.range_mask = nil
	grid.range_coords = nil
}

grid_in_bounds :: proc(grid: ^Grid, x, y: int) -> bool {
	return x >= 0 && x < grid.width && y >= 0 && y < grid.height
}

grid_index :: proc(grid: ^Grid, x, y: int) -> int {
	return x * grid.height + y
}

grid_block_at :: proc(grid: ^Grid, x, y: int) -> ^Block {
	if !grid_in_bounds(grid, x, y) {
		log.errorf("grid_block_at: (%d, %d) out of bounds.", x, y)
		return nil
	}

	return &grid.blocks[grid_index(grid, x, y)]
}

grid_unit_block :: proc(grid: ^Grid, unit: ^units.Unit) -> ^Block {
	if unit == nil || !unit.on_map {
		return nil
	}

	return grid_block_at(grid, unit.grid_x, unit.grid_y)
}

grid_clear_range_set :: proc(grid: ^Grid) {
	for index in 0 ..< len(grid.range_mask) {
		grid.range_mask[index] = false
	}

	clear(&grid.range_coords)
}

grid_in_range :: proc(grid: ^Grid, x, y: int) -> bool {
	if !grid_in_bounds(grid, x, y) {
		return false
	}

	return grid.range_mask[grid_index(grid, x, y)]
}

grid_range_add :: proc(grid: ^Grid, x, y: int) {
	if !grid_in_bounds(grid, x, y) {
		return
	}

	index := grid_index(grid, x, y)
	if grid.range_mask[index] {
		return
	}

	grid.range_mask[index] = true
	append(&grid.range_coords, Grid_Coord{x = x, y = y})
}

grid_adjacent_blocks :: proc(grid: ^Grid, block: ^Block, out_blocks: []^Block) -> int {
	if block == nil {
		return 0
	}

	count := 0
	for offset in GRID_ADJACENT_OFFSETS {
		neighbor_x := block.grid_x + offset.x
		neighbor_y := block.grid_y + offset.y
		if grid_in_bounds(grid, neighbor_x, neighbor_y) && count < len(out_blocks) {
			out_blocks[count] = grid_block_at(grid, neighbor_x, neighbor_y)
			count += 1
		}
	}

	return count
}

grid_coord_in_direction :: proc(x, y: int, direction: defs.Direction) -> (new_x, new_y: int) {
	new_x = x
	new_y = y
	switch direction {
	case .Up:
		new_y -= 1
	case .Down:
		new_y += 1
	case .Left:
		new_x -= 1
	case .Right:
		new_x += 1
	}

	return
}

grid_terrain_cost :: proc(
	movement_type: defs.Movement_Type,
	terrain: defs.Terrain,
) -> (
	cost: int,
	ok: bool,
) {
	cost = grid_movement_cost[movement_type][terrain]
	if cost == 0 {
		log.errorf(
			"No movement type [%v] cost or terrain type [%v] found in movement cost table.",
			movement_type,
			terrain,
		)
		return defs.WORLD_MAP.max_movement_cost, false
	}

	return cost, true
}

grid_place_unit :: proc(grid: ^Grid, unit: ^units.Unit, x, y: int) -> bool {
	if unit == nil {
		log.errorf("grid_place_unit: unit is nil.")
		return false
	}

	if !grid_in_bounds(grid, x, y) {
		log.errorf("Target position (%d, %d) is outside grid bounds.", x, y)
		return false
	}

	dest := grid_block_at(grid, x, y)
	already_here := unit.on_map && unit.grid_x == x && unit.grid_y == y
	if block_is_fully_occupied(dest) && !already_here {
		log.errorf(
			"grid_place_unit: Block %s already has two occupants.",
			block_print_coords(dest),
		)
		return false
	}

	if already_here {
		if !unit.is_animating {
			units.snap_to_current_tile(unit)
		}

		return true
	}

	if unit.on_map {
		origin := grid_unit_block(grid, unit)
		if origin != nil {
			block_leave(origin, unit)
		}
	}

	if !block_enter(dest, unit) {
		log.errorf(
			"grid_place_unit: block_enter failed at %s after leave; unit is off the map.",
			block_print_coords(dest),
		)
		return false
	}

	if !unit.is_animating {
		units.snap_to_current_tile(unit)
	}

	log.debugf("Unit '%s' placed at %s.", defs.name_display(unit.name), block_print_coords(dest))
	return true
}

grid_remove_dead_units :: proc(grid: ^Grid, dead_units: []^units.Unit) {
	if len(dead_units) == 0 {
		return
	}

	log.debugf("Grid::RemoveDeadUnitsFromGrid(): removing %d dead unit(s).", len(dead_units))
	for dead_unit in dead_units {
		if dead_unit.on_map {
			block := grid_unit_block(grid, dead_unit)
			if block != nil {
				count_before := block_occupant_count(block)
				log.debugf(
					"  → Removing %s from block %s (stack size before = %d)",
					defs.name_display(dead_unit.name),
					block_print_coords(block),
					count_before,
				)
				block_leave(block, dead_unit)
				log.debugf("  → Stack size after pop = %d", block_occupant_count(block))
			} else {
				log.warnf("Dead unit '%s' had no map position.", defs.name_display(dead_unit.name))
			}
		} else {
			log.warnf("Dead unit '%s' had no map position.", defs.name_display(dead_unit.name))
		}
	}
}

grid_move_unit_in_direction :: proc(
	grid: ^Grid,
	unit: ^units.Unit,
	direction: defs.Direction,
) -> bool {
	if unit == nil || !unit.on_map {
		log.warn("MoveUnitInDirection called with null unit or block.")
		return false
	}

	unit.facing_direction = direction
	new_x, new_y := grid_coord_in_direction(unit.grid_x, unit.grid_y, direction)
	if !grid_in_bounds(grid, new_x, new_y) {
		log.debugf("Movement blocked: out of bounds (%d, %d)", new_x, new_y)
		return false
	}

	if !grid_in_range(grid, new_x, new_y) {
		log.debugf("Movement blocked: block coordinate [%d, %d] not in range set.", new_x, new_y)
		return false
	}

	dest := grid_block_at(grid, new_x, new_y)
	already_here := unit.grid_x == new_x && unit.grid_y == new_y
	if block_is_fully_occupied(dest) && !already_here {
		log.debugf("Movement blocked: destination %s is fully occupied.", block_print_coords(dest))
		return false
	}

	units.start_moving_to(unit, block_pixel_coords(dest))
	return grid_place_unit(grid, unit, new_x, new_y)
}

grid_calculate_unit_movement_range :: proc(grid: ^Grid, unit: ^units.Unit) {
	if unit == nil {
		log.errorf("CalculateUnitMovementRange() unit is null.")
		return
	}

	if !unit.on_map {
		log.errorf("Unit %s does not contain a block.", defs.name_display(unit.name))
		return
	}

	if !units.movement_origin_valid(unit.movement_origin) {
		unit.movement_origin = {
			grid_x = unit.grid_x,
			grid_y = unit.grid_y,
		}
	}

	origin := unit.movement_origin
	if !grid_in_bounds(grid, origin.grid_x, origin.grid_y) {
		log.errorf(
			"CalculateUnitMovementRange(): origin (%d,%d) out of bounds.",
			origin.grid_x,
			origin.grid_y,
		)
		return
	}

	grid_clear_range_set(grid)
	cost_to_reach := make(map[Grid_Coord]int)
	queue := make([dynamic]^Block)
	defer delete(cost_to_reach)
	defer delete(queue)

	start := grid_block_at(grid, origin.grid_x, origin.grid_y)
	grid_range_add(grid, start.grid_x, start.grid_y)
	cost_to_reach[Grid_Coord{x = start.grid_x, y = start.grid_y}] = 0
	append(&queue, start)
	queue_start := 0

	neighbors: [4]^Block
	for queue_start < len(queue) {
		current := queue[queue_start]
		queue_start += 1
		current_coord := Grid_Coord {
			x = current.grid_x,
			y = current.grid_y,
		}
		
		current_cost := cost_to_reach[current_coord]
		count := grid_adjacent_blocks(grid, current, neighbors[:])
		for i in 0 ..< count {
			neighbor := neighbors[i]
			coord := Grid_Coord {
				x = neighbor.grid_x,
				y = neighbor.grid_y,
			}
			if grid_in_range(grid, coord.x, coord.y) {
				continue
			}

			top := block_top(neighbor)
			enter_cost: int
			if top != nil && unit.friendly != top.friendly {
				enter_cost = defs.WORLD_MAP.max_movement_cost
			} else {
				enter_cost, _ = grid_terrain_cost(unit.movement_type, neighbor.terrain)
			}

			total_cost := current_cost + enter_cost
			if total_cost <= unit.movement {
				grid_range_add(grid, coord.x, coord.y)
				cost_to_reach[coord] = total_cost
				append(&queue, neighbor)
			}
		}
	}
}

grid_fill_effect_distance_range :: proc(
	grid: ^Grid,
	unit: ^units.Unit,
	tile_range: defs.Tile_Range,
) {
	grid_clear_range_set(grid)
	if unit == nil || !unit.on_map {
		log.errorf("FillEffectDistanceRange: unit is not on a block.")
		return
	}

	start := grid_unit_block(grid, unit)
	visited := make([]bool, grid.width * grid.height)
	queue := make([dynamic]^Block)
	defer delete(visited)
	defer delete(queue)

	append(&queue, start)
	visited[grid_index(grid, start.grid_x, start.grid_y)] = true
	queue_start := 0
	neighbors: [4]^Block

	for queue_start < len(queue) {
		current := queue[queue_start]
		queue_start += 1
		distance := uint(abs(current.grid_x - start.grid_x) + abs(current.grid_y - start.grid_y))
		if distance >= tile_range.min && distance <= tile_range.max {
			grid_range_add(grid, current.grid_x, current.grid_y)
		}

		if distance >= tile_range.max {
			continue
		}

		count := grid_adjacent_blocks(grid, current, neighbors[:])
		for i in 0 ..< count {
			neighbor := neighbors[i]
			index := grid_index(grid, neighbor.grid_x, neighbor.grid_y)
			if !visited[index] {
				visited[index] = true
				append(&queue, neighbor)
			}
		}
	}
}

grid_calculate_weapon_attack_range :: proc(grid: ^Grid, unit: ^units.Unit) {
	if unit == nil || !unit.on_map {
		return
	}

	grid_fill_effect_distance_range(grid, unit, units.equipped_weapon_data(unit).distance_range)
}

grid_calculate_give_range :: proc(grid: ^Grid, unit: ^units.Unit) {
	if unit == nil || !unit.on_map {
		return
	}

	grid_fill_effect_distance_range(grid, unit, GRID_GIVE_DISTANCE_RANGE)
}

grid_calculate_magic_attack_range :: proc(
	grid: ^Grid,
	unit: ^units.Unit,
	magic: catalog.Magic_Data,
) {
	if unit == nil || !unit.on_map {
		return
	}

	grid_fill_effect_distance_range(grid, unit, magic.distance_range)
}

grid_calculate_item_use_range :: proc(grid: ^Grid, unit: ^units.Unit, item: catalog.Item_Data) {
	if unit == nil || !unit.on_map {
		return
	}

	grid_fill_effect_distance_range(grid, unit, item.distance_range)
}

grid_calculate_spell_effect_range :: proc(
	grid: ^Grid,
	unit: ^units.Unit,
	magic: catalog.Magic_Data,
) {
	if unit == nil || !unit.on_map {
		return
	}

	grid_fill_effect_distance_range(grid, unit, magic.target_range)
}

grid_blocks_from_range_set :: proc(grid: ^Grid, allocator := context.allocator) -> []^Block {
	blocks := make([]^Block, len(grid.range_coords), allocator)
	for coord, index in grid.range_coords {
		blocks[index] = grid_block_at(grid, coord.x, coord.y)
	}

	return blocks
}

grid_units_in_range :: proc(grid: ^Grid, allocator := context.allocator) -> []^units.Unit {
	log.debug("Grid::BuildListOfUnitsInRange() building list of units in RangeSet.")
	found := make([dynamic]^units.Unit, allocator)

	for coord in grid.range_coords {
		block := grid_block_at(grid, coord.x, coord.y)
		top := block_top(block)
		if top == nil {
			continue
		}

		log.debugf(
			"   occupant [%s] found at %s",
			defs.name_display(top.name),
			block_print_coords(block),
		)
		append(&found, top)
	}

	log.debugf("   unitsInRange = [%d]. ", len(found))
	result := make([]^units.Unit, len(found), allocator)
	copy(result, found[:])
	delete(found)

	return result
}
