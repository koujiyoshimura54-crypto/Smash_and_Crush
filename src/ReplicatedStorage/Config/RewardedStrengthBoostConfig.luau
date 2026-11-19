-- Loaded once per server/client session. Restart Play (or a published server) after editing.
return {
	Enabled = true, -- Stops NEW ads/shop prompts when false; already-paid receipts/time are honored.
	ProductId = 3733706770, -- Developer Product, not the permanent Strength pass (2089895831).
	PlacementId = 28777229838999,
	ProductName = "5 Min Strength Boost",
	DurationSeconds = 300, -- Real elapsed seconds, including time offline.
	TrainingBonus = 1, -- Added once to the training source multiplier, not final gain ×2.
	RequestCooldownSeconds = 3,
	ClientResponseTimeoutSeconds = 120,
}
