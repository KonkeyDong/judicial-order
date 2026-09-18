package state

import game_pkg "../game"

import "core:testing"

import "../catalog"
import "../data"
import "../defs"
import unit_pkg "../unit"

test_place_hale_judy :: proc(game: ^game_pkg.Game) -> (hale, judy: ^unit_pkg.Unit) {
	data.init()
	hale = data.make_unit(.Hale)
	judy = data.make_unit(.Judy)
	game_pkg.game_add_unit(game, hale, 3, 1)
	game_pkg.game_add_unit(game, judy, 4, 1)
	return hale, judy
}

@(test)
test_message_notice_dismiss_returns :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer game_pkg.input_set_pressed(nil)

	state_show_message_notice(&game, "No target", .BattleActionMenu)
	testing.expect_value(test, game.state, defs.State_Kind.MessageNotice)
	testing.expect_value(test, game.message_notice.message, "No target")
	testing.expect(test, game.state_scratch.countdown.is_active)

	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.BattleActionMenu)
	testing.expect_value(test, game.message_notice.message, "")
}

@(test)
test_message_notice_empty_returns_immediately :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	old_logger := context.logger
	context.logger = {}
	state_show_message_notice(&game, "", .UnitMoving)
	context.logger = old_logger
	testing.expect_value(test, game.state, defs.State_Kind.UnitMoving)
	testing.expect_value(test, game.message_notice.message, "")
}

@(test)
test_message_notice_countdown_returns :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	state_show_message_notice(&game, "No magic", .BattleActionMenu)
	for _ in 0 ..< defs.ANIMATIONS.switch_state_countdown {
		if game.state != .MessageNotice {
			break
		}

		state_update(&game)
	}

	testing.expect_value(test, game.state, defs.State_Kind.BattleActionMenu)
	testing.expect_value(test, game.message_notice.message, "")
}

@(test)
test_transition_selector_settles_then_next_turn :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	state_change(&game, .TransitionSelectorToNextUnit)
	testing.expect_value(test, game.state, defs.State_Kind.TransitionSelectorToNextUnit)
	testing.expect_value(test, game.highlight_target_position, unit_pkg.tile_pixel(judy))
	testing.expect(test, !game.highlight_animation_complete)

	game.highlight_animation_complete = true
	state_update(&game)
	testing.expect_value(test, game.state, defs.State_Kind.UnitMoving)
	testing.expect(test, game_pkg.game_current_unit(&game) == judy)
}

@(test)
test_healthy_start_enters_unit_moving :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	state_enter(&game)
	testing.expect_value(test, game.state, defs.State_Kind.UnitMoving)
}

@(test)
test_unit_moving_confirm_opens_action_menu :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer game_pkg.input_set_pressed(nil)

	state_enter(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.BattleActionMenu)
}

@(test)
test_action_menu_stay_rotates_to_judy :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer game_pkg.input_set_pressed(nil)

	state_enter(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.DOWN})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.TransitionSelectorToNextUnit)
	game.highlight_animation_complete = true
	state_update(&game)
	testing.expect(test, game_pkg.game_current_unit(&game) == judy)
	testing.expect_value(test, game.state, defs.State_Kind.UnitMoving)
}

@(test)
test_action_menu_magic_without_spells_notices :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer game_pkg.input_set_pressed(nil)

	state_enter(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.LEFT})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.MessageNotice)
}

@(test)
test_weapon_range_no_enemy_notices :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer game_pkg.input_set_pressed(nil)

	state_enter(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.MessageNotice)
}

@(test)
test_select_enemy_inits_attack_and_does_not_double_damage :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer game_pkg.input_set_pressed(nil)
	defer unit_pkg.combat_set_random(nil)

	judy.friendly = false
	state_enter(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.SelectEnemyForPhysicalAttack)
	game_pkg.game_test_install_rolls({1, 100})
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.EnterBattleScreen)
	testing.expect(test, game.attack_context.active)
	testing.expect(test, game.attack_context.hit)
	hp_after_hit := judy.hp.current
	testing.expect(test, hp_after_hit < 10)
	for _ in 0 ..< defs.BATTLE.transition_frames + 2 {
		if game.state == .BattleResolution || game.state == .EnterBattleScreen {
			state_update(&game)
		} else {
			break
		}
	}

	testing.expect_value(test, judy.hp.current, hp_after_hit)
}

@(test)
test_end_turn_resets_contexts :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	game.attack_context.active = true
	game.item_context.active = true
	game.magic_context.active = true
	state_change(&game, .EndTurn)
	testing.expect_value(test, game.attack_context.active, false)
	testing.expect_value(test, game.item_context.active, false)
	testing.expect_value(test, game.magic_context.active, false)
}

@(test)
test_animate_deaths_with_dead_hale_reaches_judy_turn :: proc(test: ^testing.T) {
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)

	hale.hp.current = 0
	state_change(&game, .AnimateUnitDeaths)
	for _ in 0 ..< 40 {
		if game.state == .AnimateUnitDeaths {
			state_update(&game)
		} else {
			break
		}
	}

	testing.expect(test, game_pkg.game_current_unit(&game) == judy)
	testing.expect_value(test, len(game.units), 1)
}

@(test)
test_herb_use_consumes_slot :: proc(test: ^testing.T) {
	catalog.init()
	game := game_pkg.test_game_full()
	defer game_pkg.game_destroy(&game)
	hale, judy := test_place_hale_judy(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer game_pkg.input_set_pressed(nil)
	defer unit_pkg.combat_set_random(nil)

	testing.expect(test, unit_pkg.add_item(hale, .MedicalHerb))
	hale.hp.current = 5
	state_enter(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.RIGHT})
	state_handle_input(&game)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.BattleItemMenu)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.UseWhichItem)
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.UseItemOnWhom)
	game_pkg.game_test_install_rolls({100})
	game_pkg.input_test_install_pressed({.Z})
	state_handle_input(&game)
	testing.expect_value(test, game.state, defs.State_Kind.EnterBattleScreen)
	testing.expect(test, game.item_context.active)
}
