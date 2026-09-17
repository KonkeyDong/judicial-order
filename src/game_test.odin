package game

import "core:log"
import "core:testing"

import "catalog"
import "data"
import "defs"
import unit_pkg "unit"
import rl "vendor:raylib"

GAME_TEST_ROLL_CAP :: 8

@(thread_local)
game_test_roll_buf: [GAME_TEST_ROLL_CAP]int
@(thread_local)
game_test_rolls: []int
@(thread_local)
game_test_roll_i: int

game_combat_random_from_script :: proc(lo, hi: int) -> int {
	if game_test_roll_i >= len(game_test_rolls) {
		log.errorf("game_combat_random_from_script: no scripted roll left (lo=%d hi=%d).", lo, hi)
		return lo
	}

	value := game_test_rolls[game_test_roll_i]
	game_test_roll_i += 1
	return value
}

game_test_install_rolls :: proc(rolls: []int) {
	count := len(rolls)
	if count > GAME_TEST_ROLL_CAP {
		count = GAME_TEST_ROLL_CAP
	}

	for i in 0 ..< count {
		game_test_roll_buf[i] = rolls[i]
	}

	game_test_rolls = game_test_roll_buf[:count]
	game_test_roll_i = 0
	unit_pkg.combat_set_random(game_combat_random_from_script)
}

test_game_full :: proc() -> Game {
	game: Game
	game_init(&game, GAME_STUB_WIDTH, GAME_STUB_HEIGHT)
	return game
}

@(test)
test_game_init_owns_grid :: proc(test: ^testing.T) {
	game := test_game_full()
	defer game_destroy(&game)

	testing.expect_value(test, game.grid.width, 11)
	testing.expect_value(test, game.grid.height, 10)
	testing.expect_value(test, game.renderer.debug_draw, false)
	testing.expect_value(test, grid_block_at(&game.grid, 0, 1).terrain, defs.Terrain.Forest)
	testing.expect_value(test, grid_block_at(&game.grid, 0, 2).terrain, defs.Terrain.Forest)
	testing.expect_value(test, game.flip_flop.frames_per_phase, defs.ANIMATIONS.flip_flop_delay)
	testing.expect_value(test, game.state, defs.State_Kind.CalculateUnitMovementRange)
	testing.expect_value(test, game.battle_screen_mode, defs.Battle_Screen_Mode.Combat)
	testing.expect_value(test, game.give.giver_slot_index, -1)
	testing.expect_value(test, game.prompt.return_state_on_no, defs.State_Kind.BattleActionMenu)
	testing.expect_value(test, game.attack_context.active, false)
	testing.expect_value(test, game.item_context.active, false)
	testing.expect_value(test, game.magic_context.active, false)
	testing.expect_value(test, game.item_context.target_count, 0)
	testing.expect_value(test, game.magic_context.target_count, 0)
	testing.expect_value(test, game.window.scale, f32(defs.WINDOW.scale))
	testing.expect_value(test, game.window.width, i32(768))
	testing.expect_value(test, game.window.height, i32(672))
	testing.expect_value(test, game.grid.block_size, 72)
}

@(test)
test_add_unit_places_and_rosters :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect_value(test, len(game.units), 1)
	testing.expect(test, game_current_unit(&game) == hale)
	testing.expect(test, hale.on_map)
	testing.expect(test, grid_block_at(&game.grid, 3, 1).occupant == hale)
}

@(test)
test_current_and_next_two_units :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 3, 2))
	testing.expect(test, game_current_unit(&game) == hale)
	testing.expect(test, game_next_unit(&game) == judy)
}

@(test)
test_move_first_to_end :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 3, 2))
	game_move_first_unit_to_end(&game)
	testing.expect(test, game_current_unit(&game) == judy)
	testing.expect(test, game_next_unit(&game) == hale)
	testing.expect_value(test, len(game.units), 2)

	hale_a := data.make_unit(.Hale)
	hale_b := data.make_unit(.Hale)
	judy_b := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale_a)
	defer unit_pkg.destroy(hale_b)
	defer unit_pkg.destroy(judy_b)
	game_b: Game
	game_init(&game_b, GAME_STUB_WIDTH, GAME_STUB_HEIGHT)
	defer game_destroy(&game_b)
	testing.expect(test, game_add_unit(&game_b, hale_a, 1, 1))
	testing.expect(test, game_add_unit(&game_b, hale_b, 2, 1))
	testing.expect(test, game_add_unit(&game_b, judy_b, 3, 1))
	game_move_first_unit_to_end(&game_b)
	testing.expect(test, game_current_unit(&game_b) == hale_b)
	testing.expect(test, game_next_unit(&game_b) == judy_b)
}

@(test)
test_add_unit_nil_and_oob :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	old_logger := context.logger
	context.logger = {}
	testing.expect(test, !game_add_unit(&game, nil, 0, 0))
	testing.expect_value(test, len(game.units), 0)
	testing.expect(test, !game_add_unit(&game, hale, -1, 0))
	context.logger = old_logger
	testing.expect(test, !hale.on_map)
	testing.expect_value(test, len(game.units), 0)
}

