-- Server-only Studio validation settings. Runtime guards must also use RunService:IsStudio().
return {
 GamePassEffectsEnabled=false,
 ForceSpeedPremiumUnowned=false,
 ProductionCreatorGamePassEffectsEnabled=false,
 ProductionCreatorUserIds={[7467238848]=true},
 -- Limited Egg Studio tests only; never grants creator/GamePass/debug-command privileges.
 LimitedEggTestUserIds={[7467238848]=true,[10591394123]=true,[10653503502]=true},
 Start={Enabled=true,AutoApplyOnPlay=false,ChatCommandsEnabled=true,Defaults={Level=45,World=2,Stage=1},StartLevel=45,StartWorld=2,StartStage=1},
}

