package catalog

import "core:log"

import "../defs"

Item_Data :: struct {
	name:           defs.Item_Name,
	type:           defs.Item_Type,
	price:          int,
	attack:         int,
	distance_range: defs.Tile_Range,
	allowed_jobs:   defs.Job,
	cursed:         bool,
	effect_type:    defs.Item_Effect,
	effect_value:   int,
	spell_name:     defs.Magic_Name,
}

NO_ITEM_DATA :: Item_Data {
	name           = .NoItem,
	type           = .Consumable,
	price          = 0,
	attack         = 0,
	distance_range = {0, 0},
	allowed_jobs   = defs.JOB_ANY,
	cursed         = false,
	effect_type    = .None,
	effect_value   = 0,
	spell_name     = .NoSpell,
}

item_make_weapon :: proc(
	name: defs.Item_Name,
	attack: int,
	item_type: defs.Item_Type,
	distance: defs.Tile_Range,
	jobs: defs.Job,
	price: int,
	spell_name: defs.Magic_Name = .NoSpell,
	cursed := false,
) -> Item_Data {
	return Item_Data {
		name = name,
		type = item_type,
		price = price,
		attack = attack,
		distance_range = distance,
		allowed_jobs = jobs,
		cursed = cursed,
		effect_type = .None,
		effect_value = 0,
		spell_name = spell_name,
	}
}

item_make_consumable :: proc(
	name: defs.Item_Name,
	distance: defs.Tile_Range,
	price: int,
	effect_type: defs.Item_Effect,
	effect_value: int,
) -> Item_Data {
	return Item_Data {
		name = name,
		type = .Consumable,
		price = price,
		attack = 0,
		distance_range = distance,
		allowed_jobs = defs.JOB_ANY,
		cursed = false,
		effect_type = effect_type,
		effect_value = effect_value,
		spell_name = .NoSpell,
	}
}

item_unregistered :: proc(name: defs.Item_Name, item_type: defs.Item_Type) -> Item_Data {
	return Item_Data {
		name = name,
		type = item_type,
		price = 0,
		attack = 0,
		distance_range = {0, 0},
		allowed_jobs = defs.JOB_ANY,
		cursed = false,
		effect_type = .None,
		effect_value = 0,
		spell_name = .NoSpell,
	}
}

init :: proc() {
}

