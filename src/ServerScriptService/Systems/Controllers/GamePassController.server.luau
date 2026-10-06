local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Pass=require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local remote=RS.Remotes:WaitForChild("World1DoubleWinPrompt")
local function refreshOwnership(player)
 while player.Parent==Players do
  local _,status=Pass.Refresh(player)
  if status=="Verified" or status=="UnavailableWorld" then return end
  task.wait(15)
 end
end
Players.PlayerAdded:Connect(function(player) task.spawn(refreshOwnership,player) end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(refreshOwnership,player) end
remote.OnServerEvent:Connect(function(player,action)
 if action~="Prompt" and action~="TrophyPrompt" then return end
 if action=="TrophyPrompt" then
  local trophy=workspace:FindFirstChild("Trophy")
  local buy=trophy and trophy:FindFirstChild("Buy")
  local prompt=buy and buy:FindFirstChildWhichIsA("ProximityPrompt")
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not buy or not buy:IsA("BasePart") or not prompt or not prompt.Enabled
   or not root or not humanoid or humanoid.Health<=0
   or (root.Position-buy.Position).Magnitude>prompt.MaxActivationDistance+3 then
   remote:FireClient(player,"WinPassPromptResult",false,"OutOfRange")
   return
  end
 end
 local ok,reason=Pass.Prompt(player)
 remote:FireClient(player,"WinPassPromptResult",ok,reason)
end)

-- Lobby entry replaces only this shop's E / Tap interaction.
local shop=workspace:FindFirstChild("World1DoubleWinShop")
local prompt=shop and shop:FindFirstChild("PurchasePrompt",true)
if prompt then prompt.Enabled=false end
local pedestal=shop and shop:FindFirstChild("Pedestal")
if not pedestal or not pedestal:IsA("BasePart") then return end

-- Existing pedestal footprint + 2 studs on each side; no visible map changes.
local entered={}
local function isInside(character,margin)
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not humanoid or humanoid.Health<=0 or not root then return false end
 local point=pedestal.CFrame:PointToObjectSpace(root.Position)
 local bottom=pedestal.Size.Y/2-1
 return math.abs(point.X)<=pedestal.Size.X/2+2+margin
  and math.abs(point.Z)<=pedestal.Size.Z/2+2+margin
  and point.Y>=bottom-margin and point.Y<=bottom+10+margin
end
Players.PlayerRemoving:Connect(function(player) entered[player]=nil end)
task.spawn(function()
 while pedestal:IsDescendantOf(workspace) do
  for _,player in ipairs(Players:GetPlayers()) do
   local character=player.Character
   local entry=entered[player]
   -- A small exit margin avoids boundary jitter counting as repeated entries.
   if entry and (entry.Character~=character or not isInside(character,.75)) then
    entered[player]=nil
    entry=nil
   end
   if not entry and isInside(character,0) then
    entry={Character=character}
    entered[player]=entry -- Latch before the ownership lookup can yield.
    task.spawn(function()
     if not Pass.GetNextWinPassId(player) then return end
     -- Do not prompt a player who left or respawned during ownership lookup.
     if player.Parent~=Players or entered[player]~=entry
      or player.Character~=character or not isInside(character,.75) then return end
     Pass.Prompt(player)
    end)
   end
  end
  task.wait(.1)
 end
 table.clear(entered)
end)
