local PromotionController = {}
local Player = game:GetService("Players").LocalPlayer
local Ui = Player.PlayerGui:WaitForChild("Main").HUD.Right
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceController = require(script.Parent.MarketplaceController)
local Confg = ReplicatedStorage.Configuration
local PromotionConfg = require(Confg.Promotion)
local ProductsConfg = require(Confg.Products)
local PassesConfg = require(Confg.Passes)
local Packs = require(Confg.Packs)

local Items = {
	[1] = Ui.SideItem1,
	[2] = Ui.SideItem2,
	[3] = Ui.SideItem3
}

local function FillItemData(item: GuiButton, name: string, icon: number, price: number)
	local container = item.Container
	container.Icon.Image = "rbxassetid://" .. icon
	container.Price.Text = "" .. price
	container.Title.Text = name
end

local ActivePromotions = {
	[1] = {Type = "", Name = ""},
	[2] = {Type = "", Name = ""},
	[3] = {Type = "", Name = ""},
}

local function TweenIn()
	local tweenInfo = TweenInfo.new(.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local target = {AnchorPoint = Vector2.new(0, .5)}
	for i, item in Items do
		local tween = TweenService:Create(item.Container, tweenInfo, target)
		tween:Play()
		if i == #Items then
			tween.Completed:Wait()
		end
		task.wait(.2)
	end
end

local function TweenOut()
	local tweenInfo = TweenInfo.new(.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local target = {AnchorPoint = Vector2.new(1, .5)}
	for i, item in Items do
		local tween = TweenService:Create(item.Container, tweenInfo, target)
		tween:Play()
		task.wait(.2)
	end
end

local function PickRandom(pool: {any}, count: number, previousKeys: {[string]: boolean}): {any}
	local preferred = {}
	local fallback = {}

	for _, entry in pool do
		if previousKeys[entry.Name] then
			table.insert(fallback, entry)
		else
			table.insert(preferred, entry)
		end
	end

	local function shuffle(t)
		for i = #t, 2, -1 do
			local j = math.random(i)
			t[i], t[j] = t[j], t[i]
		end
	end

	shuffle(preferred)
	shuffle(fallback)

	local combined = {}
	for _, v in preferred do table.insert(combined, v) end
	for _, v in fallback do table.insert(combined, v) end

	local result = {}
	for i = 1, math.min(count, #combined) do
		table.insert(result, combined[i])
	end
	return result
end

local function RefreshPromotion()
	local previousKeys = {}
	for _, info in ActivePromotions do
		if info.Name ~= "" then
			previousKeys[info.Name] = true
		end
	end

	local pool = {}

	for packName, iconID in PromotionConfg.Packs do
		if MarketplaceController:IsPackOwned(packName) then continue end
		local price = MarketplaceController:GetPrice("Pack", packName)
		table.insert(pool, {Type = "Pack", Name = packName, Icon = iconID, Price = price})
	end

	for passName, iconID in PromotionConfg.Passes do
		if MarketplaceController:IsPassOwned(passName) then continue end
		local price = MarketplaceController:GetPrice("Pass", passName)
		table.insert(pool, {Type = "Pass", Name = passName, Icon = iconID, Price = price})
	end

	for productName, iconID in PromotionConfg.Products do
		local price = MarketplaceController:GetPrice("Product", productName)
		table.insert(pool, {Type = "Product", Name = productName, Icon = iconID, Price = price})
	end

	local picked = PickRandom(pool, 3, previousKeys)

	for i = 1, 3 do
		local item = Items[i]
		local entry = picked[i]

		if entry then
			ActivePromotions[i] = {Type = entry.Type, Name = entry.Name}
			FillItemData(item, entry.Name, entry.Icon, entry.Price)
			item.Visible = true
		else
			ActivePromotions[i] = {Type = "", Name = ""}
			item.Visible = false
		end
	end
end

function PromotionController:start()
	for i, item in Items do
		item.MouseButton1Click:Connect(function()
			local info = ActivePromotions[i]
			if info.Type == "Product" then
				MarketplaceController:StartProductPrompt(info.Name)
			elseif info.Type == "Pack" then
				MarketplaceController:StartPackPrompt(info.Name)
			elseif info.Type == "Pass" then
				MarketplaceController:StartPassPrompt(info.Name)
			end
		end)
	end

	while true do
		TweenIn()
		RefreshPromotion()
		TweenOut()
		task.wait(15)
	end
end

return PromotionController