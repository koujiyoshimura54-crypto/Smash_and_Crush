-- Read-only reference for both offline rewards and paid packs. No attribute edits,
-- grants, Marketplace requests or temporary potion effects occur here.
local RS = game:GetService("ReplicatedStorage")
local Data = require(script.Parent.PlayerDataService)
local Dumbbell = require(script.Parent.DumbbellService)
local Aura = require(script.Parent.AuraService)
local Item = require(script.Parent.ItemService)
local Pass = require(script.Parent.GamePassService)
local Pet = require(script.Parent.PetServer)
local Rebirth = require(RS.Config.RebirthConfig)
local Training = require(RS.Config.TrainingConfig)
local Treadmill = require(RS.Config.TreadmillConfig)
local Calculation = require(RS.Modules.StrengthCalculation)
local Potion = require(script.Parent.PotionService)
local M = {}
function M.Calculate(components, candidates, itemEffects)
	local best, selected = 0, nil
	for _, candidate in ipairs(candidates) do
		if candidate.Accessible then
			local c = components[candidate.World]
			if c then
				-- Candidate effects replace only Item inputs in the fixed snapshot.
				local inputs=table.clone(c)
				if itemEffects then inputs.Protein=itemEffects.Protein;inputs.Belt=itemEffects.TrainingBelt end
				local rate = Calculation.Gain(Training.BaseGain,1,inputs,
					candidate.Multiplier+inputs.Belt+(inputs.TrainingBonus or 0))/Training.TrainingInterval
				if rate > best and rate < math.huge then best, selected = rate, candidate end
			end
		end
	end
	return best, selected
end
function M.GetContext(player, includePotions)
	local session = Data.Get(player)
	if not session or not session.Loaded or session.OwnershipLost then return nil, "DataNotLoaded" end
	local d = session.Data
	local components, candidates = {}, {}
	local effects=Item.GetEffectiveEffects(player)
	local map = workspace:FindFirstChild("World2Map")
	local area = map and map:FindFirstChild("TrainingArea")
	local folders = {[1] = workspace:FindFirstChild("Treadmills"), [2] = area and area:FindFirstChild("TreadmillDisplays")}
	for world = 1, 2 do
		-- Use durable arrival history, even after returning to World1. Studio's
		-- temporary purchase-preview lock must not rewrite actual arrival history.
		if world == 1 or (d.World2Visited == true and d.HighestUnlockedWorld >= 2) then
			-- Current authoritative equipment effects are cross-world: item WorldId
			-- selects its own bonus table; CurrentWorld is not an effect input.
			components[world] = {Dumbbell = Dumbbell.GetStrengthBonus(player), Aura = Aura.GetStrengthBonus(player),
				Protein = effects.Protein, Belt = effects.TrainingBelt,
				Rebirth = Rebirth.GetMultiplier(d.RebirthCount), VIP = Pass.GetVIPStrengthMultiplier(player),
				Pet = Pet.GetStrengthMultiplier(player),
				StrengthPotion=includePotions and Potion.GetStrengthMultiplier(player) or 1,
				TrainingBonus=includePotions and Potion.GetTrainingBonus(player) or 0}
			for _, model in ipairs(folders[world] and folders[world]:GetChildren() or {}) do
				local config = Treadmill.GetForModel(model)
				if config then
					local accessible = d.RebirthCount >= (config.RequiredRebirth or 0)
					if config.RequiresPremium then accessible = accessible and Pass.AreEffectsEnabled(player) and Pass.HasPremiumTreadmill(player, world) end
					table.insert(candidates, {World = world, Name = model.Name, Multiplier = config.Multiplier, Accessible = accessible})
				end
			end
		end
	end
	return components,candidates
end
function M.Get(player)
	local components,candidates=M.GetContext(player,false)
	if not components then return nil,candidates end
	return M.Calculate(components,candidates)
end
return M
