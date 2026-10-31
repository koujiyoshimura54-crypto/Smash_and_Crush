local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = script.Parent
local Config = require(RS.Config.StrengthRewardConfig)
local Format = require(RS.Modules.NumberFormat)
local Layout = require(RS.Modules.HUDLayout)
local panel, row = require(RS.Modules.StrengthRewardUI).Build(gui)
local remote = RS.Remotes:WaitForChild("StrengthRewards")
local prices, closed, busy, view = {}, {}, false, nil
local alive = true
-- The existing HP display is Roblox CoreGui. Replace that one display with the
-- same Humanoid values; HUDLayout exclusively owns the replacement's geometry.
local health = gui.StrengthLevelHUD:WaitForChild("PlayerHealth")
local healthConnections = {}
local function clearHealth()
	for _, connection in ipairs(healthConnections) do connection:Disconnect() end
	table.clear(healthConnections)
end
local function bindHealth(character)
	clearHealth()
	local hum = character:WaitForChild("Humanoid", 10)
	if not alive or player.Character ~= character or not hum then return end
	local function render()
		health.Main.Size = UDim2.fromScale(hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0, 1)
		health.Exp.Text = Format.Format(hum.Health) .. " / " .. Format.Format(hum.MaxHealth)
	end
	table.insert(healthConnections, hum.HealthChanged:Connect(render))
	table.insert(healthConnections, hum:GetPropertyChangedSignal("MaxHealth"):Connect(render))
	render()
end
local healthAdded = player.CharacterAdded:Connect(bindHealth)
local healthRemoving = player.CharacterRemoving:Connect(clearHealth)
if player.Character then task.spawn(bindHealth, player.Character) end
task.spawn(function()
	for _ = 1, 10 do
		if not alive then return end
		if pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end) then return end
		task.wait(.5)
	end
end)
local function request(action, value)
	local ok, result = pcall(remote.InvokeServer, remote, action, value)
	return ok and type(result) == "table" and result or {Ok = false}
end
local function paint()
	if not view then return end
	local reward = view.Reward
	panel.Visible = reward ~= nil and not closed[reward.Id]
	if reward then panel.Amount.Text = "+" .. Format.Format(reward.Amount) .. " STRENGTH" end
	panel.Claim.Button.Active = not busy
	panel.Double.Button.Active = not busy and reward ~= nil and not view.Pending and prices[Config.DoubleOffline.ProductId] ~= nil
	for _, product in ipairs(Config.Packs) do
		local card = row[tostring(product.ProductId)]
		card.Amount.Text = "+" .. Format.Format(view.Offers[tostring(product.ProductId)] or 0)
		card.Purchase.Active = not busy and view.Ready and not view.Pending and prices[product.ProductId] ~= nil
	end
end
local function refresh()
	local result = request("View")
	if result.Offers then view = result; paint() end
end
local function purchase(id)
	if busy or not view or view.Pending or not prices[id] then return end
	if id == Config.DoubleOffline.ProductId and not view.Reward then return end
	busy = true; paint()
	local result = request("Prepare", id)
	if result.Ok then
		if result.RewardId then panel.Amount.Text = "+" .. Format.Format(result.Amount) .. " STRENGTH"
		else row[tostring(id)].Amount.Text = "+" .. Format.Format(result.Amount) end
		-- The displayed amount is the persisted server quote before native checkout.
		request("Open", {ProductId = id, IntentId = result.IntentId})
	end
	busy = false; refresh()
end
panel.Close.Button.Activated:Connect(function() if view and view.Reward then closed[view.Reward.Id] = true end; panel.Visible = false end)
panel.Claim.Button.Activated:Connect(function()
	if busy or not view or not view.Reward then return end
	busy = true; paint(); request("Claim", view.Reward.Id); busy = false; refresh()
end)
panel.Double.Button.Activated:Connect(function() purchase(Config.DoubleOffline.ProductId) end)
for _, product in ipairs(Config.Packs) do row[tostring(product.ProductId)].Purchase.Activated:Connect(function() purchase(product.ProductId) end) end
local function fetchPrice(product, button)
	if product.ProductId <= 0 then return end
	local ok, info = pcall(Marketplace.GetProductInfoAsync, Marketplace, product.ProductId, Enum.InfoType.Product)
	-- Client lookup uses the same player context as regional/personalized checkout.
	if ok and type(info) == "table" and info.IsForSale == true and type(info.PriceInRobux) == "number" then
		prices[product.ProductId] = info.PriceInRobux
		Layout.PurchaseButton(button, "Robux", info.PriceInRobux); paint()
	end
end
for _, product in ipairs(Config.Packs) do task.spawn(fetchPrice, product, row[tostring(product.ProductId)].Purchase) end
task.spawn(fetchPrice, Config.DoubleOffline, panel.Double.Price)
local revision = player:GetAttributeChangedSignal("StrengthRewardRevision"):Connect(function() task.defer(refresh) end)
script.Destroying:Once(function() alive = false; revision:Disconnect(); clearHealth(); healthAdded:Disconnect(); healthRemoving:Disconnect() end)
task.spawn(function() while alive do refresh(); task.wait(2) end end)
