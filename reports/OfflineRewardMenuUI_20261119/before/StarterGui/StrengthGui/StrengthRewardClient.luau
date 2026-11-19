local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")
local Feedback=require(RS.Modules.UIFeedback)
local player = Players.LocalPlayer
local gui = script.Parent
local Config = require(RS.Config.StrengthRewardConfig)
local Format = require(RS.Modules.NumberFormat)
local Layout = require(RS.Modules.HUDLayout)
local Presentation = require(RS.Modules.StrengthHUDPresentation)
local RewardUI = require(RS.Modules.StrengthRewardUI)
local panel, row = RewardUI.Build(gui)
local remote = RS.Remotes:WaitForChild("StrengthRewards")
local prices, closed, busy, view = {}, {}, false, nil
local alive = true
local viewRevision, activeClaim = 0, nil
local claimTitle = panel.Claim.Title.Text
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
		Presentation.SetFill(health, hum.MaxHealth > 0 and hum.Health / hum.MaxHealth or 0)
		health.Exp.Text = Presentation.Number(hum.Health) .. "/" .. Presentation.Number(hum.MaxHealth)
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
local function request(action, value, quiet, token)
	local ok, result = pcall(remote.InvokeServer, remote, action, value, token)
	if ok and type(result)=="table" then
		if not quiet and action~="View" and result.Ok==false then Feedback.Denied(result.Code) end
	end
	return ok and type(result) == "table" and result or {Ok = false, Code = "Retry"}
end
local function paint()
	if not view then return end
	local reward = view.Reward
	panel.Visible = reward ~= nil and not closed[reward.Id]
	if reward then
		panel.Title.Text = RewardUI.DurationTitle(reward.Seconds)
		panel.Amount.Text = "+" .. Format.Format(reward.Amount) .. " STRENGTH"
	end
	panel.Claim.Title.Text = activeClaim and "Claiming..." or claimTitle
	panel.Claim.Button.Active = not busy
	panel.Double.Button.Active = not busy and reward ~= nil and not view.Pending and prices[Config.DoubleOffline.ProductId] ~= nil
	for _, product in ipairs(Config.Packs) do
		local card = row[tostring(product.ProductId)]
		card.Amount.Text = "+" .. Presentation.Number(view.Offers[tostring(product.ProductId)] or 0)
		card.Purchase.Active = not busy and view.Ready and not view.Pending and prices[product.ProductId] ~= nil
	end
end
local function applyView(result)
	if not alive or not result.Offers or result.SessionToken ~= player:GetAttribute("ForgeSessionToken") then return false end
	view = result
	Feedback.ObserveStrength(result)
	paint()
	return true
end
local function refresh()
	if not alive or activeClaim then return end
	viewRevision += 1
	local version = viewRevision
	local result = request("View")
	if version == viewRevision and not activeClaim then applyView(result) end
end
local retryable = {Busy=true, DataSaving=true, InventorySavePending=true, Retry=true}
local function claim()
	if busy or not view or not view.Reward then return end
	local token = {RewardId=view.Reward.Id, Session=view.SessionToken}
	if token.Session ~= player:GetAttribute("ForgeSessionToken") then return end
	activeClaim=token; busy=true; viewRevision+=1; paint()
	local function current()
		return alive and activeClaim==token and token.Session==player:GetAttribute("ForgeSessionToken")
	end
	local failure = "Retry"
	local deadline = os.clock()+45
	for attempt=1,10 do
		if not current() or os.clock()>=deadline then break end
		-- A lost RemoteFunction response must not leave input locked forever.
		local result, completed
		task.spawn(function() result=request("Claim",token.RewardId,true,token.Session); completed=true end)
		local responseDeadline=math.min(deadline,os.clock()+10)
		repeat task.wait(.05) until completed or not current() or os.clock()>=responseDeadline
		if not current() then return end
		result=completed and result or {Ok=false,Code="Retry"}
		if result.Ok and result.View and applyView(result.View) then
			closed[token.RewardId]=true
			failure=nil
			break
		end
		failure=result.Code or "Retry"
		if not retryable[failure] then break end
		local untilTime=math.min(deadline,os.clock()+math.min(2,.5*2^(attempt-1)))
		repeat task.wait(.05) until not current() or os.clock()>=untilTime
	end
	if not current() then return end
	activeClaim=nil; busy=false; paint()
	if failure then Feedback.Denied(failure); task.defer(refresh) end
end
local function purchase(id)
	if busy or not view or view.Pending or not prices[id] then return end
	if id == Config.DoubleOffline.ProductId and not view.Reward then return end
	busy = true; paint()
	local result = request("Prepare", id)
	if result.Ok then
		if result.RewardId then panel.Amount.Text = "+" .. Format.Format(result.Amount) .. " STRENGTH"
		else row[tostring(id)].Amount.Text = "+" .. Presentation.Number(result.Amount) end
		-- The displayed amount is the persisted server quote before native checkout.
		request("Open", {ProductId = id, IntentId = result.IntentId})
	end
	busy = false; refresh()
end
panel.Close.Button.Activated:Connect(function() if view and view.Reward then closed[view.Reward.Id] = true end; panel.Visible = false end)
panel.Claim.Button.Activated:Connect(claim)
panel.Double.Button.Activated:Connect(function() purchase(Config.DoubleOffline.ProductId) end)
for _, product in ipairs(Config.Packs) do row[tostring(product.ProductId)].Purchase.Activated:Connect(function() purchase(product.ProductId) end) end
local function fetchPrice(product, button)
	if product.ProductId <= 0 then return end
	local ok, info = pcall(Marketplace.GetProductInfoAsync, Marketplace, product.ProductId, Enum.InfoType.Product)
	-- Client lookup uses the same player context as regional/personalized checkout.
	if ok and type(info) == "table" and info.IsForSale == true and type(info.PriceInRobux) == "number" then
		prices[product.ProductId] = info.PriceInRobux
		if product.ProductId == Config.DoubleOffline.ProductId then
			Presentation.OfflinePrice(panel, info.PriceInRobux)
		end
		-- Main pack cards are a single input; official price remains on native checkout.
		button:SetAttribute("PriceInRobux",info.PriceInRobux)
		paint()
	end
end
for _, product in ipairs(Config.Packs) do task.spawn(fetchPrice, product, row[tostring(product.ProductId)].Purchase) end
task.spawn(fetchPrice, Config.DoubleOffline, panel.Double.Price)
local sessionChanged = player:GetAttributeChangedSignal("ForgeSessionToken"):Connect(function()
	activeClaim=nil; busy=false; view=nil; viewRevision+=1
	panel.Visible=false; panel.Claim.Title.Text=claimTitle
	task.defer(refresh)
end)
local revision = player:GetAttributeChangedSignal("StrengthRewardRevision"):Connect(function() task.defer(refresh) end)
script.Destroying:Once(function() alive = false; activeClaim=nil; viewRevision+=1; sessionChanged:Disconnect(); revision:Disconnect(); clearHealth(); healthAdded:Disconnect(); healthRemoving:Disconnect() end)
task.spawn(function() while alive do refresh(); task.wait(2) end end)
