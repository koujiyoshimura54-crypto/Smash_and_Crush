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
	ReceiptWaitSeconds = 1, -- Memory-only contention/lifecycle checks, only while a receipt is pending.
	ReceiptRecoverySeconds = 30, -- Slow recovery after the existing mutation retries.
	AvailabilityCacheSeconds = 60,
	AvailabilityRetrySeconds = 5, -- Coalesce natural UI recovery opportunities.
	AvailabilityTimeoutSeconds = 15,
	AvailabilityDiagnostics = false, -- Bounded client-memory records; no logs or saves.
}
