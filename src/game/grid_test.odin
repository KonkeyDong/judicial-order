package game

import "core:testing"

import "../catalog"
import "../data"
import "../defs"
import "../timers"
import units "../unit"

test_grid_small :: proc() -> Grid {
	grid: Grid
	grid_init(&grid, 5, 5)
	return grid
}

test_grid_full :: proc() -> Grid {
	grid: Grid
	grid_init(&grid, 11, 10)
	return grid
}

@(test)
test_init_stub_map :: proc(test: ^testing.T) {
	grid := test_grid_full()
	defer grid_destroy(&grid)

	testing.expect_value(test, grid.width, 11)
	testing.expect_value(test, grid.height, 10)
	testing.expect_value(test, grid_block_at(&grid, 0, 0).terrain, defs.Terrain.Plains)
	testing.expect_value(test, grid_block_at(&grid, 0, 1).terrain, defs.Terrain.Forest)
	testing.expect_value(test, grid_block_at(&grid, 0, 2).terrain, defs.Terrain.Forest)
	testing.expect(test, !grid_in_bounds(&grid, -1, 0))
	old_logger := context.logger
	context.logger = {}
	testing.expect(test, grid_block_at(&grid, -1, 0) == nil)
	context.logger = old_logger
}

@(test)
test_place_leave_then_enter :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	testing.expect(test, hale.on_map)
	testing.expect_value(test, hale.grid_x, 3)
	testing.expect_value(test, hale.grid_y, 1)
	testing.expect(test, grid_block_at(&grid, 3, 1).occupant == hale)
	testing.expect(test, grid_place_unit(&grid, hale, 3, 2))
	testing.expect(test, grid_block_at(&grid, 3, 1).occupant == nil)
	testing.expect(test, grid_block_at(&grid, 3, 2).occupant == hale)
}

@(test)
test_visitor_slot :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer units.destroy(hale)
	defer units.destroy(judy)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	testing.expect(test, grid_place_unit(&grid, judy, 3, 1))
	block := grid_block_at(&grid, 3, 1)
	testing.expect(test, block.occupant == hale)
	testing.expect(test, block.visitor == judy)
	testing.expect(test, block_top(block) == judy)
	testing.expect(test, block_is_fully_occupied(block))
}

@(test)
test_refuse_third :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale_a := data.make_unit(.Hale)
	hale_b := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer units.destroy(hale_a)
	defer units.destroy(hale_b)
	defer units.destroy(judy)

	testing.expect(test, grid_place_unit(&grid, hale_a, 3, 1))
	testing.expect(test, grid_place_unit(&grid, judy, 3, 1))
	testing.expect(test, grid_place_unit(&grid, hale_b, 4, 1))
	old_logger := context.logger
	context.logger = {}
	ok := grid_place_unit(&grid, hale_b, 3, 1)
	context.logger = old_logger
	testing.expect(test, !ok)
	testing.expect(test, hale_b.on_map)
	testing.expect_value(test, hale_b.grid_x, 4)
	testing.expect_value(test, hale_b.grid_y, 1)
}

@(test)
test_visitor_leaves_occupant_stays :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer units.destroy(hale)
	defer units.destroy(judy)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	testing.expect(test, grid_place_unit(&grid, judy, 3, 1))
	testing.expect(test, grid_place_unit(&grid, judy, 4, 1))
	block := grid_block_at(&grid, 3, 1)
	testing.expect(test, block.occupant == hale)
	testing.expect(test, block.visitor == nil)
	testing.expect(test, grid_block_at(&grid, 4, 1).occupant == judy)
}

@(test)
test_remove_dead :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	dead := []^units.Unit{hale}
	grid_remove_dead_units(&grid, dead)
	testing.expect(test, !hale.on_map)
	testing.expect(test, grid_block_at(&grid, 3, 1).occupant == nil)
}

@(test)
test_movement_bfs_plains :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	grid_block_at(&grid, 0, 1).terrain = .Plains
	grid_block_at(&grid, 0, 2).terrain = .Plains
	testing.expect(test, grid_place_unit(&grid, hale, 4, 4))
	hale.movement = 6
	grid_calculate_unit_movement_range(&grid, hale)
	testing.expect(test, grid_in_range(&grid, 4, 4))
	testing.expect(test, grid_in_range(&grid, 10, 4))
	testing.expect(test, !grid_in_range(&grid, 10, 5))
}

@(test)
test_forest_cost_two :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 0, 0))
	hale.movement_origin = {
		grid_x = 0,
		grid_y = 0,
	}
	hale.movement = 1
	grid_calculate_unit_movement_range(&grid, hale)
	testing.expect(test, !grid_in_range(&grid, 0, 1))
	hale.movement = 2
	grid_calculate_unit_movement_range(&grid, hale)
	testing.expect(test, grid_in_range(&grid, 0, 1))
}

