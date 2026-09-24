local MarketplaceController = {}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")
local UserService = game:GetService("UserService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage.Configuration
local PassesConfig   = require(Config.Passes)
local ProductsConfig = require(Config.Products)
local PacksConfig    = require(Config.Packs)

local Packets = require(ReplicatedStorage.Utils.Packets)
local Frames = require(script.Parent.UiController.Frames)
local ReplicationController = require(script.Parent.ReplicationController)
local NotificationController = require(script.Parent.NotificationController)
local GlobalSignals = require(script.Parent.Parent.Utils.GlobalSignals)

local CAMERA = workspace.CurrentCamera

local INFO_TYPE = {
	Pass = Enum.InfoType.GamePass,
	Product = Enum.InfoType.Product,
	Pack = Enum.InfoType.Product,
}

local PROMPT_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FOV_OPEN  = 50
local FOV_CLOSE = 70
local BLUR_SIZE = 40

local FullGui = Player.PlayerGui:WaitForChild("Full")
local MainGui = Player.PlayerGui:WaitForChild("Main")

local GiftPlayerChooseFrame = Frames.GiftPlayerChoose
local GiftConfirmFrame = Frames.GiftConfirm
local ScrollFrame = GiftPlayerChooseFrame.Main.Holder

local PlayerTemplate = ScrollFrame.Template
PlayerTemplate.Parent = nil

local GiftData = {
	GiftType   = "" :: "Pass" | "Product",
	GiftName   = "",
	GiftTarget = 0,
}

local priceCache = {
	Pass    = {} :: { [number]: number },
	Product = {} :: { [number]: number },
	Pack    = {} :: { [number]: number },
}

local function fetchPrice(id: number, itemType: "Pass" | "Product" | "Pack"): number?
	local cache = priceCache[itemType]
	if cache[id] then return cache[id] end

	local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, id, INFO_TYPE[itemType])
	if ok and info then
		cache[id] = info.PriceInRobux
		return info.PriceInRobux
	end
end

local function sanitizeUsername(text: string): string
	local parts = {}
	local underscoreUsed = false

	for i = 1, #text do
		local char = text:sub(i, i)
		if char:match("[%a%d]") then
			table.insert(parts, char)
		elseif char == "_" and not underscoreUsed then
			table.insert(parts, char)
			underscoreUsed = true
		end
	end

	return table.concat(parts)
end

local function resolvePlayerByName(rawUsername: string): { number | string }?
	local username = sanitizeUsername(rawUsername)

	local idOk, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
	if not idOk or not userId then return nil end

	local infoOk, infoList = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, { userId })
	if infoOk and infoList and infoList[1] then
		return { userId, username, infoList[1].DisplayName }
	end
end

local function iterPageItems(pages)
	return coroutine.wrap(function()
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(item)
			end
			if pages.IsFinished then break end
			pages:AdvanceToNextPageAsync()
		end
	end)
end

local function openPromptAnimation()
	FullGui.PromptUi.Visible = true
	MainGui.Enabled = false

	TweenService:Create(CAMERA, PROMPT_TWEEN_INFO, { FieldOfView = FOV_OPEN }):Play()

	local blur = game.Lighting:FindFirstChildOfClass("BlurEffect")
	if blur then
		blur.Enabled = true
		TweenService:Create(blur, PROMPT_TWEEN_INFO, { Size = BLUR_SIZE }):Play()
	end
end

local function closePromptAnimation()
	FullGui.PromptUi.Visible = false
	MainGui.Enabled = true

	TweenService:Create(CAMERA, PROMPT_TWEEN_INFO, { FieldOfView = FOV_CLOSE }):Play()

	local blur = game.Lighting:FindFirstChildOfClass("BlurEffect")
	if blur then
		local blurTween = TweenService:Create(blur, PROMPT_TWEEN_INFO, { Size = 0 })
		blurTween.Completed:Once(function()
			blur.Enabled = false
		end)
		blurTween:Play()
	end
end

local function onPlayerSelected(userId: number, username: string, displayName: string)
	GiftData.GiftTarget = userId

	if GiftData.GiftType == "Pass" then
		local ownsPass = Packets.Marketplace.CheckPassOwned:Fire(userId, GiftData.GiftName)
		if ownsPass then
			NotificationController:Prompt("Error", `{displayName} already owns this gamepass`)
			return
		end
	end

	GiftConfirmFrame.AreYouSureText.Text =
		`Are you sure you want to gift "{GiftData.GiftName}" to {username}?`

	GlobalSignals.UI.OpenFrame:Fire("GiftConfirm", false)
end

local function createPlayerFrame(userId: number, username: string, displayName: string, isFriend: boolean?)
	if ScrollFrame:FindFirstChild(tostring(userId)) then return end

	local frame = PlayerTemplate:Clone()
	frame.Name = tostring(userId)
	frame.DisplayUser.Text = displayName
	frame.MainUser.Text = username

	task.defer(function()
		frame.Icon.Image = Players:GetUserThumbnailAsync(
			userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180
		)
	end)

	frame.Confirm.MouseButton1Click:Connect(function()
		onPlayerSelected(userId, username, displayName)
	end)

	local inServer = Players:GetPlayerByUserId(userId) ~= nil
	if inServer and isFriend then
		frame.LayoutOrder = 1
	elseif inServer then
		frame.LayoutOrder = 2
	elseif isFriend then
		frame.LayoutOrder = 3
	end

	if isFriend then
		frame:SetAttribute("Friend", true)
	end

	frame.Parent = ScrollFrame
end

