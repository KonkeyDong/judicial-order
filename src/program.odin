package main

import "core:fmt"
import "core:log"
import "core:path/filepath"
import "core:strings"

import "catalog"
import "data"
import "game"
import "sprites"
import "state"
import unit_pkg "unit"
import rl "vendor:raylib"

Program_Options :: struct {
	log_level:   log.Level,
	sprite_demo: bool,
	help:        bool,
}

@(thread_local)
program_log_level: log.Level

@(thread_local)
program_log_ready: bool

@(private)
program_log_level_get :: proc() -> log.Level {
	if program_log_ready {
		return program_log_level
	}

	return .Info
}

@(private)
program_log_in_debug_mode :: proc() -> bool {
	return program_log_level_get() == .Debug
}

@(private)
program_set_log_level :: proc(level: log.Level) {
	program_log_level = level
	program_log_ready = true
	context.logger.lowest_level = level
}

@(private)
program_apply_debug_draw :: proc(session: ^game.Game) {
	if session == nil {
		log.panic("session is nil.")
	}


	session.renderer.debug_draw = program_log_in_debug_mode()
}

@(private = "file")
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

@(private)
program_help_text :: proc(program_name: string) -> string {
	name := filepath.base(program_name)
	if name == "" || name == "." || name == "/" {
		name = "judicial-order"
	}

	return fmt.aprintf(`Usage:
  %s [options]

Start Judicial Order. With no options, the log level is info and the game opens on the map.

Options:
  -h, --help
        Show this help and exit.

  -l, --logger LEVEL
  -d LEVEL
  --logger=LEVEL
        Set the log level. LEVEL is one of: debug, info, warning, error, fatal.
        The default is info. -l, -d, and --logger are the same option.

  --sprite-demo
        Start in the sprite viewer instead of the map.
        Characters lists each battle sprite, with H for a hero and M for a monster.
        Animation chooses Attack or Idle. The sheet loops in the center of the screen.
        A gray checker fills the background so transparent pixels stay visible.
        The default character is Sara in her Idle animation.

Examples:
  %s
  %s --logger debug
  %s --sprite-demo
  %s --logger debug --sprite-demo
  %s --help
`, name, name, name, name, name, name)
}

@(private)
program_print_help :: proc(args: []string) {
	name := "judicial-order"
	if len(args) > 0 {
		name = args[0]
	}

	text := program_help_text(name)
	defer delete(text)
	fmt.println(text)
}

@(private)
program_args_request_help :: proc(args: []string) -> bool {
	for arg in args[1:] {
		if arg == "--help" || arg == "-h" {
			return true
		}
	}

	return false
}

@(private)
program_parse_args :: proc(args: []string) -> (options: Program_Options, ok: bool) {
	options.log_level = .Info
	options.sprite_demo = false
	options.help = false
	ok = true

	if program_args_request_help(args) {
		options.help = true
		return options, true
	}

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
		} else if arg == "--sprite-demo" {
			options.sprite_demo = true
		} else {
			log.errorf("program_parse_args: unknown argument [%s]. Use --help to list options.", arg)
			return options, false
		}

		i += 1
	}

	return options, true
}

@(private)
program_handle_logging_toggle :: proc(session: ^game.Game) {
	if session == nil {
		log.panic("session is nil.")
	}

	if !game.input_key_pressed(.F1) {
		return
	}

	if program_log_level_get() == .Debug {
		program_set_log_level(.Info)
	} else {
		program_set_log_level(.Debug)
	}

	program_apply_debug_draw(session)
	log.infof("Logging level changed to: %v", program_log_level_get())
}

@(private)
program_handle_global_input :: proc(session: ^game.Game, apply_os_window := true) {
	if session == nil {
		log.panic("session is nil.")
	}

	game.window_handle_resize_input(session, apply_os_window)
	program_handle_logging_toggle(session)
	state.state_handle_input(session)
}

program_init_databases :: proc() {
	catalog.init()
	data.init()
}

@(private)
program_load_graphics :: proc() {
	sprites.init()
	sprites.item_icons_load()
	sprites.magic_icons_load()
	sprites.command_icons_load()
	sprites.battle_planes_load()
	sprites.death_sprites_load()
}

@(private)
program_update :: proc(session: ^game.Game) {
	if session == nil {
		log.panic("session is nil.")
	}

	state.state_update(session)
}

@(private)
program_draw :: proc(session: ^game.Game) {
	if session == nil {
		log.panic("session is nil.")
	}

	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)
	state.state_draw(session)
	rl.EndDrawing()
}
