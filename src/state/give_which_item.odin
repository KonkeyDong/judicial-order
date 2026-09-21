package state

import game_pkg "../game"

import "../defs"
import "../sprites"
import "../timers"

give_which_item_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current != nil {
		game_pkg.grid_calculate_give_range(&game.grid, current)
		units := game_pkg.grid_units_in_range(&game.grid)
		defer delete(units)
		game_pkg.game_separate_units_in_range(game, current, units)
	}

	if len(game.friendly_units_in_range) == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .BattleItemMenu)
		return
	}

	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
	sprites.item_ui_select_first(&game.item_ui, current, sprites.item_ui_giveable_filter)
}

give_which_item_exit :: proc(_: ^game_pkg.Game) {}

give_which_item_handle_input :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	state_item_handle_slot_keys(game, current, sprites.item_ui_giveable_filter)
	if game_pkg.input_confirm_press() {
		if !sprites.item_ui_has_valid_selection(
			&game.item_ui,
			current,
			sprites.item_ui_giveable_filter,
		) {
			return
		}

		game.contexts.give.giver_slot_index = game.item_ui.selected_index
		game.contexts.give.recipient = nil
		game.contexts.give.recipient_slot_index = -1
		state_change(game, .GiveItemToWhom)
	}

	if game_pkg.input_cancel_press() {
		sprites.item_ui_reset(&game.item_ui)
		sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
		state_change(game, .BattleItemMenu)
	}
}

give_which_item_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.item_icons_tick()
}

give_which_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	state_draw_item_radial(game, scale, game_pkg.game_current_unit(game))
}
