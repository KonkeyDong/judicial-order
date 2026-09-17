package game

import "core:log"

import "defs"
import "timers"

message_notice_enter :: proc(game: ^Game) {
	timers.countdown_timer_reset(&game.state_scratch.countdown)

	if len(game.message_notice.message) == 0 {
		log.warn("MessageNotice: Message was empty. Returning immediately.")
		return_state := game.message_notice.return_state
		state_change(game, return_state)
		return
	}

	timers.oscillator_reset(&game.grid.range_tint)
	log.infof(
		"MessageNotice: \"%s\" → return to [%v].",
		game.message_notice.message,
		game.message_notice.return_state,
	)
}

message_notice_exit :: proc(game: ^Game) {
	message_notice_reset(&game.message_notice)
}

message_notice_handle_input :: proc(game: ^Game) {
	if input_dismiss_press() {
		message_notice_dismiss(game)
	}
}

message_notice_dismiss :: proc(game: ^Game) {
	return_state := game.message_notice.return_state
	state_change(game, return_state)
}

message_notice_update :: proc(game: ^Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)
	timers.countdown_timer_tick(&game.state_scratch.countdown)

	if !game.state_scratch.countdown.is_active {
		log.info("MessageNotice: countdown exhausted.")
		message_notice_dismiss(game)
	}
}

message_notice_draw :: proc(game: ^Game, scale: f32) {
	debug_draw := game.renderer.debug_draw
	renderer_draw_background(scale, &game.grid, 255, debug_draw)
	renderer_draw_range(scale, &game.grid, debug_draw)
	renderer_draw_units(scale, game.units[:], game.flip_flop.is_on, 255, debug_draw)
	renderer_draw_battle_menu_message(
		scale,
		game.message_notice.message,
		defs.WORLD_MAP.positions.no_target_message_box,
	)
}