function MarketplaceController:GetPrice(itemType: "Pass" | "Product" | "Pack", itemName: string): number?
	local id = (PassesConfig[itemName] and PassesConfig[itemName].PassID)
		or (ProductsConfig[itemName] and ProductsConfig[itemName].ProductID)
		or (PacksConfig[itemName] and PacksConfig[itemName].ProductID)

	if not id then
		warn(`MarketplaceController:GetPrice — unknown item "{itemName}"`)
		return nil
	end

	return fetchPrice(id, itemType)
end

function MarketplaceController:IsPassOwned(passName: string): boolean
	local data = ReplicationController.Subscribe(`{Player.UserId}_Passes`)
	if data[passName] then return true end
end

function MarketplaceController:IsPackOwned(packName: string): boolean
	local data = ReplicationController.Subscribe(`{Player.UserId}_Packs`)
	return table.find(data, packName) ~= nil
end

function MarketplaceController:StartPassPrompt(passName: string)
	local passId = PassesConfig[passName].PassID
	MarketplaceService:PromptGamePassPurchase(Player, passId)
	openPromptAnimation()
end

function MarketplaceController:SetPassButton(button: GuiButton, passName: string)
	local passId = PassesConfig[passName].PassID

	button.MouseButton1Click:Connect(function()
		self:StartPassPrompt(passName)
	end)

	local function applyOwnedState()
		button.Visible = false
		button.Parent.Owned.Visible = true
	end

	if self:IsPassOwned(passName) then
		applyOwnedState()
		return
	end

	ReplicationController.GetSignal(`{Player.UserId}_Passes`):Connect(function(updated)
		if updated[passName] then
			applyOwnedState()
		end
	end)
end

function MarketplaceController:StartProductPrompt(productName: string)
	local productId = ProductsConfig[productName].ProductID
	MarketplaceService:PromptProductPurchase(Player, productId)
	openPromptAnimation()
end

function MarketplaceController:SetProductButton(button: GuiButton, productName: string)
	button.MouseButton1Click:Connect(function()
		self:StartProductPrompt(productName)
	end)
end

function MarketplaceController:StartPackPrompt(packName: string)
	local packId = PacksConfig[packName].ProductID
	MarketplaceService:PromptProductPurchase(Player, packId)
	openPromptAnimation()
end

function MarketplaceController:SetPackButton(button: GuiButton, packName: string)
	local productId = PacksConfig[packName].ProductID

	button.MouseButton1Click:Connect(function()
		self:StartPackPrompt(packName)
	end)

	local function applyOwnedState()
		button.Visible = false
		button.Parent.Owned.Visible = true
	end

	if self:IsPackOwned(packName) then
		applyOwnedState()
		return
	end

	ReplicationController.GetSignal(`{Player.UserId}_Packs`):Connect(function(updated)
		if table.find(updated, packName) then
			applyOwnedState()
		end
	end)
end

function MarketplaceController:SetPassGiftButton(button: GuiButton, passName: string)
	button.MouseButton1Click:Connect(function()
		GiftData.GiftType = "Pass"
		GiftData.GiftName = passName
		ScrollFrame.HeadngText.Text = `- Gift "{passName}" To -`
		GlobalSignals.UI.OpenFrame:Fire("GiftPlayerChoose")
	end)
end

function MarketplaceController:SetProductGiftButton(button: GuiButton, productName: string)
	button.MouseButton1Click:Connect(function()
		GiftData.GiftType = "Product"
		GiftData.GiftName = productName
		ScrollFrame.HeadngText.Text = `- Gift "{productName}" To -`
		GlobalSignals.UI.OpenFrame:Fire("GiftPlayerChoose")
	end)
end

function MarketplaceController:start()
	GiftPlayerChooseFrame.Confirm.MouseButton1Click:Connect(function()
		local info = resolvePlayerByName(GiftPlayerChooseFrame.UserSearch.Text)
		if info then
			onPlayerSelected(info[1], info[2], info[3])
		end
	end)

	GiftPlayerChooseFrame.Top.Close.MouseButton1Click:Connect(function()
		GlobalSignals.UI.OpenFrame:Fire("Shop")
	end)

	for item in iterPageItems(Players:GetFriendsAsync(Player.UserId)) do
		createPlayerFrame(item.Id, item.Username, item.DisplayName, true)
	end

	for _, player in Players:GetPlayers() do
		if player ~= Player then
			createPlayerFrame(player.UserId, player.Name, player.DisplayName, false)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		createPlayerFrame(player.UserId, player.Name, player.DisplayName, false)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local entry = ScrollFrame:FindFirstChild(tostring(player.UserId))
		if not entry then return end

		if entry:GetAttribute("Friend") then
			entry.LayoutOrder = 3
		else
			entry:Destroy()
		end
	end)

	GiftConfirmFrame.Yes.MouseButton1Click:Connect(function()
		Packets.Marketplace.StartGifting:Fire(GiftData.GiftTarget, GiftData.GiftType, GiftData.GiftName)
		MarketplaceService.PromptProductPurchaseFinished:Once(function(_, _, purchased)
			if purchased then
				GlobalSignals.UI.CloseFrame:Fire(true)
			end
		end)
	end)

	Packets.Marketplace.PromptStart.OnClientEvent:Connect(openPromptAnimation)
	MarketplaceService.PromptProductPurchaseFinished:Connect(closePromptAnimation)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(closePromptAnimation)

	TweenService:Create(
		FullGui.PromptUi.Grad.UIGradient,
		TweenInfo.new(10, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, -1, true, 0),
		{ Rotation = 359 }
	):Play()
end

return MarketplaceController