@(test)
test_add_unit_visitor_slot :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 3, 1))
	testing.expect_value(test, len(game.units), 2)
	block := grid_block_at(&game.grid, 3, 1)
	testing.expect(test, block.occupant == hale)
	testing.expect(test, block.visitor == judy)
	testing.expect(test, block_top(block) == judy)
}

@(test)
test_add_unit_dest_full_does_not_append :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	hale_b := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer unit_pkg.destroy(hale_b)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 3, 1))
	old_logger := context.logger
	context.logger = {}
	ok := game_add_unit(&game, hale_b, 3, 1)
	context.logger = old_logger
	testing.expect(test, !ok)
	testing.expect_value(test, len(game.units), 2)
	testing.expect(test, !hale_b.on_map)
}

@(test)
test_empty_roster_current_is_nil :: proc(test: ^testing.T) {
	game := test_game_full()
	defer game_destroy(&game)

	old_logger := context.logger
	context.logger = {}
	testing.expect(test, game_current_unit(&game) == nil)
	testing.expect(test, game_next_unit(&game) == nil)
	context.logger = old_logger
}

@(test)
test_one_unit_next_and_rotate_noop :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	old_logger := context.logger
	context.logger = {}
	testing.expect(test, game_next_unit(&game) == hale)
	game_move_first_unit_to_end(&game)
	context.logger = old_logger
	testing.expect_value(test, len(game.units), 1)
	testing.expect(test, game_current_unit(&game) == hale)
}

@(test)
test_context_reset :: proc(test: ^testing.T) {
	game := test_game_full()
	defer game_destroy(&game)

	game.prompt.action = .DropItem
	game.prompt.item_slot_index = 2
	game.prompt.return_state_on_no = .EndTurn
	game.give.giver_slot_index = 0
	game.message_notice.message = "x"
	prompt_reset(&game.prompt)
	give_reset(&game.give)
	message_notice_reset(&game.message_notice)
	testing.expect_value(test, game.prompt.action, defs.Prompt_Action.None)
	testing.expect_value(test, game.prompt.item_slot_index, -1)
	testing.expect_value(test, game.prompt.return_state_on_no, defs.State_Kind.BattleActionMenu)
	testing.expect_value(test, game.give.giver_slot_index, -1)
	testing.expect_value(test, game.message_notice.message, "")
	testing.expect_value(test, game.message_notice.return_state, defs.State_Kind.BattleActionMenu)
}

@(test)
test_separate_units_in_range :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	judy.friendly = false
	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 4, 1))
	grid_calculate_give_range(&game.grid, hale)
	found := grid_units_in_range(&game.grid)
	defer delete(found)
	game_separate_units_in_range(&game, hale, found)
	testing.expect_value(test, len(game.unfriendly_units_in_range), 1)
	testing.expect_value(test, len(game.friendly_units_in_range), 0)
	testing.expect(test, game.unfriendly_units_in_range[0] == judy)
}

@(test)
test_separate_friendly :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 4, 1))
	grid_calculate_give_range(&game.grid, hale)
	found := grid_units_in_range(&game.grid)
	defer delete(found)
	game_separate_units_in_range(&game, hale, found)
	testing.expect_value(test, len(game.friendly_units_in_range), 1)
	testing.expect_value(test, len(game.unfriendly_units_in_range), 0)
	testing.expect(test, game.friendly_units_in_range[0] == judy)
}

@(test)
test_remove_dead_units :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	hale.hp.current = 0
	unit_pkg.apply_status(hale, .Poison)
	dead := game_remove_all_dead_units(&game)
	defer delete(dead)
	testing.expect_value(test, len(dead), 1)
	testing.expect(test, dead[0] == hale)
	testing.expect_value(test, len(game.units), 0)
	testing.expect(test, !hale.on_map)
	testing.expect(test, grid_block_at(&game.grid, 3, 1).occupant == nil)
	testing.expect_value(test, hale.status_count, 0)
}

@(test)
test_find_does_not_remove :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	hale.hp.current = 0
	dead := game_find_all_dead_units(&game)
	defer delete(dead)
	testing.expect_value(test, len(dead), 1)
	testing.expect_value(test, len(game.units), 1)
	testing.expect(test, hale.on_map)
}

@(test)
test_remove_dead_preserves_survivor_order :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale_a := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	hale_b := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale_a)
	defer unit_pkg.destroy(judy)
	defer unit_pkg.destroy(hale_b)

	testing.expect(test, game_add_unit(&game, hale_a, 1, 1))
	testing.expect(test, game_add_unit(&game, judy, 2, 1))
	testing.expect(test, game_add_unit(&game, hale_b, 3, 1))
	hale_a.hp.current = 0
	hale_b.hp.current = 0
	dead := game_remove_all_dead_units(&game)
	defer delete(dead)
	testing.expect_value(test, len(game.units), 1)
	testing.expect(test, game.units[0] == judy)
	testing.expect_value(test, len(dead), 2)
	testing.expect(test, dead[0] == hale_a)
	testing.expect(test, dead[1] == hale_b)
}

