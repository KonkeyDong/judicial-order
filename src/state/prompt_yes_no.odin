package state

import game_pkg "../game"

import "core:log"

import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"


prompt_yes_no_enter :: proc(game: ^game_pkg.Game) {
	game.state_scratch.yes_selected = true
	sprites.command_icons_set_selected(.Yes)
}

prompt_yes_no_exit :: proc(_: ^game_pkg.Game) {}

prompt_yes_no_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_key_pressed(.LEFT) {
		game.state_scratch.yes_selected = true
		sprites.command_icons_set_selected(.Yes)
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		game.state_scratch.yes_selected = false
		sprites.command_icons_set_selected(.No)
	}

	if game_pkg.input_confirm_press() {
		if game.state_scratch.yes_selected {
			prompt_yes_no_on_yes(game)
		} else {
			prompt_yes_no_on_no(game)
		}
	}

	if game_pkg.input_cancel_press() {
		prompt_yes_no_on_no(game)
	}
}

prompt_yes_no_on_yes :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	switch game.contexts.prompt.action {
	case .DropItem:
		if current != nil {
			unit_pkg.remove_item_at(current, game.contexts.prompt.item_slot_index)
		}
	case .GiveItem:
		if current != nil && game.contexts.give.recipient != nil {
			unit_pkg.give_item_to(
				current,
				game.contexts.give.recipient,
				game.contexts.give.giver_slot_index,
			)
		}
	case .TradeItem:
		if current != nil && game.contexts.give.recipient != nil {
			unit_pkg.swap_item_with(
				current,
				game.contexts.give.recipient,
				game.contexts.give.giver_slot_index,
				game.contexts.give.recipient_slot_index,
			)
		}
	case .None:
		log.warn("PromptYesNo: No prompt action set.")
	}

	next := game.contexts.prompt.return_state_on_yes
	game_pkg.prompt_reset(&game.contexts.prompt)
	state_change(game, next)
}

prompt_yes_no_on_no :: proc(game: ^game_pkg.Game) {
	next := game.contexts.prompt.return_state_on_no
	game_pkg.prompt_reset(&game.contexts.prompt)
	state_change(game, next)
}

prompt_yes_no_update :: proc(game: ^game_pkg.Game) {
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.command_icons_tick()
}

prompt_yes_no_is_give_or_trade :: proc(game: ^game_pkg.Game) -> bool {
	return game.contexts.prompt.action == .GiveItem || game.contexts.prompt.action == .TradeItem
}

prompt_yes_no_draw_trade_summary :: proc(game: ^game_pkg.Game, scale: f32) {
	current := game_pkg.game_current_unit(game)
	recipient := game.contexts.give.recipient
	if current == nil || recipient == nil {
		return
	}

	giver_index := game.contexts.give.giver_slot_index
	if giver_index < 0 || giver_index >= defs.MAX_BUCKET_SIZE {
		return
	}

	giver_item := unit_pkg.item_display_name(current.items[giver_index].name)
	receiver_item: defs.Item_Name
	has_receiver := false
	action := "Give"
	if game.contexts.prompt.action == .TradeItem {
		action = "Swap"
		receiver_index := game.contexts.give.recipient_slot_index
		if receiver_index < 0 || receiver_index >= defs.MAX_BUCKET_SIZE {
			return
		}

		receiver_item = unit_pkg.item_display_name(recipient.items[receiver_index].name)
		has_receiver = true
	}

	sprites.renderer_draw_trade_prompt_box(
		scale,
		action,
		defs.name_display(current.name),
		giver_item,
		defs.name_display(recipient.name),
		receiver_item,
		has_receiver,
		defs.GIVE.positions.trade_prompt_box,
	)
}

prompt_yes_no_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, false, false)
	if prompt_yes_no_is_give_or_trade(game) {
		prompt_yes_no_draw_trade_summary(game, scale)
	}

	y_factor :=
		defs.GIVE.trade_prompt_yes_no_y_factor if prompt_yes_no_is_give_or_trade(game) else sprites.RADIAL_Y_FACTOR
	center := sprites.radial_center(game.window, y_factor)
	gap := f32(defs.TILE_SIZE) * 0.75
	sprites.renderer_draw_command_icon(scale, .Yes, {center.x - gap, center.y})
	sprites.renderer_draw_command_icon(scale, .No, {center.x + gap, center.y})

	label := "Yes" if game.state_scratch.yes_selected else "No"
	sprites.renderer_draw_battle_menu_message(
		scale,
		label,
		{center.x + sprites.RADIAL_INFO_BOX_OFFSET_X, center.y + 10},
	)
}
