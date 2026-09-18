package state

import game_pkg "../game"

import "core:log"

import "../catalog"
import "../defs"
import "../sprites"
import "../timers"
import unit_pkg "../unit"
import rl "vendor:raylib"

state_item_handle_slot_keys :: proc(
	game: ^game_pkg.Game,
	caster: ^unit_pkg.Unit,
	filter: sprites.Item_Slot_Filter,
) {
	if game_pkg.input_key_pressed(.UP) {
		sprites.item_ui_set_selected(&game.item_ui, .Up, caster, filter)
	}

	if game_pkg.input_key_pressed(.LEFT) {
		sprites.item_ui_set_selected(&game.item_ui, .Left, caster, filter)
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		sprites.item_ui_set_selected(&game.item_ui, .Right, caster, filter)
	}

	if game_pkg.input_key_pressed(.DOWN) {
		sprites.item_ui_set_selected(&game.item_ui, .Down, caster, filter)
	}
}

state_draw_item_radial :: proc(game: ^game_pkg.Game, scale: f32, owner: ^unit_pkg.Unit) {
	if owner == nil {
		return
	}

	directions := [4]defs.Direction{.Up, .Left, .Right, .Down}
	for direction in directions {
		index := sprites.radial_index_for_direction(direction)
		slot := owner.items[index]
		selected := index == game.item_ui.selected_index

		sprites.renderer_draw_item_icon(
			scale,
			slot.name,
			sprites.radial_icon_position(game.item_ui.center, direction),
			selected,
		)
	}
}

battle_item_menu_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current != nil {
		game_pkg.grid_calculate_unit_movement_range(&game.grid, current)
	}

	game.state_scratch.selected_command = .Use
}

battle_item_menu_exit :: proc(_: ^game_pkg.Game) {}

battle_item_menu_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_key_pressed(.UP) {
		game.state_scratch.selected_command = .Use
	}

	if game_pkg.input_key_pressed(.DOWN) {
		game.state_scratch.selected_command = .Drop
	}

	if game_pkg.input_key_pressed(.LEFT) {
		game.state_scratch.selected_command = .Give
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		game.state_scratch.selected_command = .Equip
	}

	if game_pkg.input_confirm_press() {
		battle_item_menu_confirm(game)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleActionMenu)
	}
}

battle_item_menu_confirm :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	switch game.state_scratch.selected_command {
	case .Use:
		if !unit_pkg.has_usable_item(current) {
			state_show_message_notice(game, defs.MESSAGE_NOTICE.no_item, .BattleItemMenu)
			return
		}

		state_change(game, .UseWhichItem)
	case .Drop:
		state_change(game, .DropItem)
	case .Give:
		if !unit_pkg.has_giveable_item(current) {
			log.warn("Give: no giveable items in inventory.")
			return
		}

		state_change(game, .GiveWhichItem)
	case .Equip:
		state_change(game, .EquipItem)
	case .Attack,
	     .Stay,
	     .Magic,
	     .Item,
	     .Yes,
	     .No,
	     .Talk,
	     .Search,
	     .Map,
	     .Speed,
	     .Message,
	     .Quit,
	     .Save,
	     .Cure,
	     .Raise,
	     .Promote,
	     .Buy,
	     .Deals,
	     .Sell,
	     .Repair:
	}
}

battle_item_menu_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)
}

battle_item_menu_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	center := sprites.radial_center(game.window)

	sprites.renderer_draw_battle_menu_message(
		scale,
		sprites.command_icon_display_name(game.state_scratch.selected_command),
		sprites.radial_menu_message_position(center),
	)
}

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

		game.prompt.item_slot_index = game.item_ui.selected_index

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
	timers.flip_flop_tick(&game.flip_flop)
	sprites.item_icons_tick()
}

use_which_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	state_draw_item_radial(game, scale, game_pkg.game_current_unit(game))
	sprites.renderer_draw_item_info_box(
		scale,
		sprites.item_ui_selected_data(&game.item_ui),
		false,
		game.item_ui.info_box,
	)
}

