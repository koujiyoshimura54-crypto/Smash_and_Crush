if not game:GetService("RunService"):IsStudio() then return end
local p=game.Players.LocalPlayer local H=game:GetService("HttpService")
local value=Instance.new("StringValue")value.Name="SpacingClientResults"value.Parent=p:WaitForChild("PlayerGui")
local state=workspace:WaitForChild("SpacingPlayTest",45)if not state then return end
game:GetService("RunService"):BindToRenderStep("SpacingQA_Move",Enum.RenderPriority.Last.Value,function()
 local target=state:GetAttribute("MoveTarget")
 local ch=p.Character local root=ch and ch:FindFirstChild("HumanoidRootPart") local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if target and root and hum then
  local delta=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
  hum:Move(delta.Magnitude>.3 and delta.Unit or Vector3.zero,false)
 end
end)
local rows={}
game.ReplicatedStorage.Remotes.GameRemotes.CombatState.OnClientEvent:Connect(function(d)
 if d.Type~="CombatAttack" then return end
 local phase=state:GetAttribute("Phase")
 if phase~="Wall" and phase~="Boss" and phase~="Approach" then return end
 task.delay(.1,function()
 local n=state:GetAttribute("Stage")
 local row={Stage=n,Phase=phase,CombatType=d.CombatType,BossGauges=0,WallBars=0}
 for _,v in workspace:GetDescendants() do
  if v:IsA("BillboardGui") and v.Name=="PersonalGauge" and v.Enabled then
   row.BossGauges+=1
   row.BossName=v.BossName.Text row.HPText=v.HPLabel.Text row.StageText=v.StageNumber.Text
   local e=v.Parent.Parent
   local visual=e:FindFirstChildOfClass('Model') or e
   local cf,sz=visual:GetBoundingBox() local top=cf.Position.Y+sz.Y/2
   for _,bone in visual:GetDescendants() do if bone:IsA("Bone") then top=math.max(top,bone.WorldPosition.Y)end end
   row.UITopError=(v.Adornee.Position+v.StudsOffsetWorldSpace).Y-(top+math.clamp(sz.Y*.1,4,8))
   row.Adornee=v.Adornee.Name
  end
  if v:IsA("Frame") and v.Name=="HPBar" and v.Visible and v.Parent and v.Parent.Parent and v.Parent.Parent.Name=="StageSurface" then row.WallBars+=1 end
 end
 table.insert(rows,row)value.Value=H:JSONEncode(rows)
 end)
end)
