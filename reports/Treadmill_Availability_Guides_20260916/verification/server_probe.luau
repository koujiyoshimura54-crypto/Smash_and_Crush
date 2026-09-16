-- Temporary isolated-store Play verification; never retained in the DataModel.
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Training=require(game.ServerScriptService.Services.TrainingManager)
local Pass=require(game.ServerScriptService.Services.GamePassService)
local control=Instance.new("Folder")
control.Name="TreadmillGuideQA"
control.Parent=workspace
local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
repeat task.wait(.1) until Data.Get(player) and Data.Get(player).Loaded and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
local originalEffects,originalOwned=Pass.AreEffectsEnabled,Pass.HasPremiumTreadmill
local function away()
 Training.StopTraining(player)
 player.Character:PivotTo(workspace.GeneratedMap.TrainingArea.SpawnLocation.CFrame*CFrame.new(0,5,0))
end
local function ride(name)
 local root=player.Character.HumanoidRootPart
 local h=player.Character:FindFirstChildOfClass("Humanoid")
 player.Character:PivotTo(workspace.Treadmill[name].TrainingZone.CFrame*CFrame.new(0,h.HipHeight+root.Size.Y/2,0))
 root.AssemblyLinearVelocity=Vector3.zero
 root.AssemblyAngularVelocity=Vector3.zero
 Training.UpdateZoneOccupants()
end
control:GetAttributeChangedSignal("Action"):Connect(function()
 local action=control:GetAttribute("Action")
 local ok,result=pcall(function()
  local count=action:match("^rebirth(%d+)$")
  if count then away(); Data.SetRebirthCount(player,tonumber(count)) end
  if action=="normal" then ride("Tredmill06") end
  if action=="blue" then ride("Tredmill04") end
  if action=="green" then ride("Tredmill02") end
  if action=="premium" then ride("Tredmill01") end
  if action=="exit" then away() end
  if action=="owned" or action=="unowned" or action=="effectsOff" then
   away()
   Pass.AreEffectsEnabled=function(p) if p==player then return action~="effectsOff" end return originalEffects(p) end
   Pass.HasPremiumTreadmill=function(p) if p==player then return action~="unowned" end return originalOwned(p) end
  end
  if action=="restore" then away(); Pass.AreEffectsEnabled=originalEffects; Pass.HasPremiumTreadmill=originalOwned end
  Training.UpdateZoneOccupants()
  task.wait(.3)
  local allowed={}
  for _,model in Training.GetTreadmills() do allowed[model.Name]=Training.CanUseTreadmill(player,model)==true end
  return {allowed=allowed,active=player:GetAttribute("TrainingTreadmill"),training=player:GetAttribute("IsTraining"),rebirth=player:GetAttribute("RebirthCount")}
 end)
 control:SetAttribute("Result",Http:JSONEncode({action=action,ok=ok,result=ok and result or nil,error=not ok and tostring(result) or nil}))
end)
away()
Data.SetRebirthCount(player,0)
control:SetAttribute("Ready",true)