@(test)
test_enemy_blocks_tile :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer units.destroy(hale)
	defer units.destroy(judy)

	judy.friendly = false
	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	testing.expect(test, grid_place_unit(&grid, judy, 3, 2))
	grid_calculate_unit_movement_range(&grid, hale)
	testing.expect(test, !grid_in_range(&grid, 3, 2))
}

@(test)
test_origin_rooted_full_budget :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	grid_block_at(&grid, 0, 1).terrain = .Plains
	grid_block_at(&grid, 0, 2).terrain = .Plains
	hale.movement = 6
	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	hale.movement_origin = {
		grid_x = 3,
		grid_y = 1,
	}
	testing.expect(test, grid_place_unit(&grid, hale, 4, 1))
	grid_calculate_unit_movement_range(&grid, hale)
	testing.expect(test, grid_in_range(&grid, 3, 1))
	testing.expect(test, grid_in_range(&grid, 3, 7))
	testing.expect(test, !grid_in_range(&grid, 4, 7))
}

@(test)
test_give_range :: proc(test: ^testing.T) {
	data.init()
	catalog.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	grid_calculate_give_range(&grid, hale)
	testing.expect(test, !grid_in_range(&grid, 3, 1))
	testing.expect(test, grid_in_range(&grid, 4, 1))
	testing.expect(test, !grid_in_range(&grid, 5, 1))
}

@(test)
test_weapon_unarmed_range :: proc(test: ^testing.T) {
	data.init()
	catalog.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	grid_calculate_weapon_attack_range(&grid, hale)
	testing.expect(test, !grid_in_range(&grid, 3, 1))
	testing.expect(test, grid_in_range(&grid, 4, 1))
	testing.expect(test, !grid_in_range(&grid, 5, 1))
}

@(test)
test_manhattan_fill_includes_origin :: proc(test: ^testing.T) {
	data.init()
	catalog.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	grid_fill_effect_distance_range(&grid, hale, {min = 0, max = 1})
	testing.expect(test, grid_in_range(&grid, 3, 1))
	testing.expect(test, grid_in_range(&grid, 4, 1))
}

@(test)
test_move_in_direction :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 3, 1))
	origin_pixel := block_pixel_coords(grid_block_at(&grid, 3, 1))
	grid_range_add(&grid, 4, 1)
	testing.expect(test, grid_move_unit_in_direction(&grid, hale, .Right))
	testing.expect_value(test, hale.facing_direction, defs.Direction.Right)
	testing.expect(test, grid_block_at(&grid, 4, 1).occupant == hale)
	testing.expect(test, hale.is_animating)
	testing.expect_value(test, hale.start_world_position, origin_pixel)
	testing.expect(test, !grid_move_unit_in_direction(&grid, hale, .Up))
}

@(test)
test_move_oob_and_empty_range :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_full()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	testing.expect(test, grid_place_unit(&grid, hale, 0, 0))
	testing.expect(test, !grid_move_unit_in_direction(&grid, hale, .Left))
	testing.expect(test, !grid_move_unit_in_direction(&grid, hale, .Right))
	testing.expect_value(test, hale.grid_x, 0)
	testing.expect_value(test, hale.grid_y, 0)
}

@(test)
test_grid_range_tint_steps :: proc(test: ^testing.T) {
	grid := test_grid_full()
	defer grid_destroy(&grid)

	testing.expect_value(test, timers.oscillator_value(grid.range_tint), defs.range_tint_levels[0])
	for _ in 0 ..< defs.ANIMATIONS.range_tint_frame_delay {
		timers.oscillator_tick(&grid.range_tint)
	}

	testing.expect_value(test, timers.oscillator_value(grid.range_tint), defs.range_tint_levels[1])
}

@(test)
test_first_reach_wins :: proc(test: ^testing.T) {
	data.init()
	grid := test_grid_small()
	defer grid_destroy(&grid)
	hale := data.make_unit(.Hale)
	defer units.destroy(hale)

	grid_block_at(&grid, 1, 0).terrain = .Hill
	testing.expect_value(test, grid_block_at(&grid, 0, 1).terrain, defs.Terrain.Forest)
	testing.expect_value(test, grid_block_at(&grid, 0, 2).terrain, defs.Terrain.Forest)
	testing.expect(test, grid_place_unit(&grid, hale, 0, 0))
	hale.movement = 4
	hale.movement_origin = {
		grid_x = 0,
		grid_y = 0,
	}
	grid_calculate_unit_movement_range(&grid, hale)
	testing.expect(test, grid_in_range(&grid, 1, 1))
	testing.expect(test, !grid_in_range(&grid, 1, 2))
}
