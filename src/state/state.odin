package state

import game ".."

Kind :: enum {
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

init :: proc(gameplay: ^game.Game, kind: Kind) {
	gameplay.state = kind
	enter(gameplay)
}