use_item_on_whom_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if current == nil {
		return
	}

	slot_index := game.prompt.item_slot_index
	if slot_index < 0 || slot_index >= defs.MAX_BUCKET_SIZE {
		log.errorf("UseItemOnWhom: invalid ItemSlotIndex. Returning to UseWhichItem.")
		state_change(game, .UseWhichItem)
		return
	}

	slot := unit_pkg.item_at(current, slot_index)
	data := catalog.item_get(slot.name)
	game.state_scratch.target_count = 0
	if data.type == .Consumable &&
	   (data.effect_type == .Heal ||
			   data.effect_type == .RemovePoison ||
			   data.effect_type == .HealAllFull) {
		game.state_scratch.use_mode = .Consumable
		if data.effect_type == .HealAllFull {
			use_item_on_whom_enter_heal_all(game, current)
			return
		}

		use_item_on_whom_enter_consumable(game, current, data)
		return
	}

	if data.spell_name != .NoSpell {
		if !defs.job_is_allowed_by(current.job, data.allowed_jobs) {
			state_change(game, .UseWhichItem)
			return
		}

		game.state_scratch.use_mode = .SpellItem
		use_item_on_whom_enter_spell(game, current, catalog.magic_get(data.spell_name))
		return
	}

	state_change(game, .UseWhichItem)
}

use_item_on_whom_push_target :: proc(game: ^game_pkg.Game, target: ^unit_pkg.Unit) {
	if target == nil || game.state_scratch.target_count >= len(game.state_scratch.targets) {
		return
	}

	for i in 0 ..< game.state_scratch.target_count {
		if game.state_scratch.targets[i] == target {
			return
		}
	}

	game.state_scratch.targets[game.state_scratch.target_count] = target
	game.state_scratch.target_count += 1
}

use_item_on_whom_enter_heal_all :: proc(game: ^game_pkg.Game, current: ^unit_pkg.Unit) {
	for unit in game.units {
		if unit != nil && unit.friendly == current.friendly && !unit_pkg.is_dead(unit) {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	use_item_on_whom_confirm_consumable_targets(game)
}

use_item_on_whom_enter_consumable :: proc(
	game: ^game_pkg.Game,
	current: ^unit_pkg.Unit,
	data: catalog.Item_Data,
) {
	game_pkg.grid_calculate_item_use_range(&game.grid, current, data)
	units := game_pkg.grid_units_in_range(&game.grid)
	defer delete(units)
	for unit in units {
		if unit != nil && unit.friendly == current.friendly {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if current.on_map && game_pkg.grid_in_range(&game.grid, current.grid_x, current.grid_y) {
		use_item_on_whom_push_target(game, current)
		// Prefer self first.
		if game.state_scratch.target_count > 1 {
			game.state_scratch.targets[0], game.state_scratch.targets[game.state_scratch.target_count - 1] =
				game.state_scratch.targets[game.state_scratch.target_count - 1],
				game.state_scratch.targets[0]
		}
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	game.state_scratch.list_index = 0
	game_pkg.game_initialize_highlight(game)
	game_pkg.game_set_highlight_target(game, game.state_scratch.targets[0])
}

use_item_on_whom_enter_spell :: proc(
	game: ^game_pkg.Game,
	current: ^unit_pkg.Unit,
	magic: catalog.Magic_Data,
) {
	game_pkg.grid_calculate_magic_attack_range(&game.grid, current, magic)
	units := game_pkg.grid_units_in_range(&game.grid)
	defer delete(units)
	for unit in units {
		if unit == nil {
			continue
		}

		if magic.offensive {
			if unit.friendly != current.friendly {
				use_item_on_whom_push_target(game, unit)
			}
		} else if unit.friendly == current.friendly {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if !magic.offensive &&
	   current.on_map &&
	   game_pkg.grid_in_range(&game.grid, current.grid_x, current.grid_y) {
		use_item_on_whom_push_target(game, current)
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	game.state_scratch.list_index = 0
	game_pkg.game_initialize_highlight(game)
	game_pkg.game_set_highlight_target(game, game.state_scratch.targets[0])
}

use_item_on_whom_exit :: proc(_: ^game_pkg.Game) {}

use_item_on_whom_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_try_cycle_index(
		&game.state_scratch.list_index,
		game.state_scratch.target_count,
	) {
		target := game.state_scratch.targets[game.state_scratch.list_index]
		if target != nil && target.on_map {
			game_pkg.game_set_highlight_target(game, target)
		}
	}

	if game_pkg.input_confirm_press() {
		if game.state_scratch.use_mode == .Consumable {
			target := game.state_scratch.targets[game.state_scratch.list_index]
			game.state_scratch.target_count = 1
			game.state_scratch.targets[0] = target

			use_item_on_whom_confirm_consumable_targets(game)
		} else {
			use_item_on_whom_confirm_spell(game)
		}
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .UseWhichItem)
	}
}

use_item_on_whom_confirm_consumable_targets :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	game_pkg.item_context_init(
		&game.item_context,
		current,
		game.state_scratch.targets[:game.state_scratch.target_count],
		&game.grid,
		game.prompt.item_slot_index,
	)

	game.battle_screen_mode = .ItemConsumable
	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
	game_pkg.grid_clear_range_set(&game.grid)

	state_change(game, .EnterBattleScreen)
}

use_item_on_whom_confirm_spell :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	slot := unit_pkg.item_at(current, game.prompt.item_slot_index)
	data := catalog.item_get(slot.name)
	magic := catalog.magic_get(data.spell_name)
	selected := game.state_scratch.targets[game.state_scratch.list_index]
	game_pkg.grid_calculate_spell_effect_range(&game.grid, selected, magic)
	aoe := game_pkg.grid_units_in_range(&game.grid)

	defer delete(aoe)

	game.state_scratch.target_count = 0
	for unit in aoe {
		if unit == nil {
			continue
		}

		if magic.offensive {
			if unit.friendly != current.friendly {
				use_item_on_whom_push_target(game, unit)
			}
		} else if unit.friendly == current.friendly {
			use_item_on_whom_push_target(game, unit)
		}
	}

	if game.state_scratch.target_count == 0 {
		state_show_message_notice(game, defs.MESSAGE_NOTICE.no_target, .UseWhichItem)
		return
	}

	game_pkg.magic_context_init(
		&game.magic_context,
		current,
		game.state_scratch.targets[:game.state_scratch.target_count],
		&game.grid,
	)

	game_pkg.magic_context_cast(&game.magic_context, data.spell_name, true)
	unit_pkg.item_apply_spell_item_durability(current, game.prompt.item_slot_index)
	sprites.item_ui_reset(&game.item_ui)
	sprites.item_ui_reset_layout_center(&game.item_ui, game.window)
	game_pkg.grid_clear_range_set(&game.grid)
	game_pkg.prompt_reset(&game.prompt)

	state_change(game, .AnimateUnitDeaths)
}

use_item_on_whom_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)

	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

use_item_on_whom_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, true)
}

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
		game.prompt.action = .DropItem
		game.prompt.item_slot_index = game.item_ui.selected_index
		game.prompt.return_state_on_no = .DropItem
		game.prompt.return_state_on_yes = .BattleItemMenu

		state_change(game, .PromptYesNo)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleItemMenu)
	}
}

