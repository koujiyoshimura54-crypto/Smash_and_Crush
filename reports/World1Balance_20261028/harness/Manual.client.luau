-- QA repeats normal manual-combat input; server cooldowns remain authoritative.
local p=game.Players.LocalPlayer
local r=game.ReplicatedStorage.Remotes:WaitForChild('AutoTapRequest')
local mine=false;local lastToggle=-math.huge
script:SetAttribute('EnabledInput',false)
task.spawn(function()
 while true do
  task.wait(.26)
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  local wanted=script:GetAttribute('EnabledInput')and h and h.Health>0 and p:GetAttribute('IsFighting')and not p:GetAttribute('IsTraining')
  local auto=p:GetAttribute('AutoTapEnabled')~=false
  if wanted then
   if auto then
    if os.clock()-lastToggle>.3 then
     r:FireServer('Toggle');lastToggle=os.clock();mine=true
     game.ReplicatedStorage.__NightMeasure:FireServer('ClientEvent',{Remote='QAManualCombat',Data={Type='ManualRequested'}})
    end
   else r:FireServer('Tap')end
  elseif mine and not auto and os.clock()-lastToggle>.3 then
   r:FireServer('Toggle');lastToggle=os.clock();mine=false
  end
 end
end)
