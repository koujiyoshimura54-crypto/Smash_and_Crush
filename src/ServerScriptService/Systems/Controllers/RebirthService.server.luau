local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Strength=require(game.ServerScriptService.Services:WaitForChild("StrengthManager"))

local PlayerData=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))local Config=require(RS.Config:WaitForChild("RebirthConfig"))
local Badges=require(game.ServerScriptService.Services:WaitForChild("BadgeAwardService"))
local request=RS.Remotes:WaitForChild("RebirthRequest")
local busy=setmetatable({}, {__mode="k"})
local function setup(player)
 if typeof(player:GetAttribute("RebirthCount"))~="number" then player:SetAttribute("RebirthCount",0) end
end
local function response(player,data) request:FireClient(player,data) end
request.OnServerEvent:Connect(function(player,action)
 if action~="Request" or busy[player] then return end
 busy[player]=true
 local session=PlayerData.Get(player)
 if not PlayerData.IsLoaded(player) or PlayerData.IsSaving(player) or (session and (session.PendingItemMutation or session.OwnershipLost)) then
  response(player,{Type="Denied",Reason="DataNotReady"})
  busy[player]=nil return
 end
 local count=session.Data.RebirthCount
 local curve=session.Data.LevelCurveVersion
 if Config.IsWorld1Max(count,curve) then
  response(player,{Type="Denied",Reason="World1Max",RebirthCount=count})
  busy[player]=nil return
 end
 local required=Config.GetRequiredLevel(count,curve)
 local level=session.Data.Level
 if required and level>=required then
  local accepted,nextCount=PlayerData.TryRebirth(player)
  if not accepted then response(player,{Type="Denied",Reason=nextCount});busy[player]=nil;return end
  if count==0 and nextCount==1 then Badges.Award(player,"FirstRebirth") end
  Strength.ResetGainRemainder(player)
  response(player,{Type="Success",RebirthCount=nextCount,RequiredLevel=Config.GetRequiredLevel(nextCount,session.Data.LevelCurveVersion),Level=1})
 else
  response(player,{Type="Denied",RebirthCount=count,RequiredLevel=required,Level=level})
 end
 busy[player]=nil
end)
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player) busy[player]=nil end)
for _,player in Players:GetPlayers() do setup(player) end
