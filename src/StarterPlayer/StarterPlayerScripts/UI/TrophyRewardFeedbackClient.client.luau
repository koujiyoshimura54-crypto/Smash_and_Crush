local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local sounds = require(ReplicatedStorage.Config:WaitForChild("UISoundConfig"))
local format = require(ReplicatedStorage.Modules:WaitForChild("NumberFormat"))
local winLabel = player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui"):WaitForChild("WinLabel")
local amountLabel = winLabel:WaitForChild("Amount")
amountLabel.AutoLocalize = false

local scale = winLabel:FindFirstChild("RewardFeedbackScale")
if not scale then
	scale = Instance.new("UIScale")
	scale.Name = "RewardFeedbackScale"
	scale.Scale = 1
	scale.Parent = winLabel
end

local sound = SoundService:FindFirstChild("CoinCollectFeedback")
if not sound then
	sound = Instance.new("Sound")
	sound.Name = "CoinCollectFeedback"
	sound.Parent = SoundService
end
sound.SoundId = sounds.CoinCollect.SoundId
sound.Volume = sounds.CoinCollect.Volume
sound.PlaybackSpeed = sounds.CoinCollect.PlaybackSpeed

local generation = 0
local activeTween
local baseRotation = winLabel.Rotation

local function resetVisual()
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	scale.Scale = 1
	winLabel.Rotation = baseRotation
end

local function tween(token,target,duration,properties)
	if token ~= generation then return false end
	local value = TweenService:Create(target,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
	activeTween = value
	value:Play()
	value.Completed:Wait()
	value:Destroy()
	if activeTween == value then activeTween = nil end
	return token == generation
end

local function animateReward(expectedWin)
	generation += 1
	local token = generation
	resetVisual()
	amountLabel.Text = format.Format(expectedWin)
	sound:Stop()
	sound.TimePosition = 0
	sound:Play()
	task.spawn(function()
		if not tween(token,scale,.10,{Scale=1.17}) then return end
		if not tween(token,winLabel,.07,{Rotation=baseRotation-4}) then return end
		if not tween(token,winLabel,.07,{Rotation=baseRotation+4}) then return end
		if not tween(token,winLabel,.07,{Rotation=baseRotation-3}) then return end
		if not tween(token,winLabel,.07,{Rotation=baseRotation+2}) then return end
		if not tween(token,scale,.12,{Scale=1}) then return end
		if token == generation then winLabel.Rotation=baseRotation end
	end)
end

remote.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" or data.Type ~= "TrophyCollected" or typeof(data.Win) ~= "number" then return end
	local expectedWin = data.Win
	task.spawn(function()
		for _=1,30 do
			if player:GetAttribute("Win") == expectedWin then
				animateReward(expectedWin)
				return
			end
			task.wait()
		end
	end)
end)

script.Destroying:Connect(function()
	generation += 1
	resetVisual()
	sound:Stop()
end)
