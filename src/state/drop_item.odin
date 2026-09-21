package state

import game_pkg "../game"

import "../sprites"
import "../timers"

drop_item_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current != nil {
		game_pkg.grid_calculate_unit_movement_range(&game.grid, current)
	}

	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
	sprites.item_ui_set_selected(&game.item_ui, .Up, current, sprites.item_ui_giveable_filter)
}

drop_item_exit :: proc(_: ^game_pkg.Game) {}

drop_item_handle_input :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	state_item_handle_slot_keys(game, current, sprites.item_ui_giveable_filter)
	if game_pkg.input_confirm_press() {
		game.contexts.prompt.action = .DropItem
		game.contexts.prompt.item_slot_index = game.item_ui.selected_index
		game.contexts.prompt.return_state_on_no = .DropItem
		game.contexts.prompt.return_state_on_yes = .BattleItemMenu

		state_change(game, .PromptYesNo)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleItemMenu)
	}
}

drop_item_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.overworld_idle_flip_flop)
	sprites.item_icons_tick()
}

drop_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	state_draw_item_radial(game, scale, game_pkg.game_current_unit(game))
}
