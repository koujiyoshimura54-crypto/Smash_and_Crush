-- Temporary isolated-store Play probe. Removed after verification.
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local Training=require(game.ServerScriptService.Services.TrainingManager)
local TreadmillConfig=require(game.ReplicatedStorage.Config.TreadmillConfig)
local control=Instance.new("Folder")
control.Name="TreadmillColorQAControl"
control.Parent=workspace
local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
repeat task.wait(.1) until Data.Get(player) and Data.Get(player).Loaded and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
local function parkAt(treadmill)
 local character=player.Character
 local root=character.HumanoidRootPart
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 character:PivotTo(treadmill.TrainingZone.CFrame*CFrame.new(0,humanoid.HipHeight+root.Size.Y/2,0))
 root.AssemblyLinearVelocity=Vector3.zero
 root.AssemblyAngularVelocity=Vector3.zero
end
local function parkAway()
 Training.StopTraining(player)
 local spawn=workspace.GeneratedMap.TrainingArea.SpawnLocation
 player.Character:PivotTo(spawn.CFrame*CFrame.new(0,5,0))
end
local function test(name,rebirth)
 local treadmill=workspace.Treadmill[name]
 local entry=TreadmillConfig.Get(name)
 Data.SetRebirthCount(player,rebirth)
 Strength.SetStrength(player,0)
 Strength.ResetGainRemainder(player)
 local changes={}
 local last=player:GetAttribute("Strength") or 0
 local connection=player:GetAttributeChangedSignal("Strength"):Connect(function()
  local current=player:GetAttribute("Strength") or last
  if current>last then table.insert(changes,current-last) end
  last=current
 end)
 parkAt(treadmill)
 Training.UpdateZoneOccupants()
 local deadline=os.clock()+2
 repeat task.wait(.05) until #changes>0 or os.clock()>=deadline
 parkAway()
 connection:Disconnect()
 return {
  name=name,multiplier=entry.Multiplier,requiredRebirth=entry.RequiredRebirth,
  firstCommittedGain=changes[1],isTraining=player:GetAttribute("IsTraining"),
  strength=player:GetAttribute("Strength"),label=treadmill.TreadmillUIDisplay.TreadmillInfo.Strength.Text,
 }
end
control:GetAttributeChangedSignal("Action"):Connect(function()
 local action=control:GetAttribute("Action")
 local ok,result=pcall(function()
  if action=="test3" then return test("Tredmill04",3) end
  if action=="test5" then return test("Tredmill02",5) end
  error("unknown action")
 end)
 control:SetAttribute("Result",Http:JSONEncode({action=action,ok=ok,result=ok and result or nil,error=not ok and tostring(result) or nil}))
end)
control:SetAttribute("Ready",true)
