package state

import game_pkg "../game"

import "core:log"

import "../defs"
import "../sprites"
import "../timers"
import rl "vendor:raylib"

trade_which_item_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	recipient := game.contexts.give.recipient
	if recipient == nil {
		log.errorf("TradeWhichItemFromAdjacentNeighbor: Give.Recipient is nil.")
		state_change(game, .GiveItemToWhom)
		return
	}

	if current != nil {
		game_pkg.grid_calculate_give_range(&game.grid, current)
	}

	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_set_layout_center(&game.item_ui, defs.GIVE.positions.trade_inventory_center)
	sprites.item_ui_select_first(&game.item_ui, recipient, sprites.item_ui_giveable_filter)
	if recipient.on_map {
		game_pkg.game_initialize_highlight(game)
		game_pkg.game_set_highlight_target(game, recipient)
	}
}

trade_which_item_exit :: proc(_: ^game_pkg.Game) {}

trade_which_item_handle_input :: proc(game: ^game_pkg.Game) {
	recipient := game.contexts.give.recipient
	state_item_handle_slot_keys(game, recipient, sprites.item_ui_giveable_filter)
	if game_pkg.input_confirm_press() {
		if !sprites.item_ui_has_valid_selection(
			&game.item_ui,
			recipient,
			sprites.item_ui_giveable_filter,
		) {
			return
		}

		game.contexts.give.recipient_slot_index = game.item_ui.selected_index
		game.contexts.prompt.action = .TradeItem
		game.contexts.prompt.return_state_on_yes = .EndTurn
		game.contexts.prompt.return_state_on_no = .TradeWhichItemFromAdjacentNeighbor
		state_change(game, .PromptYesNo)
	}

	if game_pkg.input_cancel_press() {
		sprites.item_ui_reset(&game.item_ui)
		sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
		state_change(game, .GiveItemToWhom)
	}
}

trade_which_item_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.item_icons_tick()
	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

trade_which_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, true)
	state_draw_item_radial(game, scale, game.contexts.give.recipient)
}
