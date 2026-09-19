local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Config:WaitForChild("TimeRewardConfig"))
local RewardDisplay=require(RS.Modules:WaitForChild("RewardDisplay"))
local gui=script.Parent
local panel=gui:WaitForChild("TimeRewardsPanel")
local menu=gui:WaitForChild("LeftMenu")
-- Keep this panel above the separate 2x Win ScreenGui while open.
local baseDisplayOrder=gui.DisplayOrder
local function updateDisplayOrder()
 gui.DisplayOrder=panel.Visible and math.max(baseDisplayOrder,26) or baseDisplayOrder
end
panel:GetPropertyChangedSignal("Visible"):Connect(updateDisplayOrder)
updateDisplayOrder()
local request=RS.Remotes:WaitForChild("TimeRewardClaim")
local getState=RS.Remotes:WaitForChild("TimeRewardState")
local snapshot,receivedAt,pending,message=nil,0,nil,""
local CLAIMED_GRADIENT=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromRGB(116,110,132)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(154,149,168)),
})
local originalButtonVisuals=setmetatable({},{__mode="k"})
local function setClaimedVisual(button,claimed)
 local gradient=button:FindFirstChildOfClass("UIGradient")
 local outer=button:FindFirstChild("UIStroke")
 local inner=button:FindFirstChild("UIStrokeInner")
 local original=originalButtonVisuals[button]
 if not original then
  original={BackgroundColor3=button.BackgroundColor3,GradientColor=gradient and gradient.Color,OuterColor=outer and outer.Color,InnerColor=inner and inner.Color}
  originalButtonVisuals[button]=original
 end
 button.BackgroundColor3=claimed and Color3.fromRGB(138,133,150) or original.BackgroundColor3
 if gradient then gradient.Color=claimed and CLAIMED_GRADIENT or original.GradientColor end
 if outer then outer.Color=claimed and Color3.fromRGB(61,58,69) or original.OuterColor end
 if inner then inner.Color=claimed and Color3.fromRGB(210,207,218) or original.InnerColor end
end
local function duration(seconds)
 seconds=math.max(0,math.ceil(seconds))
 return string.format("%d:%02d",math.floor(seconds/60),seconds%60)
end
local label=RewardDisplay.GetText
local function render()
 local anyReady=false
 if snapshot and snapshot.Loaded and snapshot.States then
  for _,state in pairs(snapshot.States) do if state=="Ready" then anyReady=true;break end end
 end
 menu.TimeRewardsButton.NotificationBadge.Visible=anyReady
 local age=os.clock()-receivedAt
 for _,r in ipairs(Config.Rewards) do
  local card=panel.Holder:FindFirstChild(r.Id)
  if card then
   card.RewardName.Text=label(r)
   local state=snapshot and snapshot.States and snapshot.States[r.Id] or "Locked"
   local ready=state=="Ready" and snapshot.Loaded==true
   card.Locked.Visible=not ready and state~="Claimed" and state~="Pending"
   card.Redeem.Visible=not card.Locked.Visible
   card.Redeem.Active=ready and pending==nil
   card.Redeem.AutoButtonColor=card.Redeem.Active
   setClaimedVisual(card.Redeem,state=="Claimed")
   card.Redeem.TextLabel.Text=state=="Claimed" and "CLAIMED" or (state=="Pending" and "SAVING..." or "CLAIM")
   local elapsed=snapshot and snapshot.ElapsedSeconds or 0
   card.Countdown.Text=state=="Claimed" and "CLAIMED" or (ready and "READY" or (state=="Pending" and "SAVING..." or duration(r.RequiredSeconds-elapsed-age)))
   if not snapshot or not snapshot.Loaded then card.Countdown.Text="LOADING..." end
   if state=="Failed" then card.Countdown.Text="ERROR" end
  end
 end
 local text=message
 if snapshot and snapshot.Potions then
  local s=math.max(0,snapshot.Potions.StrengthSeconds-age)
  local t=math.max(0,snapshot.Potions.TrainingSeconds-age)
  if s>0 then text=text.."  Strength x"..tostring(Config.Potions.Strength.Multiplier).." "..duration(s) end
  if t>0 then text=text.."  Training +"..tostring(Config.Potions.Training.TreadmillBonus).." "..duration(t) end
 end
 panel.Status.Text=text
end
local function refresh()
 local ok,state=pcall(function() return getState:InvokeServer() end)
 if ok and typeof(state)=="table" then snapshot=state receivedAt=os.clock() else message="Rewards unavailable. Please reopen." end
 render()
end
for _,r in ipairs(Config.Rewards) do
 local card=panel.Holder:WaitForChild(r.Id)
 Responsive.ConnectActivation(card.Redeem,function()
  if pending or not snapshot or not snapshot.States or snapshot.States[r.Id]~="Ready" then return end
  pending=r.Id message="Claiming..."
  request:FireServer(r.Id) render()
  task.delay(5,function() if pending==r.Id then pending=nil refresh() end end)
 end)
end
request.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" then return end
 if typeof(result.State)=="table" then snapshot=result.State receivedAt=os.clock() end
 if result.Code then
  pending=nil
  message=result.Success and "Claimed!" or tostring(result.Code)
  if result.Success and result.Result and result.Result.Items then message=tostring(#result.Result.Items).." Items received" end
 end
 render()
end)
local function layout()
 require(game.ReplicatedStorage.Modules.ResponsivePanels).Fit(panel,gui)
end
menu.TimeRewardsButton.Activated:Connect(function()
 panel.Visible=not panel.Visible
 if panel.Visible then
  for _,name in ipairs({"InventoryPanel","ShopPanel","RebirthPanel","MergePanel"}) do local other=gui:FindFirstChild(name) if other then other.Visible=false end end
  refresh()
 end
end)
Responsive.ConnectActivation(panel.Top.Close,function() panel.Visible=false end)
for _,name in ipairs({"InventoryButton","ShopButton","RebirthButton","MergeButton","SkipButton"}) do
 menu[name].Activated:Connect(function() panel.Visible=false end)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
task.spawn(refresh)
task.spawn(function() while gui.Parent do task.wait(.25) if panel.Visible then render() end end end)
