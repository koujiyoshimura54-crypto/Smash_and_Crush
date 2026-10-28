local p=game.Players:GetPlayers()[1]
local S=game.ServerScriptService.Services
local Items=require(S.ItemService);local Bells=require(S.DumbbellService);local Aura=require(S.AuraService);local Strength=require(S.StrengthManager)
local b=Instance.new('BindableFunction');b.Name='__BalanceFactors';b.Parent=game.ServerScriptService
b.OnInvoke=function()return {Set=Items.GetElementSetMultiplier(p),Protein=Items.GetProteinBonus(p),Glove=Items.GetGloveBossDamageBonus(p),Belt=Items.GetBeltTreadmillBonus(p),Dumbbell=Bells.GetStrengthBonus(p),Aura=Aura.GetStrengthBonus(p),NormalGain=Strength.GetNormalTrainingGain(p,1)}end
