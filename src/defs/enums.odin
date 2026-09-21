package defs

Direction :: enum {
	Up,
	Right,
	Down,
	Left,
}

Item_Name :: enum {
	NoItem,
	Unarmed,

	// Briefcases
	SmallBriefcase, // ShortSword,
	MediumBriefcase, // MiddleSword,
	LargeBriefcase, // LongSword,
	SteelBriefcase, // SteelSword,
	BroadBriefcase, // BroadSword,
	AttacheBriefcase, // DoomBlade,
	LaptopBriefcase, // Katana,
	BriefcaseOfHonor, // SwordOfLight,
	BriefcaseOfJustice, // SwordOfDarkness,
	LawBreaker, // ChaosBreaker,

	// Gavels (warriors, gladiators)
	Gavel, // HandAxe,
	OakGavel, // MiddleAxe,
	EbonyGavel, // BattleAxe,
	HouseGavel, // HeatAxe,
	SenateGavel, // GreatAxe,
	SupremeCourtGavel, // Atlas,

	// Pens (healers + mages)
	Pencil, // WoodenStaff,
	GelPen, // PowerStaff,
	BallpointPen, // GuardianStaff,
	FountainPen, // HolyStaff,
	CalligraphyPen, // DemonRod,

	// Ranged Weapons
	Subpoena, // WoodenArrow,
	SummonsNotice, // SteelArrow,
	EvictionNotice, // ElvenArrow,
	SearchWarrant, // AssaultShell,
	DeathWarrant, // BusterShot,

	// Spears
	Spear,
	PowerSpear,

	// Scales
	BronzeScales, // BronzeLance,
	SteelScales, // SteelLance,
	ChromeScales, // ChromeLance,
	MassScales, // Halberd,
	UnbalancedScales, // DevilLance,
	ScalesOfHonor, // Valkyrie,

	// Consumable Items
	Hotdog, // MedicalHerb,
	FoisGras, // HealingSeed,
	Caviar, // ShowerOfCure,
	Antidote,
	StrategicWithdrawal, // AngelWing,
	BreadOfLife,
	PowerPotion,
	DefensePotion,
	LegsOfHaste,
	TurboPepper,
	OrbOfLight,
	DomingoEgg,
	MoonStone,
	LunarDew,
	SugoiMizugi,
	KituiHuku,
}

Job_Kind :: enum u32 {
	Swordsman,
	Hero,
	Warrior,
	Gladiator,
	Archer,
	BowMaster,
	Mage,
	Wizard,
	Knight,
	Paladin,
	Birdman,
	SkyWarrior,
	Ninja,
	Samurai,
	Healer,
	Vicar,
	Sniper,
	Robot,
	Cyborg,
	Dragon,
	GreatDragon,
	AssaultKnight,
	StrikeKnight,
	SkyKnight,
	SkyLord,
	SkyBaron,
	Monster,
}

Job :: bit_set[Job_Kind;u32]

JOB_ANY :: ~Job{}

job_is_allowed_by :: proc(unit_job, allowed: Job) -> bool {
	return (allowed & unit_job) != {}
}

Movement_Type :: enum {
	Warrior,
	Flyer,
	Horse,
	Mage,
	Thief,
	Archer,
	Werewolf,
}

Terrain :: enum {
	Road,
	Plains,
	Marsh,
	Forest,
	Hill,
	Mountain,
	Sand,
	Impassable,
	Water,
	Floor,
}

Attack_Effect :: enum {
	NormalAttack,
	ArtilleryExplosion,
	BattleFieldDeath,
}

Status_Effect :: enum {
	None,
	Poison,
	Sleep,
}

Name :: enum {
	Hale,
	Judy,
	Trudy,
	Anthony,
	Bellweather,
}

Item_Type :: enum {
	Unarmed,
	Briefcase, // Sword,
	Gavel, // Axe,
	Pen, //Staff,
	RangedWeapon, // Arrow,
	Spear,
	Scales, // Lance,
	Consumable,
	Story,
	Ring,
	Clothes,
}

Item_Effect :: enum {
	None,
	Heal,
	RemovePoison,
	Escape,
	HealAllFull,
}

Magic_Name :: enum {
	Blaze1,
	Blaze2,
	Blaze3,
	Blaze4,
	Freeze1,
	Freeze2,
	Freeze3,
	Freeze4,
	Bolt1,
	Bolt2,
	Bolt3,
	Bolt4,
	Desoul1,
	Desoul2,
	Dispel1,
	Muddle1,
	Sleep1,
	Egress1,
	Detox1,
	Shield1,
	Boost1,
	Slow1,
	Slow2,
	Quick1,
	Quick2,
	Heal1,
	Heal2,
	Heal3,
	Heal4,
	Aura1,
	Aura2,
	Aura3,
	Aura4,
	NoSpell,
}

Magic_Family :: enum {
	Blaze,
	Freeze,
	Bolt,
	Heal,
	Aura,
	Slow,
	Quick,
	Desoul,
	Dispel,
	Muddle,
	Sleep,
	Egress,
	Detox,
	Shield,
	Boost,
	NoSpell,
}

Magic_Type :: enum {
	Ice,
	Fire,
	Lightning,
	Heal,
	Buff,
	Debuff,
	Misc,
}

Magic_Effect :: enum {
	None,
	Damage,
	Heal,
	Egress,
	Desoul,
}

Battle_Screen_Mode :: enum {
	Combat,
	ItemConsumable,
}

Prompt_Action :: enum {
	None,
	DropItem,
	GiveItem,
	TradeItem,
}

Command_Icon :: enum {
	Yes,
	No,
	Talk,
	Magic,
	Item,
	Search,
	Attack,
	Stay,
	Use,
	Give,
	Equip,
	Drop,
	Map,
	Speed,
	Message,
	Quit,
	Save,
	Cure,
	Raise,
	Promote,
	Buy,
	Deals,
	Sell,
	Repair,
}

Use_Mode :: enum {
	Consumable,
	SpellItem,
}

// Battle states only. Mirrors src/state/state.odin Kind.
State_Kind :: enum {
	UnitMoving,
	EndTurn,
	CalculateUnitMovementRange,
	CalculateWeaponAttackRange,
	PrepareMagicTargets,
	BattleActionMenu,
	BattleItemMenu,
	SelectingAction,
	SelectEnemyForPhysicalAttack,
	TransitionSelectorToNextUnit,
	AnimateUnitDeaths,
	SelectMagic,
	SelectMagicLevel,
	MessageNotice,
	SelectMagicTargets,
	BattleResolution,
	BattleResolutionDebug,
	EnterBattleScreen,
	ExitBattleScreen,
	DropItem,
	PromptYesNo,
	EquipItem,
	UseWhichItem,
	UseItemOnWhom,
	UseConsumableBattle,
	GiveWhichItem,
	GiveItemToWhom,
	TradeWhichItemFromAdjacentNeighbor,
}