drop_item_update :: proc(game: ^game_pkg.Game) {
	timers.oscillator_tick(&game.grid.range_tint)
	timers.flip_flop_tick(&game.flip_flop)
	sprites.item_icons_tick()
}

drop_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	state_draw_item_radial(game, scale, game_pkg.game_current_unit(game))
}

equip_item_slot_equippable :: proc(caster: ^unit_pkg.Unit, index: int) -> bool {
	if caster == nil || index < 0 || index > 2 {
		return false
	}

	slot := caster.items[index]
	if unit_pkg.item_slot_is_empty(slot) {
		return false
	}

	return unit_pkg.can_equip_weapon(caster, catalog.item_get(slot.name))
}

equip_item_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	game.state_scratch.list_index = 3
	game.state_scratch.equip_unarmed = true

	if current != nil && current.equipped_weapon_index >= 0 && current.equipped_weapon_index <= 2 {
		if equip_item_slot_equippable(current, current.equipped_weapon_index) {
			game.state_scratch.list_index = current.equipped_weapon_index
			game.state_scratch.equip_unarmed = false
		}
	}
}

equip_item_exit :: proc(_: ^game_pkg.Game) {}

equip_item_handle_input :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	if game_pkg.input_key_pressed(.UP) && equip_item_slot_equippable(current, 0) {
		game.state_scratch.list_index = 0
		game.state_scratch.equip_unarmed = false
	}

	if game_pkg.input_key_pressed(.LEFT) && equip_item_slot_equippable(current, 1) {
		game.state_scratch.list_index = 1
		game.state_scratch.equip_unarmed = false
	}

	if game_pkg.input_key_pressed(.RIGHT) && equip_item_slot_equippable(current, 2) {
		game.state_scratch.list_index = 2
		game.state_scratch.equip_unarmed = false
	}

	if game_pkg.input_key_pressed(.DOWN) {
		game.state_scratch.list_index = 3
		game.state_scratch.equip_unarmed = true
	}

	if game_pkg.input_confirm_press() {
		if current == nil {
			return
		}

		if game.state_scratch.equip_unarmed {
			unit_pkg.unequip_weapon(current)
		} else if equip_item_slot_equippable(current, game.state_scratch.list_index) {
			unit_pkg.equip_weapon_at(current, game.state_scratch.list_index)
		}

		state_change(game, .BattleItemMenu)
	}

	if game_pkg.input_cancel_press() {
		state_change(game, .BattleItemMenu)
	}
}

