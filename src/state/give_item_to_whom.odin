package state

import game_pkg "../game"

import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"
import rl "vendor:raylib"


give_item_to_whom_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current != nil {
		game_pkg.grid_calculate_give_range(&game.grid, current)
		units := game_pkg.grid_units_in_range(&game.grid)
		defer delete(units)
		game_pkg.game_separate_units_in_range(game, current, units)
	}

	if len(game.friendly_units_in_range) == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .GiveWhichItem)
		return
	}

	game.state_scratch.list_index = 0
	game_pkg.game_initialize_highlight(game)
	game_pkg.game_set_highlight_target(game, game.friendly_units_in_range[0])
}

give_item_to_whom_exit :: proc(_: ^game_pkg.Game) {}

give_item_to_whom_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_try_cycle_index(
		&game.state_scratch.list_index,
		len(game.friendly_units_in_range),
	) {
		target := game.friendly_units_in_range[game.state_scratch.list_index]
		if target != nil && target.on_map {
			game_pkg.game_set_highlight_target(game, target)
		}
	}

	if game_pkg.input_confirm_press() {
		if len(game.friendly_units_in_range) == 0 {
			return
		}

		recipient := game.friendly_units_in_range[game.state_scratch.list_index]
		game.contexts.give.recipient = recipient
		game.contexts.give.recipient_slot_index = -1
		if unit_pkg.has_empty_item_slot(recipient) {
			game.contexts.prompt.action = .GiveItem
			game.contexts.prompt.return_state_on_yes = .EndTurn
			game.contexts.prompt.return_state_on_no = .GiveItemToWhom
			state_change(game, .PromptYesNo)
		} else if unit_pkg.has_giveable_item(recipient) {
			state_change(game, .TradeWhichItemFromAdjacentNeighbor)
		}
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .GiveWhichItem)
	}
}

give_item_to_whom_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.item_icons_tick()
	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

give_item_to_whom_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, true)
	if len(game.friendly_units_in_range) == 0 {
		return
	}

	recipient := game.friendly_units_in_range[game.state_scratch.list_index]
	state_draw_item_icons(scale, defs.GIVE.positions.recipient_inventory_center, recipient, -1)
	sprites.renderer_draw_unit_info_box(scale, recipient, defs.GIVE.positions.recipient_info_box)
}
