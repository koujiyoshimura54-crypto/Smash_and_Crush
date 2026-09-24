local Players = game:GetService("Players")

local PlayerData=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local DumbbellService=require(game.ServerScriptService.Services:WaitForChild("DumbbellService"))
local ItemService=require(game.ServerScriptService.Services:WaitForChild("ItemService"))
local AuraService=require(game.ServerScriptService.Services:WaitForChild("AuraService"))
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local LevelRequirements=require(ReplicatedStorage.Config:WaitForChild("LevelRequirements"))
local RebirthMultiplierConfig=require(ReplicatedStorage.Config:WaitForChild("RebirthMultiplierConfig"))
local PotionService=require(game.ServerScriptService.Services:WaitForChild("PotionService"))
local ShopPasses=require(game.ServerScriptService.Services.GamePassService)
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

-- Archived test compatibility only; live Level never derives from Strength.
function StrengthManager.CalculateLevel(strength)
 return LevelRequirements.CalculateLevel(strength)
end
function StrengthManager.GetLevel(player)
 local level=PlayerData.GetLevelState(player)
 return level or 1
end
function StrengthManager.UpdateLevel(player)
 local level,progress=PlayerData.GetLevelState(player)
 if not level then return 1 end
 player:SetAttribute("LevelProgress",progress)
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

	-- Absolute administrative assignment grants no LevelProgress.
 if not PlayerData.SetCurrentStrength(player,sanitized) then return nil,"DataNotLoaded" end
 StrengthManager.UpdateLevel(player)
 return sanitized
end

function StrengthManager.GetRebirthCount(player)
 local value=player:GetAttribute("RebirthCount")
 return typeof(value)=="number" and math.max(0,math.floor(value)) or 0
end
function StrengthManager.GetStrengthGainMultiplier(player)
 return RebirthMultiplierConfig.GetMultiplier(StrengthManager.GetRebirthCount(player))
end
function StrengthManager.ResetGainRemainder(player)
 gainRemainder[player]=0
end
function StrengthManager.GetGainRemainder(player)
 return gainRemainder[player] or 0
end
-- Already-calculated rewards bypass ALL equipment, treadmill and potion multipliers.
local function commitGain(player,gain)
 if not isFiniteNumber(gain) then return nil, "combined gain must be a finite number" end
 gainRemainder[player]=0
 if gain<=0 then
  StrengthManager.UpdateLevel(player)
  return StrengthManager.GetStrength(player)
 end
 local before=StrengthManager.GetStrength(player)
 local result,reason=PlayerData.AddStrengthGain(player,gain)
 if result==nil then return nil,reason end
 -- Presentation only: report the actual committed delta, never recalculate multipliers on clients.
 if typeof(result)=="number" and result>before and player.Parent==Players then
  game:GetService("ReplicatedStorage").Remotes.StrengthGain:FireClient(player,result-before)
 end
 return result
end

function StrengthManager.AddRewardStrength(player,amount)
 local valid,message=validatePlayer(player)
 if not valid then return nil,message end
 if not isFiniteNumber(amount) or amount<=0 then return nil,"Invalid reward amount" end
 return commitGain(player,amount)
end
-- Normal equipment reference, independent of current location/treadmill/potions/Belt.
function StrengthManager.GetNormalTrainingGain(player,baseGain)
 local valid,message=validatePlayer(player)
 if not valid then return nil,message end
 if not isFiniteNumber(baseGain) or baseGain<=0 then return nil,"Invalid normal base" end
 local base=baseGain+DumbbellService.GetStrengthBonus(player)+AuraService.GetStrengthBonus(player)+ItemService.GetProteinBonus(player)
 return base*StrengthManager.GetStrengthGainMultiplier(player)
end

-- tickCount preserves per-tick bonuses when walking batches elapsed ticks.
function StrengthManager.AddStrength(player, amount, tickCount, sourceMultiplier)
 local valid, message=validatePlayer(player)
 if not valid then return nil, message end
 if not isFiniteNumber(amount) then return nil, "amount must be a finite number" end
 tickCount=tickCount or 1
 if not isFiniteNumber(tickCount) or tickCount<1 or tickCount%1~=0 then return nil, "tickCount must be a positive integer" end
 -- V5: Dumbbell contributes to training; walking uses Base + Aura + Protein.
 local bonus=sourceMultiplier~=nil and DumbbellService.GetStrengthBonus(player) or 0
 local proteinBonus=ItemService.GetProteinBonus(player)
 local auraBonus=AuraService.GetStrengthBonus(player)
 local baseWithBonuses=amount>0 and (amount+(bonus+auraBonus+proteinBonus)*tickCount) or amount
 -- Only the server training caller supplies this multiplier; walking defaults to 1.
 sourceMultiplier=sourceMultiplier or 1
 if not isFiniteNumber(sourceMultiplier) or sourceMultiplier<=0 then return nil, "sourceMultiplier must be positive and finite" end
 local gain=baseWithBonuses*StrengthManager.GetStrengthGainMultiplier(player)*sourceMultiplier*PotionService.GetStrengthMultiplier(player)*ShopPasses.GetVIPStrengthMultiplier(player)*ItemService.GetElementSetMultiplier(player)
 return commitGain(player,gain)
end

function StrengthManager.ResetStrength(player)
	local ok,reason=PlayerData.ResetStrengthProgress(player)
 if not ok then return nil,reason end
 StrengthManager.ResetGainRemainder(player)
 return DEFAULT_STRENGTH
end

function StrengthManager.InitializeExistingPlayers()
	for _, player in Players:GetPlayers() do
		StrengthManager.InitializePlayer(player)
	end
end

return StrengthManager