equip_item_update :: proc(game: ^game_pkg.Game) {
	timers.flip_flop_tick(&game.flip_flop)
	sprites.item_icons_tick()
}

equip_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, false, false)
	state_draw_item_radial(game, scale, game_pkg.game_current_unit(game))
}

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

		game.give.giver_slot_index = game.item_ui.selected_index
		game.give.recipient = nil
		game.give.recipient_slot_index = -1
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
	timers.flip_flop_tick(&game.flip_flop)
	sprites.item_icons_tick()
}

give_which_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, false)
	state_draw_item_radial(game, scale, game_pkg.game_current_unit(game))
}

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
		game.give.recipient = recipient
		game.give.recipient_slot_index = -1
		if unit_pkg.has_empty_item_slot(recipient) {
			game.prompt.action = .GiveItem
			game.prompt.return_state_on_yes = .EndTurn
			game.prompt.return_state_on_no = .GiveItemToWhom
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
	timers.flip_flop_tick(&game.flip_flop)
	sprites.item_icons_tick()
	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

give_item_to_whom_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, true)
	if len(game.friendly_units_in_range) == 0 {
		return
	}

	recipient := game.friendly_units_in_range[game.state_scratch.list_index]
	sprites.renderer_draw_unit_info_box(scale, recipient, defs.GIVE.positions.recipient_info_box)
}

trade_which_item_enter :: proc(game: ^game_pkg.Game) {
	current := game_pkg.game_current_unit(game)
	recipient := game.give.recipient
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
	recipient := game.give.recipient
	state_item_handle_slot_keys(game, recipient, sprites.item_ui_giveable_filter)
	if game_pkg.input_confirm_press() {
		if !sprites.item_ui_has_valid_selection(
			&game.item_ui,
			recipient,
			sprites.item_ui_giveable_filter,
		) {
			return
		}

		game.give.recipient_slot_index = game.item_ui.selected_index
		game.prompt.action = .TradeItem
		game.prompt.return_state_on_yes = .EndTurn
		game.prompt.return_state_on_no = .TradeWhichItemFromAdjacentNeighbor
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
	timers.flip_flop_tick(&game.flip_flop)
	sprites.item_icons_tick()
	game_pkg.game_update_highlight(game, rl.GetFrameTime())
}

trade_which_item_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, true, true)
	state_draw_item_radial(game, scale, game.give.recipient)
}

prompt_yes_no_enter :: proc(game: ^game_pkg.Game) {
	game.state_scratch.yes_selected = true
}

prompt_yes_no_exit :: proc(_: ^game_pkg.Game) {}

prompt_yes_no_handle_input :: proc(game: ^game_pkg.Game) {
	if game_pkg.input_key_pressed(.LEFT) {
		game.state_scratch.yes_selected = true
	}

	if game_pkg.input_key_pressed(.RIGHT) {
		game.state_scratch.yes_selected = false
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
	switch game.prompt.action {
	case .DropItem:
		if current != nil {
			unit_pkg.remove_item_at(current, game.prompt.item_slot_index)
		}
	case .GiveItem:
		if current != nil && game.give.recipient != nil {
			unit_pkg.give_item_to(current, game.give.recipient, game.give.giver_slot_index)
		}
	case .TradeItem:
		if current != nil && game.give.recipient != nil {
			unit_pkg.swap_item_with(
				current,
				game.give.recipient,
				game.give.giver_slot_index,
				game.give.recipient_slot_index,
			)
		}
	case .None:
		log.warn("PromptYesNo: No prompt action set.")
	}

	next := game.prompt.return_state_on_yes
	game_pkg.prompt_reset(&game.prompt)
	state_change(game, next)
}

prompt_yes_no_on_no :: proc(game: ^game_pkg.Game) {
	next := game.prompt.return_state_on_no
	game_pkg.prompt_reset(&game.prompt)
	state_change(game, next)
}

prompt_yes_no_update :: proc(game: ^game_pkg.Game) {
	timers.flip_flop_tick(&game.flip_flop)
}

prompt_yes_no_draw :: proc(game: ^game_pkg.Game, scale: f32) {
	state_draw_map(game, scale, false, false)
	label := "Yes" if game.state_scratch.yes_selected else "No"
	sprites.renderer_draw_battle_menu_message(scale, label, sprites.radial_center(game.window))
}
