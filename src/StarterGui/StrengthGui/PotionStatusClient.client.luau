-- Uses the existing TimeReward server stream; no independent activation timer.
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Config:WaitForChild("TimeRewardConfig"))
local gui=script.Parent
local panel=Instance.new("Frame")
panel.Name="PotionStatus";panel.BackgroundTransparency=1;panel.Visible=false
panel.Size=UDim2.fromOffset(202,38);panel.ZIndex=10;panel.Parent=gui
local stack=Instance.new("UIListLayout")
stack.Padding=UDim.new(0,4);stack.SortOrder=Enum.SortOrder.LayoutOrder;stack.Parent=panel
local definitions={
 {Id="Training",Field="TrainingSeconds",Reward="Reward07",Title="Training ×"..tostring(1+Config.Potions.Training.TreadmillBonus)},
 {Id="Strength",Field="StrengthSeconds",Reward="Reward04",Title="Strength ×"..tostring(Config.Potions.Strength.Multiplier)},
}
local rows={}
for order,d in ipairs(definitions) do
 local row=Instance.new("Frame");row.Name=d.Id;row.LayoutOrder=order;row.Size=UDim2.new(1,0,0,38)
 row.BackgroundColor3=Color3.fromRGB(29,35,49);row.BackgroundTransparency=.12;row.BorderSizePixel=0;row.Visible=false;row.ZIndex=10;row.Parent=panel
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=row
 local icon=Instance.new("ImageLabel");icon.Name="Icon";icon.BackgroundTransparency=1
 icon.Image=gui.TimeRewardsPanel.Holder[d.Reward].Decor.Icon.Image
 icon.Position=UDim2.fromOffset(5,5);icon.Size=UDim2.fromOffset(28,28);icon.ScaleType=Enum.ScaleType.Fit;icon.ZIndex=11;icon.Parent=row
 local title=Instance.new("TextLabel");title.Name="Title";title.BackgroundTransparency=1;title.Text=d.Title
 title.Font=Enum.Font.GothamBold;title.TextSize=14;title.TextColor3=Color3.new(1,1,1);title.TextXAlignment=Enum.TextXAlignment.Left
 title.Position=UDim2.fromOffset(38,0);title.Size=UDim2.new(1,-84,1,0);title.ZIndex=11;title.Parent=row
 local timer=title:Clone();timer.Name="Remaining";timer.Text="";timer.TextXAlignment=Enum.TextXAlignment.Right
 timer.Position=UDim2.new(1,-45,0,0);timer.Size=UDim2.new(0,39,1,0);timer.Parent=row
 rows[d.Id]=row
end
local function layout()
 require(RS.Modules.HUDLayout).Mount(gui).Refresh()
end
local snapshot
local function render()
 local active=false
 local age=snapshot and math.max(0,workspace:GetServerTimeNow()-snapshot.ServerTime) or 0
 for _,d in ipairs(definitions) do
  local seconds=snapshot and math.max(0,(snapshot[d.Field] or 0)-age) or 0
  local row=rows[d.Id];row.Visible=seconds>0
  local n=math.ceil(seconds)
  row.Remaining.Text=string.format("%d:%02d",math.floor(n/60),n%60)
  active=active or row.Visible
 end
 panel.Visible=active
 if active then layout() end
end
local function apply(state)
 if typeof(state)~="table" or not state.Loaded or typeof(state.Potions)~="table" then return end
 local potion=state.Potions
 if typeof(potion.ServerTime)~="number" then return end
 if snapshot and potion.ServerTime<snapshot.ServerTime then return end
 snapshot=potion;render()
end
RS.Remotes:WaitForChild("TimeRewardClaim").OnClientEvent:Connect(function(result)
 if typeof(result)=="table" then apply(result.State) end
end)
task.spawn(function()
 local ok,state=pcall(function() return RS.Remotes:WaitForChild("TimeRewardState"):InvokeServer() end)
 if ok then apply(state) end
end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
task.spawn(function() while script.Parent do render();task.wait(.1) end end)