@(test)
test_poison_flags :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	game_set_first_unit_died_from_poison(&game, hale)
	testing.expect(test, game.first_unit_died_from_poison)
	testing.expect(test, game.unit_that_died_from_poison == hale)
	game_reset_first_unit_died_from_poison(&game)
	testing.expect(test, !game.first_unit_died_from_poison)
	testing.expect(test, game.unit_that_died_from_poison == nil)
}

@(test)
test_highlight_init_and_settle :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 4, 1))
	game_initialize_highlight(&game)
	testing.expect_value(test, game.highlight_current_position, rl.Vector2{72, 24})
	game_set_highlight_target(&game, judy)
	testing.expect_value(test, game.highlight_target_position, rl.Vector2{96, 24})
	testing.expect(test, !game.highlight_animation_complete)
	game_update_highlight(&game, 10)
	testing.expect_value(test, game.highlight_current_position, rl.Vector2{96, 24})
	testing.expect(test, !game.highlight_animation_complete)
	game_update_highlight(&game, 1.0 / 60)
	testing.expect_value(test, game.highlight_current_position, rl.Vector2{96, 24})
	testing.expect(test, game.highlight_animation_complete)
}

@(test)
test_highlight_steps :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	testing.expect(test, game_add_unit(&game, hale, 3, 1))
	testing.expect(test, game_add_unit(&game, judy, 4, 1))
	game_initialize_highlight(&game)
	game_set_highlight_target(&game, judy)
	game_update_highlight(&game, 1.0 / 60)
	testing.expect(test, game.highlight_current_position.x > 72)
	testing.expect(test, game.highlight_current_position.x < 96)
	testing.expect(test, !game.highlight_animation_complete)
}

@(test)
test_highlight_off_map :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	old_logger := context.logger
	context.logger = {}
	game_initialize_highlight(&game)
	before := game.highlight_current_position
	game_set_highlight_target(&game, hale)
	context.logger = old_logger
	testing.expect_value(test, game.highlight_current_position, before)
	testing.expect(test, !hale.on_map)
}

@(test)
test_attack_context_hale_normal_effect :: proc(test: ^testing.T) {
	data.init()
	catalog.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer unit_pkg.combat_set_random(nil)

	judy.friendly = false
	game_test_install_rolls({1, 100})
	attack_context_init(&game.attack_context, hale, judy)
	testing.expect(test, game.attack_context.active)
	testing.expect_value(test, game.attack_context.effect, defs.Attack_Effect.NormalAttack)
	testing.expect_value(test, game.attack_context.damage_apply_frame, 0)
	testing.expect(test, game.attack_context.hit)
	testing.expect_value(test, attack_context_monster(&game.attack_context), judy)
	testing.expect_value(test, attack_context_force_member(&game.attack_context), hale)
}

@(test)
test_item_context_self_and_party :: proc(test: ^testing.T) {
	data.init()
	catalog.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	judy := data.make_unit(.Judy)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	item_context_init(&game.item_context, hale, {hale}, &game.grid, 0)
	testing.expect(test, item_context_is_self_target(&game.item_context))
	testing.expect(test, !item_context_is_party_wide(&game.item_context))
	testing.expect_value(test, item_context_target(&game.item_context), hale)
	testing.expect(test, game.item_context.grid == &game.grid)

	item_context_init(&game.item_context, hale, {hale, judy}, &game.grid, 0)
	testing.expect(test, item_context_is_party_wide(&game.item_context))
	testing.expect(test, !item_context_is_self_target(&game.item_context))
	testing.expect_value(test, item_context_target(&game.item_context), hale)
	testing.expect_value(test, game.item_context.target_count, 2)
}

@(test)
test_item_context_use_item_empty_slot :: proc(test: ^testing.T) {
	data.init()
	catalog.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale := data.make_unit(.Hale)
	defer unit_pkg.destroy(hale)

	item_context_init(&game.item_context, hale, {hale}, &game.grid, 0)
	old_logger := context.logger
	context.logger = {}
	item_context_use_item(&game.item_context)
	context.logger = old_logger
	testing.expect(test, game.item_context.active)
	testing.expect(test, unit_pkg.item_slot_is_empty(unit_pkg.item_at(hale, 0)))
}

@(test)
test_game_contexts_reset_on_init :: proc(test: ^testing.T) {
	game := test_game_full()
	defer game_destroy(&game)

	testing.expect_value(test, game.attack_context.active, false)
	testing.expect_value(test, game.item_context.active, false)
	testing.expect_value(test, game.magic_context.active, false)
	testing.expect_value(test, game.item_context.target_count, 0)
	testing.expect_value(test, game.magic_context.target_count, 0)
	testing.expect_value(test, game.item_context.targets[0], nil)
	testing.expect_value(test, game.magic_context.targets[0], nil)
}
