local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config:WaitForChild("SpeedConfig"))
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Pass=require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local M={}
local TRANSITION_BOOST_MULTIPLIER=2
local boosts={}
local bindings={}
local function activeBoost(player)
 local boost=boosts[player]
 local character=player.Character
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 if boost and boost.Character==character and boost.WorldId==(player:GetAttribute("CurrentWorld") or 1)
  and hum and hum.Health>0 then return boost end
 return nil
end
function M.GetState(player)
 local s=Data.Get(player)
 local loaded=s~=nil and s.Loaded==true and s.Data~=nil
 local owned=loaded and s.Data.OwnedSpeeds.Speed1==true or false
 local premium=Pass.HasPremiumSpeed(player)
 local activeId=premium and Pass.AreEffectsEnabled(player) and "Premium" or (owned and "Speed1" or "NONE")
 local speed=activeId=="NONE" and Config.DefaultSpeed or Config[activeId].WalkSpeed
 return {Loaded=loaded,OwnedSpeeds={Speed1=owned},PremiumOwned=premium,ActiveSpeedItemId=activeId,WalkSpeed=speed,Win=player:GetAttribute("Win") or 0}
end
-- Equipment/source identity is independent of applied WalkSpeed and transition boosts.
function M.GetActiveSpeedItemId(player)
 return M.GetState(player).ActiveSpeedItemId
end
function M.Apply(player)
 local state=M.GetState(player)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid.WalkSpeed=state.WalkSpeed*(activeBoost(player) and TRANSITION_BOOST_MULTIPLIER or 1) end
 return state
end
function M.ClearTransitionBoost(player,worldId)
 local boost=boosts[player]
 if not boost or (worldId and boost.WorldId~=worldId) then return end
 boosts[player]=nil
 M.Apply(player)
end
function M.BeginTransitionBoost(player,worldId,defeatedStage)
 if (worldId~=1 and worldId~=2) or (player:GetAttribute("CurrentWorld") or 1)~=worldId then return end
 M.ClearTransitionBoost(player)
 if defeatedStage<1 or defeatedStage>=10 then return end
 local character=player.Character
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 then return end
 boosts[player]={Active=true,WorldId=worldId,DefeatedStage=defeatedStage,TargetStage=defeatedStage+1,Character=character}
 M.Apply(player)
end
function M.OnWallCombatContact(player,worldId,stage,index)
 local boost=activeBoost(player)
 if boost and boost.WorldId==worldId and boost.TargetStage==stage and index==1 then
  M.ClearTransitionBoost(player,worldId)
 end
end
function M.GetTransitionBoost(player)
 local boost=activeBoost(player)
 return boost and table.clone(boost) or nil
end
function M.Purchase(player,id)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if id~="Speed1" then return false,"InvalidRequest" end
 local ok,code=Data.PurchaseSpeed(player,id)
 if ok then M.Apply(player) end
 return ok,code
end
local function bind(player)
 local connections={}
 bindings[player]=connections
 local deathConnection
 local function characterAdded(character)
  M.ClearTransitionBoost(player)
  if deathConnection then deathConnection:Disconnect();deathConnection=nil end
  task.spawn(function()
   local hum=character:WaitForChild("Humanoid",10)
   if hum and player.Character==character and player.Parent==Players then
    deathConnection=hum.Died:Connect(function() M.ClearTransitionBoost(player) end)
   end
  end)
 end
 connections[#connections+1]=player.CharacterAdded:Connect(characterAdded)
 connections[#connections+1]=player.CharacterRemoving:Connect(function() M.ClearTransitionBoost(player) end)
 connections[#connections+1]=player:GetAttributeChangedSignal("CurrentWorld"):Connect(function() M.ClearTransitionBoost(player) end)
 connections[#connections+1]={Disconnect=function() if deathConnection then deathConnection:Disconnect() end end}
 if player.Character then characterAdded(player.Character) end
end
Players.PlayerAdded:Connect(bind)
for _,player in Players:GetPlayers() do bind(player) end
Players.PlayerRemoving:Connect(function(player)
 boosts[player]=nil
 for _,connection in bindings[player] or {} do connection:Disconnect() end
 bindings[player]=nil
end)
return M
