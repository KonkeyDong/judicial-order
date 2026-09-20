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
	case .SmallBriefcase:
		return item_make_weapon(.SmallBriefcase, 5, .Briefcase, melee, swordsman, 100)
	case .MediumBriefcase:
		return item_make_weapon(.MediumBriefcase, 8, .Briefcase, melee, swordsman, 250)
	case .LargeBriefcase:
		return item_make_weapon(.LargeBriefcase, 12, .Briefcase, melee, {.Swordsman, .Warrior}, 750)
	case .SteelBriefcase:
		return item_make_weapon(.SteelBriefcase, 18, .Briefcase, melee, hero, 2500)
	case .BroadBriefcase:
		return item_make_weapon(.BroadBriefcase, 20, .Briefcase, melee, hero, 4800)
	case .AttacheBriefcase:
		return item_make_weapon(.AttacheBriefcase, 25, .Briefcase, melee, hero, 0)
	case .LaptopBriefcase:
		return item_make_weapon(.LaptopBriefcase, 30, .Briefcase, melee, hero, 0)
	case .BriefcaseOfHonor:
		return item_make_weapon(.BriefcaseOfHonor, 36, .Briefcase, melee, light_sword, 0, .Bolt2)
	case .BriefcaseOfJustice:
		return item_make_weapon(
			.BriefcaseOfJustice,
			40,
			.Briefcase,
			melee,
			light_sword,
			0,
			.Desoul1,
			true,
		)
	case .LawBreaker:
		return item_make_weapon(.LawBreaker, 40, .Briefcase, melee, light_sword, 0, .Freeze3)
	case .Gavel:
		return item_make_weapon(.Gavel, 7, .Gavel, melee, {.Warrior}, 200)
	case .OakGavel:
		return item_make_weapon(.OakGavel, 11, .Gavel, melee, {.Warrior}, 600)
	case .EbonyGavel:
		return item_make_weapon(.EbonyGavel, 16, .Gavel, melee, {.Warrior}, 2600)
	case .HouseGavel:
		return item_make_weapon(.HouseGavel, 22, .Gavel, melee, {.Gladiator}, 0, .Blaze2)
	case .SenateGavel:
		return item_make_weapon(.SenateGavel, 26, .Gavel, melee, {.Gladiator}, 10000)
	case .SupremeCourtGavel:
		return item_make_weapon(.SupremeCourtGavel, 33, .Gavel, melee, {.Gladiator}, 0, .Blaze3)
	case .Pencil:
		return item_make_weapon(.Pencil, 5, .Pen, melee, healer_mage, 80)
	case .GelPen:
		return item_make_weapon(.GelPen, 8, .Pen, melee, healer_mage, 500)
	case .BallpointPen:
		return item_make_weapon(.BallpointPen, 12, .Pen, melee, vicar_wizard, 3200)
	case .FountainPen:
		return item_make_weapon(.FountainPen, 18, .Pen, melee, {.Vicar}, 8000, .Blaze2)
	case .CalligraphyPen:
		return item_make_weapon(.CalligraphyPen, 20, .Pen, melee, {.Wizard}, 0)
	case .Subpoena:
		return item_make_weapon(.Subpoena, 8, .RangedWeapon, bow, archer, 320)
	case .SummonsNotice:
		return item_make_weapon(.SummonsNotice, 13, .RangedWeapon, bow, archer, 1200)
	case .EvictionNotice:
		return item_make_weapon(.EvictionNotice, 18, .RangedWeapon, longbow, sniper, 3200)
	case .SearchWarrant:
		return item_make_weapon(.SearchWarrant, 27, .RangedWeapon, longbow, bowmaster, 4500)
	case .DeathWarrant:
		return item_make_weapon(.DeathWarrant, 35, .RangedWeapon, longbow, bowmaster, 12400)
	case .Spear:
		return item_make_weapon(.Spear, 8, .Spear, reach, knight, 150)
	case .PowerSpear:
		return item_make_weapon(.PowerSpear, 8, .Spear, reach, knight, 900)
	case .BronzeScales:
		return item_make_weapon(.BronzeScales, 9, .Scales, melee, knight, 300)
	case .SteelScales:
		return item_make_weapon(.SteelScales, 18, .Scales, melee, paladin, 3000)
	case .ChromeScales:
		return item_make_weapon(.ChromeScales, 22, .Scales, melee, paladin, 4500)
	case .MassScales:
		return item_make_weapon(.MassScales, 25, .Scales, melee, paladin, 0, .Bolt1)
	case .UnbalancedScales:
		return item_make_weapon(.UnbalancedScales, 35, .Scales, melee, paladin, 0, .NoSpell, true)
	case .ScalesOfHonor:
		return item_make_weapon(.ScalesOfHonor, 35, .Scales, melee, paladin, 0)
	case .Hotdog:
		return item_make_consumable(.Hotdog, {0, 1}, 10, .Heal, 10)
	case .FoisGras:
		return item_make_consumable(.FoisGras, {0, 1}, 200, .Heal, 20)
	case .Antidote:
		return item_make_consumable(.Antidote, {0, 1}, 20, .RemovePoison, 0)
	case .StrategicWithdrawal:
		return item_make_consumable(.StrategicWithdrawal, {0, 0}, 40, .Escape, 0)
	case .Caviar:
		return item_make_consumable(.Caviar, {0, 0}, 0, .HealAllFull, 999)
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
	case .Unarmed, .Briefcase, .Gavel, .Pen, .RangedWeapon, .Spear, .Scales:
		return true
	}

	return false
}
