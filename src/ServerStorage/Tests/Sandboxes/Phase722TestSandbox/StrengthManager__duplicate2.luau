local engineTypeof=typeof
local function typeof(v) if type(v)=="table" and v.IsTestPlayer then return "Instance" end return engineTypeof(v) end
local Players = require(script.Parent.Runtime).Players

local PlayerData=require(script.Parent:WaitForChild("PlayerDataService"))
local DumbbellService=require(script.Parent:WaitForChild("DumbbellService"))
local TrainingLobbyAreaService=require(script.Parent:WaitForChild("TrainingLobbyAreaService"))
local ItemService=require(script.Parent:WaitForChild("ItemService"))
local LevelRequirements=require(game:GetService("ReplicatedStorage").Config:WaitForChild("LevelRequirements"))
local LevelRequirements=require(game:GetService("ReplicatedStorage").Config:WaitForChild("LevelRequirements"))
local StrengthManager = {}

local ATTRIBUTE_NAME = "Strength"
local DEFAULT_STRENGTH = 0

local gainRemainder=setmetatable({}, {__mode="k"})

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function validatePlayer(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "player must be a Player instance"
	end
	return true
end

local function sanitizeStrength(value)
	if not isFiniteNumber(value) then
		return nil, "Strength must be a finite number"
	end
	return math.max(0, value)
end

function StrengthManager.InitializePlayer(player)
	local valid, message = validatePlayer(player)
	if not valid then
		return nil, message
	end

	local existing = player:GetAttribute(ATTRIBUTE_NAME)
	if existing == nil then
		player:SetAttribute(ATTRIBUTE_NAME, DEFAULT_STRENGTH)
		return DEFAULT_STRENGTH
	end

	local sanitized = sanitizeStrength(existing)
	if sanitized == nil then
		player:SetAttribute(ATTRIBUTE_NAME, DEFAULT_STRENGTH)
		return DEFAULT_STRENGTH
	end

	if sanitized ~= existing then
		player:SetAttribute(ATTRIBUTE_NAME, sanitized)
	end
	return sanitized
end

function StrengthManager.GetStrength(player)
	local valid, message = validatePlayer(player)
	if not valid then
		return nil, message
	end

	local value = player:GetAttribute(ATTRIBUTE_NAME)
	local sanitized = sanitizeStrength(value)
	if sanitized == nil then
		return StrengthManager.InitializePlayer(player)
	end
	if sanitized ~= value then
		player:SetAttribute(ATTRIBUTE_NAME, sanitized)
	end
	return sanitized
end

function StrengthManager.CalculateLevel(strength)
 return LevelRequirements.CalculateLevel(strength)
end
function StrengthManager.UpdateLevel(player,strength)
 local level=StrengthManager.CalculateLevel(strength or StrengthManager.GetStrength(player))
 player:SetAttribute("Level",level)
 return level
end

function StrengthManager.SetStrength(player, value)
	local valid, message = validatePlayer(player)
	if not valid then
		return nil, message
	end

	local sanitized, valueError = sanitizeStrength(value)
	if sanitized == nil then
		return nil, valueError
	end

	player:SetAttribute(ATTRIBUTE_NAME, sanitized)
	StrengthManager.UpdateLevel(player, sanitized)
	PlayerData.SetCurrentStrength(player, sanitized)
	return sanitized
end

function StrengthManager.GetRebirthCount(player)
 local value=player:GetAttribute("RebirthCount")
 return typeof(value)=="number" and math.max(0,math.floor(value)) or 0
end
function StrengthManager.GetStrengthGainMultiplier(player)
 return 1+StrengthManager.GetRebirthCount(player)*0.20
end
-- Keep GetStrengthGainMultiplier as the existing Rebirth-only API.
function StrengthManager.GetTotalStrengthGainMultiplier(player)
 local dumbbellMultiplier=TrainingLobbyAreaService.IsInTrainingLobby(player)
  and DumbbellService.GetStrengthMultiplier(player) or 1
 return StrengthManager.GetStrengthGainMultiplier(player)*dumbbellMultiplier*ItemService.GetItemStrengthMultiplier(player)
end
function StrengthManager.ResetGainRemainder(player)
 gainRemainder[player]=0
end
function StrengthManager.GetGainRemainder(player)
 return gainRemainder[player] or 0
end
function StrengthManager.AddStrength(player, amount)
 local valid, message=validatePlayer(player)
 if not valid then return nil, message end
 if not isFiniteNumber(amount) then return nil, "amount must be a finite number" end
 local total=amount*StrengthManager.GetTotalStrengthGainMultiplier(player)+(gainRemainder[player] or 0)
 if not isFiniteNumber(total) then return nil, "combined gain must be a finite number" end
 local whole=math.floor(total+1e-9)
 gainRemainder[player]=total-whole
 if math.abs(gainRemainder[player])<1e-9 then gainRemainder[player]=0 end
 if whole<=0 then
  StrengthManager.UpdateLevel(player,StrengthManager.GetStrength(player))
  return StrengthManager.GetStrength(player)
 end
 local result=StrengthManager.SetStrength(player,StrengthManager.GetStrength(player)+whole)
 PlayerData.RecordStrengthGain(player,whole)
 return result
end

function StrengthManager.ResetStrength(player)
	return StrengthManager.SetStrength(player, DEFAULT_STRENGTH)
end

function StrengthManager.InitializeExistingPlayers()
	for _, player in Players:GetPlayers() do
		StrengthManager.InitializePlayer(player)
	end
end

return StrengthManager
