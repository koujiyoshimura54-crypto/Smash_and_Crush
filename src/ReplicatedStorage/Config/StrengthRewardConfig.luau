-- Current approved configuration. Prices are reference metadata, never UI prices.
local C = {
	Offline = {MaxSeconds = 86400, HourlyFraction = 0.04},
	DoubleOffline = {Name = "double offline reward", ProductId = 3724845103, BasePrice = 19},
	Packs = {
		{Name = "Small Strength Pack", ProductId = 3724835102, BasePrice = 19, Seconds = 120},
		{Name = "Medium Strength Pack", ProductId = 3724835678, BasePrice = 99, Seconds = 720},
		{Name = "Large Strength Pack", ProductId = 3724836170, BasePrice = 299, Seconds = 2400},
	},
}
function C.ForProduct(id)
	for _, product in ipairs(C.Packs) do if product.ProductId == id then return product, "Pack" end end
	if C.DoubleOffline.ProductId > 0 and id == C.DoubleOffline.ProductId then return C.DoubleOffline, "DoubleOffline" end
end
function C.OfflineSeconds(elapsed)
	assert(type(elapsed) == "number" and elapsed == elapsed and math.abs(elapsed) < math.huge, "InvalidOfflineTime")
	return math.clamp(elapsed, 0, C.Offline.MaxSeconds)
end
function C.OfflineAmount(departureStrength, elapsed)
	assert(type(departureStrength) == "number" and departureStrength >= 0 and departureStrength < math.huge, "InvalidDepartureStrength")
	-- Multiply by the bounded fraction last: preserve fractional Strength and avoid
	-- overflowing an intermediate Strength * seconds for otherwise finite rewards.
	return departureStrength * (C.Offline.HourlyFraction * (C.OfflineSeconds(elapsed) / 3600))
end
return C
