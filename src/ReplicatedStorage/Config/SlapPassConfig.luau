local Config = {
	GamePassId = 1987256653,
	ToolName = "Slap Hand",
	PlayerCollisionGroup = "PlayerCharacters",
	SlapDistance = 8,
	MinimumFacingDot = -0.15,
	HorizontalKnockback = 60,
	UpwardKnockback = 20,
	Cooldown = 5,
	PromptDistance = 8,
	PromptCooldown = 30,
	PromptScanInterval = 0.5,
}

return table.freeze(Config)
