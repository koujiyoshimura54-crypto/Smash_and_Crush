-- QA hold-jump input at the ordinary pre-physics input boundary.
local p=game.Players.LocalPlayer
local measure=game.ReplicatedStorage:WaitForChild('__NightMeasure')
local centers={165.875,283.86,404.62,528.695,656.52,826.87,1049.87,1257.87,1420.87,1595.42}
script:SetAttribute('Hold',false);script:SetAttribute('JumpStates',0)
local function bind(c)
 c:WaitForChild('Humanoid').StateChanged:Connect(function(_,new)
  if new==Enum.HumanoidStateType.Jumping and script:GetAttribute('Hold')then
   script:SetAttribute('JumpStates',script:GetAttribute('JumpStates')+1)
   measure:FireServer('ClientEvent',{Remote='QAJumpInput',Data={Type='JumpStarted'}})
  end
 end)
end
p.CharacterAdded:Connect(bind);if p.Character then task.spawn(bind,p.Character)end
game:GetService('RunService').PreSimulation:Connect(function()
 local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
 local stage=p:GetAttribute('CurrentStage')or 1
 if script:GetAttribute('Hold')and h and h.Health>0 and r and p:GetAttribute('IsFighting') then
  h.Jump=true
 end
end)
