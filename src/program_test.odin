package game

import "core:log"
import "core:testing"

import "catalog"
import "data"
import "defs"
import unit_pkg "unit"

@(test)
test_parse_args_default_info :: proc(test: ^testing.T) {
	options, ok := program_parse_args({"judicial-order"})
	testing.expect(test, ok)
	testing.expect_value(test, options.log_level, log.Level.Info)
}

@(test)
test_parse_args_logger_flag :: proc(test: ^testing.T) {
	options, ok := program_parse_args({"judicial-order", "--logger", "debug"})
	testing.expect(test, ok)
	testing.expect_value(test, options.log_level, log.Level.Debug)

	options, ok = program_parse_args({"judicial-order", "-l", "warning"})
	testing.expect(test, ok)
	testing.expect_value(test, options.log_level, log.Level.Warning)

	options, ok = program_parse_args({"judicial-order", "-d", "error"})
	testing.expect(test, ok)
	testing.expect_value(test, options.log_level, log.Level.Error)

	options, ok = program_parse_args({"judicial-order", "--logger=fatal"})
	testing.expect(test, ok)
	testing.expect_value(test, options.log_level, log.Level.Fatal)
}

@(test)
test_parse_args_unknown_level :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	_, ok := program_parse_args({"judicial-order", "--logger", "noisy"})
	testing.expect(test, !ok)
}

@(test)
test_parse_args_missing_value :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	_, ok := program_parse_args({"judicial-order", "-l"})
	testing.expect(test, !ok)
}

@(test)
test_parse_args_unknown_flag :: proc(test: ^testing.T) {
	old_logger := context.logger
	context.logger = {}
	defer {context.logger = old_logger}

	_, ok := program_parse_args({"judicial-order", "--help"})
	testing.expect(test, !ok)
}

@(test)
test_f1_toggles_debug_and_info :: proc(test: ^testing.T) {
	game := test_game_full()
	defer game_destroy(&game)
	defer input_set_pressed(nil)
	defer program_set_log_level(.Info)

	program_set_log_level(.Info)
	program_apply_debug_draw(&game)
	testing.expect(test, !program_log_in_debug_mode())
	testing.expect_value(test, game.renderer.debug_draw, false)

	input_test_install_pressed({.F1})
	program_handle_logging_toggle(&game)
	testing.expect(test, program_log_in_debug_mode())
	testing.expect(test, game.renderer.debug_draw)

	program_handle_logging_toggle(&game)
	testing.expect(test, !program_log_in_debug_mode())
	testing.expect_value(test, game.renderer.debug_draw, false)
}

@(test)
test_program_add_test_units_hale_judy :: proc(test: ^testing.T) {
	data.init()
	game := test_game_full()
	defer game_destroy(&game)
	hale, judy, bellweather := program_add_test_units(&game)
	defer unit_pkg.destroy(hale)
	defer unit_pkg.destroy(judy)
	defer unit_pkg.destroy(bellweather)

	testing.expect_value(test, len(game.units), 3)
	testing.expect(test, game_current_unit(&game) == hale)
	testing.expect_value(test, hale.grid_x, 3)
	testing.expect_value(test, hale.grid_y, 1)
	testing.expect_value(test, judy.grid_x, 2)
	testing.expect_value(test, judy.grid_y, 1)
	testing.expect_value(test, bellweather.grid_x, 3)
	testing.expect_value(test, bellweather.grid_y, 2)
	testing.expect(test, !bellweather.friendly)
	testing.expect(test, unit_pkg.has_spells(judy))
}

@(test)
test_item_get_register_stats :: proc(test: ^testing.T) {
	herb := catalog.item_get(.HealingSeed)
	testing.expect_value(test, herb.effect_value, 20)
	testing.expect_value(test, herb.effect_type, defs.Item_Effect.Heal)
	staff := catalog.item_get(.WoodenStaff)
	testing.expect_value(test, staff.attack, 5)
	testing.expect_value(test, staff.type, defs.Item_Type.Staff)
	light := catalog.item_get(.SwordOfLight)
	testing.expect_value(test, light.attack, 36)
	testing.expect_value(test, light.spell_name, defs.Magic_Name.Bolt2)
	testing.expect_value(test, defs.item_name_display(.ShortSword), "Short Sword")
	testing.expect_value(test, defs.item_name_display(.SwordOfLight), "Sword Of Light")
}

@(test)
test_unit_get_force_and_enemy :: proc(test: ^testing.T) {
	trudy := data.unit_get(.Trudy)
	testing.expect(test, trudy.friendly)
	testing.expect_value(test, trudy.default_job, defs.Job{.Mage})
	foe := data.unit_get(.Bellweather)
	testing.expect(test, !foe.friendly)
	testing.expect_value(test, foe.base_hp, 12)
	testing.expect_value(test, foe.base_attack, 6)
}

@(test)
test_battle_slide_amount_bounds :: proc(test: ^testing.T) {
	testing.expect_value(test, battle_slide_amount(0), f32(0))
	testing.expect_value(test, battle_slide_amount(0.5), f32(0))
	testing.expect_value(test, battle_slide_amount(1), f32(1))
}

@(test)
test_window_scale_clamp :: proc(test: ^testing.T) {
	testing.expect_value(test, window_scale_clamp(0.5), f32(1.0))
	testing.expect_value(test, window_scale_clamp(6.0), f32(5.0))
	testing.expect_value(test, window_scale_clamp(3.0), f32(3.0))
}

@(test)
test_window_apply_scale_updates_block_size :: proc(test: ^testing.T) {
	game := test_game_full()
	defer game_destroy(&game)

	testing.expect_value(test, game.window.scale, f32(defs.WINDOW.scale))
	testing.expect_value(test, game.window.width, i32(768))
	testing.expect_value(test, game.window.height, i32(672))
	testing.expect_value(test, game.grid.block_size, 72)

	window_apply_scale(&game, 4.0, apply_os_window = false)
	testing.expect_value(test, game.window.scale, f32(4.0))
	testing.expect_value(test, game.window.width, i32(1024))
	testing.expect_value(test, game.window.height, i32(896))
	testing.expect_value(test, game.grid.block_size, 96)

	window_apply_scale(&game, 0.5, apply_os_window = false)
	testing.expect_value(test, game.window.scale, f32(1.0))
	testing.expect_value(test, game.window.width, i32(256))
	testing.expect_value(test, game.window.height, i32(224))
	testing.expect_value(test, game.grid.block_size, 24)
}

@(test)
test_window_ctrl_plus_minus :: proc(test: ^testing.T) {
	game := test_game_full()
	defer game_destroy(&game)
	defer input_set_pressed(nil)
	defer input_set_down(nil)

	input_test_install_down({.LEFT_CONTROL})
	input_test_install_pressed({.EQUAL})
	window_handle_resize_input(&game, apply_os_window = false)
	testing.expect_value(test, game.window.scale, f32(4.0))

	input_test_install_pressed({.MINUS})
	window_handle_resize_input(&game, apply_os_window = false)
	testing.expect_value(test, game.window.scale, f32(3.0))

	window_apply_scale(&game, 1.0, apply_os_window = false)
	input_test_install_pressed({.MINUS})
	window_handle_resize_input(&game, apply_os_window = false)
	testing.expect_value(test, game.window.scale, f32(1.0))
}
