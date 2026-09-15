local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Strength=require(game.ServerScriptService.Services:WaitForChild("StrengthManager"))

local PlayerData=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))local Config=require(RS.Config:WaitForChild("RebirthConfig"))
local request=RS.Remotes:WaitForChild("RebirthRequest")
local busy=setmetatable({}, {__mode="k"})
local function setup(player)
 if typeof(player:GetAttribute("RebirthCount"))~="number" then player:SetAttribute("RebirthCount",0) end
end
local function response(player,data) request:FireClient(player,data) end
request.OnServerEvent:Connect(function(player,action)
 if action~="Request" or busy[player] then return end
 busy[player]=true
 if not PlayerData.IsLoaded(player) or PlayerData.IsSaving(player) then
  response(player,{Type="Denied",Reason="DataNotReady"})
  busy[player]=nil return
 end
 local count=Strength.GetRebirthCount(player)
 if Config.IsWorld1Max(count) then
  response(player,{Type="Denied",Reason="World1Max",RebirthCount=count})
  busy[player]=nil return
 end
 local required=Config.GetRequiredLevel(count)
 local level=Strength.GetLevel(player)
 if required and level>=required then
  local nextCount=count+1
  PlayerData.SetRebirthCount(player,nextCount)
  Strength.ResetGainRemainder(player)
  Strength.ResetStrength(player)
  response(player,{Type="Success",RebirthCount=nextCount,RequiredLevel=Config.GetRequiredLevel(nextCount),Level=1})
 else
  response(player,{Type="Denied",RebirthCount=count,RequiredLevel=required,Level=level})
 end
 busy[player]=nil
end)
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player) busy[player]=nil end)
for _,player in Players:GetPlayers() do setup(player) end

