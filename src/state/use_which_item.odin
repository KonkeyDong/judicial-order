package state

import game_pkg "../game"

import "../defs"
import "../sprites"
import "../timers"

use_which_item_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
	sprites.item_ui_select_first(&game.item_ui, current, sprites.item_ui_usable_filter)

	if !sprites.item_ui_has_valid_selection(
		&game.item_ui,
		current,
		sprites.item_ui_usable_filter,
	) {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_item, .BattleItemMenu)
		return
	}

	if current != nil {
		game_pkg.grid_calculate_item_use_range(
			&game.grid,
			current,
			sprites.item_ui_selected_data(&game.item_ui),
		)
	}
}

use_which_item_exit :: proc(_: ^game_pkg.Game) {}

use_which_item_handle_input :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	state_item_handle_slot_keys(game, current, sprites.item_ui_usable_filter)
	if sprites.item_ui_has_valid_selection(
		   &game.item_ui,
		   current,
		   sprites.item_ui_usable_filter,
	   ) &&
	   current != nil {
		game_pkg.grid_calculate_item_use_range(
			&game.grid,
			current,
			sprites.item_ui_selected_data(&game.item_ui),
		)
	}

	if game_pkg.input_confirm_press() {
		if !sprites.item_ui_has_valid_selection(
			&game.item_ui,
			current,
			sprites.item_ui_usable_filter,
		) {
			return
		}

		game.contexts.prompt.item_slot_index = game.item_ui.selected_index

		state_change(game, .UseItemOnWhom)
	}

	if game_pkg.input_cancel_press() {
		sprites.item_ui_reset(&game.item_ui)
		sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
		game_pkg.grid_clear_range_set(&game.grid)

		state_change(game, .BattleItemMenu)
	}
}

use_which_item_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.item_icons_tick()
}

use_which_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	state_draw_item_icons(
		scale,
		game.item_ui.center,
		game_pkg.game_current_unit(game),
		game.item_ui.selected_index,
		sprites.item_ui_usable_filter,
		true,
	)
	sprites.renderer_draw_item_info_box(
		scale,
		sprites.item_ui_selected_data(&game.item_ui),
		false,
		game.item_ui.info_box,
	)
}
