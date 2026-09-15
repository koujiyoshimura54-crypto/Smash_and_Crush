local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config:WaitForChild("SpeedConfig"))
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Pass=require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local M={}
function M.GetState(player)
 local s=Data.Get(player)
 local loaded=s~=nil and s.Loaded==true and s.Data~=nil
 local owned=loaded and s.Data.OwnedSpeeds.Speed1==true or false
 local premium=Pass.HasPremiumSpeed(player)
 local speed=premium and Pass.AreEffectsEnabled() and Config.Premium.WalkSpeed or (owned and Config.Speed1.WalkSpeed or Config.DefaultSpeed)
 return {Loaded=loaded,OwnedSpeeds={Speed1=owned},PremiumOwned=premium,WalkSpeed=speed,Win=player:GetAttribute("Win") or 0}
end
function M.Apply(player)
 local state=M.GetState(player)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid.WalkSpeed=state.WalkSpeed end
 return state
end
function M.Purchase(player,id)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if id~="Speed1" then return false,"InvalidRequest" end
 local ok,code=Data.PurchaseSpeed(player,id)
 if ok then M.Apply(player) end
 return ok,code
end
return M

