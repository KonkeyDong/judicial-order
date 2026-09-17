package game

import "core:log"
import "core:strings"

import "catalog"
import "data"
import "sprites"
import unit_pkg "unit"
import rl "vendor:raylib"

Program_Options :: struct {
	log_level: log.Level,
}

@(thread_local)
program_log_level: log.Level

@(thread_local)
program_log_ready: bool

program_log_level_get :: proc() -> log.Level {
	if program_log_ready {
		return program_log_level
	}

	return .Info
}

program_log_in_debug_mode :: proc() -> bool {
	return program_log_level_get() == .Debug
}

program_set_log_level :: proc(level: log.Level) {
	program_log_level = level
	program_log_ready = true
	context.logger.lowest_level = level
}

program_apply_debug_draw :: proc(game: ^Game) {
	if game == nil {
		return
	}

	game.renderer.debug_draw = program_log_in_debug_mode()
}

program_parse_log_level :: proc(text: string) -> (level: log.Level, ok: bool) {
	if strings.equal_fold(text, "debug") {
		return .Debug, true
	}

	if strings.equal_fold(text, "info") {
		return .Info, true
	}

	if strings.equal_fold(text, "warning") {
		return .Warning, true
	}

	if strings.equal_fold(text, "error") {
		return .Error, true
	}

	if strings.equal_fold(text, "fatal") {
		return .Fatal, true
	}

	return .Info, false
}

program_parse_args :: proc(args: []string) -> (options: Program_Options, ok: bool) {
	options.log_level = .Info
	ok = true

	i := 1
	for i < len(args) {
		arg := args[i]
		if arg == "--logger" || arg == "-l" || arg == "-d" {
			if i + 1 >= len(args) {
				log.errorf("program_parse_args: %s requires a log level.", arg)
				return options, false
			}

			i += 1
			level, parsed := program_parse_log_level(args[i])
			if !parsed {
				log.errorf("program_parse_args: unknown log level [%s].", args[i])
				return options, false
			}

			options.log_level = level
		} else if strings.has_prefix(arg, "--logger=") {
			value := arg[len("--logger="):]
			level, parsed := program_parse_log_level(value)
			if !parsed {
				log.errorf("program_parse_args: unknown log level [%s].", value)
				return options, false
			}

			options.log_level = level
		} else {
			log.errorf("program_parse_args: unknown argument [%s].", arg)
			return options, false
		}

		i += 1
	}

	return options, true
}

program_handle_logging_toggle :: proc(game: ^Game) {
	if !input_key_pressed(.F1) {
		return
	}

	if program_log_level_get() == .Debug {
		program_set_log_level(.Info)
	} else {
		program_set_log_level(.Debug)
	}

	program_apply_debug_draw(game)
	log.infof("Logging level changed to: %v", program_log_level_get())
}

program_handle_global_input :: proc(game: ^Game, apply_os_window := true) {
	window_handle_resize_input(game, apply_os_window)
	program_handle_logging_toggle(game)
	state_handle_input(game)
}

program_init_databases :: proc() {
	catalog.init()
	data.init()
}

program_load_graphics :: proc() {
	sprites.init()
	sprites.item_icons_load()
	sprites.magic_icons_load()
}

program_add_test_units :: proc(game: ^Game) -> (hale, judy, bellweather: ^unit_pkg.Unit) {
	catalog.init()
	data.init()
	hale = data.make_unit(.Hale)
	judy = data.make_unit(.Judy)
	bellweather = data.make_unit(.Bellweather)
	unit_pkg.add_item(hale, .ShortSword, auto_equip_weapon = true)
	unit_pkg.add_item(hale, .MedicalHerb)
	unit_pkg.learn_spell(judy, .Heal1)
	unit_pkg.learn_spell(judy, .Blaze1)
	game_add_unit(game, hale, 3, 1)
	game_add_unit(game, judy, 2, 1)
	game_add_unit(game, bellweather, 3, 2)
	return hale, judy, bellweather
}

program_update :: proc(game: ^Game) {
	state_update(game)
}

program_draw :: proc(game: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)
	state_draw(game)
	rl.EndDrawing()
}
