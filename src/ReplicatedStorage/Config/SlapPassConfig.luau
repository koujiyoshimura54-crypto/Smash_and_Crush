local Config = {
	GamePassId = 1987256653,
	ToolName = "Slap Hand",
	ToolTemplateName = "SlapToolTemplate",
	PlayerCollisionGroup = "PlayerCharacters",
	SlapDistance = 8,
	MinimumFacingDot = -0.15,
	HorizontalKnockback = 60,
	UpwardKnockback = 20,
	Cooldown = 5,
	HitDelay = 0.2,
	SwingLockout = 0.35,
	-- Store R15 asset 102083458174016 is retained in the template but is not shared with this experience.
	AnimationPlaybackEnabled = false,
	PromptDistance = 8,
	PromptCooldown = 30,
	PromptScanInterval = 0.5,
}

return table.freeze(Config)