item_get :: proc(name: defs.Item_Name) -> Item_Data {
	melee := defs.Tile_Range{1, 1}
	reach := defs.Tile_Range{1, 2}
	bow := defs.Tile_Range{2, 2}
	longbow := defs.Tile_Range{2, 3}
	swordsman := defs.Job{.Swordsman, .Warrior, .Birdman}
	hero := defs.Job{.Hero, .Ninja, .SkyWarrior, .Samurai}
	light_sword := defs.Job{.Hero, .SkyWarrior}
	healer_mage := defs.Job{.Healer, .Mage}
	vicar_wizard := defs.Job{.Vicar, .Wizard}
	archer := defs.Job{.Archer, .AssaultKnight}
	sniper := defs.Job{.Archer, .Sniper, .BowMaster, .AssaultKnight, .StrikeKnight}
	bowmaster := defs.Job{.StrikeKnight, .BowMaster, .Sniper}
	knight := defs.Job{.Knight, .SkyKnight}
	paladin := defs.Job{.Paladin, .SkyBaron, .SkyLord}

	switch name {
	case .NoItem:
		return NO_ITEM_DATA
	case .Unarmed:
		return item_make_weapon(.Unarmed, 0, .Unarmed, melee, defs.JOB_ANY, 0)
	case .ShortSword:
		return item_make_weapon(.ShortSword, 5, .Sword, melee, swordsman, 100)
	case .MiddleSword:
		return item_make_weapon(.MiddleSword, 8, .Sword, melee, swordsman, 250)
	case .LongSword:
		return item_make_weapon(.LongSword, 12, .Sword, melee, {.Swordsman, .Warrior}, 750)
	case .SteelSword:
		return item_make_weapon(.SteelSword, 18, .Sword, melee, hero, 2500)
	case .BroadSword:
		return item_make_weapon(.BroadSword, 20, .Sword, melee, hero, 4800)
	case .DoomBlade:
		return item_make_weapon(.DoomBlade, 25, .Sword, melee, hero, 0)
	case .Katana:
		return item_make_weapon(.Katana, 30, .Sword, melee, hero, 0)
	case .SwordOfLight:
		return item_make_weapon(.SwordOfLight, 36, .Sword, melee, light_sword, 0, .Bolt2)
	case .SwordOfDarkness:
		return item_make_weapon(
			.SwordOfDarkness,
			40,
			.Sword,
			melee,
			light_sword,
			0,
			.Desoul1,
			true,
		)
	case .ChaosBreaker:
		return item_make_weapon(.ChaosBreaker, 40, .Sword, melee, light_sword, 0, .Freeze3)
	case .HandAxe:
		return item_make_weapon(.HandAxe, 7, .Axe, melee, {.Warrior}, 200)
	case .MiddleAxe:
		return item_make_weapon(.MiddleAxe, 11, .Axe, melee, {.Warrior}, 600)
	case .BattleAxe:
		return item_make_weapon(.BattleAxe, 16, .Axe, melee, {.Warrior}, 2600)
	case .HeatAxe:
		return item_make_weapon(.HeatAxe, 22, .Axe, melee, {.Gladiator}, 0, .Blaze2)
	case .GreatAxe:
		return item_make_weapon(.GreatAxe, 26, .Axe, melee, {.Gladiator}, 10000)
	case .Atlas:
		return item_make_weapon(.Atlas, 33, .Axe, melee, {.Gladiator}, 0, .Blaze3)
	case .WoodenStaff:
		return item_make_weapon(.WoodenStaff, 5, .Staff, melee, healer_mage, 80)
	case .PowerStaff:
		return item_make_weapon(.PowerStaff, 8, .Staff, melee, healer_mage, 500)
	case .GuardianStaff:
		return item_make_weapon(.GuardianStaff, 12, .Staff, melee, vicar_wizard, 3200)
	case .HolyStaff:
		return item_make_weapon(.HolyStaff, 18, .Staff, melee, {.Vicar}, 8000, .Blaze2)
	case .DemonRod:
		return item_make_weapon(.DemonRod, 20, .Staff, melee, {.Wizard}, 0)
	case .WoodenArrow:
		return item_make_weapon(.WoodenArrow, 8, .Arrow, bow, archer, 320)
	case .SteelArrow:
		return item_make_weapon(.SteelArrow, 13, .Arrow, bow, archer, 1200)
	case .ElvenArrow:
		return item_make_weapon(.ElvenArrow, 18, .Arrow, longbow, sniper, 3200)
	case .AssaultShell:
		return item_make_weapon(.AssaultShell, 27, .Arrow, longbow, bowmaster, 4500)
	case .BusterShot:
		return item_make_weapon(.BusterShot, 35, .Arrow, longbow, bowmaster, 12400)
	case .Spear:
		return item_make_weapon(.Spear, 8, .Spear, reach, knight, 150)
	case .PowerSpear:
		return item_make_weapon(.PowerSpear, 8, .Spear, reach, knight, 900)
	case .BronzeLance:
		return item_make_weapon(.BronzeLance, 9, .Lance, melee, knight, 300)
	case .SteelLance:
		return item_make_weapon(.SteelLance, 18, .Lance, melee, paladin, 3000)
	case .ChromeLance:
		return item_make_weapon(.ChromeLance, 22, .Lance, melee, paladin, 4500)
	case .Halberd:
		return item_make_weapon(.Halberd, 25, .Lance, melee, paladin, 0, .Bolt1)
	case .DevilLance:
		return item_make_weapon(.DevilLance, 35, .Lance, melee, paladin, 0, .NoSpell, true)
	case .Valkyrie:
		return item_make_weapon(.Valkyrie, 35, .Lance, melee, paladin, 0)
	case .MedicalHerb:
		return item_make_consumable(.MedicalHerb, {0, 1}, 10, .Heal, 10)
	case .HealingSeed:
		return item_make_consumable(.HealingSeed, {0, 1}, 200, .Heal, 20)
	case .Antidote:
		return item_make_consumable(.Antidote, {0, 1}, 20, .RemovePoison, 0)
	case .AngelWing:
		return item_make_consumable(.AngelWing, {0, 0}, 40, .Escape, 0)
	case .ShowerOfCure:
		return item_make_consumable(.ShowerOfCure, {0, 0}, 0, .HealAllFull, 999)
	case .BreadOfLife, .PowerPotion, .DefensePotion, .LegsOfHaste, .TurboPepper:
		return item_unregistered(name, .Consumable)
	case .OrbOfLight, .DomingoEgg, .MoonStone, .LunarDew:
		return item_unregistered(name, .Story)
	case .SugoiMizugi, .KituiHuku:
		return item_unregistered(name, .Clothes)
	}

	log.errorf("ItemDatabase.Get(): Unknown item [%v]. Returning NoItem.", name)
	return NO_ITEM_DATA
}

item_sell_price :: proc(data: Item_Data) -> int {
	return int(f32(data.price) * 0.75)
}

item_type_is_weapon :: proc(item_type: defs.Item_Type) -> bool {
	#partial switch item_type {
	case .Unarmed, .Sword, .Axe, .Staff, .Arrow, .Spear, .Lance:
		return true
	}

	return false
}
