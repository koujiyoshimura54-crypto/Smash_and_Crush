-- Current approved configuration. Prices are reference metadata, never UI prices.
local C = {
	Offline = {MaxSeconds = 3600, Efficiency = 0.05, DecayBands = {}},
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
function C.OfflineAmount(rate, elapsed)
	local seconds = math.clamp(elapsed, 0, C.Offline.MaxSeconds)
	local amount, start = 0, 0
	-- Ordered bands override efficiency within their cumulative EndSeconds.
	for _, band in ipairs(C.Offline.DecayBands) do
		local finish = math.min(seconds, band.EndSeconds)
		amount += math.max(0, finish - start) * band.Efficiency
		start = finish
		if start >= seconds then break end
	end
	return rate * (amount + math.max(0, seconds - start) * C.Offline.Efficiency)
end
return C
