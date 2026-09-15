package game

Direction :: enum {
    Up,
    Right,
    Down,
    Left
}

Game_State :: enum {
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

Item_Name :: enum {
    NoItem,

    Unarmed,

    ShortSword,
}

Job :: enum {
    Lawyer,
}

Movement :: enum {

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
