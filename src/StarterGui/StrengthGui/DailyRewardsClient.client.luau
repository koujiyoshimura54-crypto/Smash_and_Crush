local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Config:WaitForChild("DailyRewardConfig"))
local RewardDisplay=require(RS.Modules:WaitForChild("RewardDisplay"))
local gui=script.Parent
local panel=gui:WaitForChild("DailyRewardsPanel")
local menu=gui:WaitForChild("LeftMenu")
local request=RS.Remotes:WaitForChild("DailyRewardClaim")
local stateRemote=RS.Remotes:WaitForChild("DailyRewardState")
local ShopConfig=require(RS.Config.ShopProductConfig)
local vip=panel.Holder:WaitForChild("VIPBonus")
local snapshot,pending
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
local function render()
 local state=snapshot and snapshot.States and snapshot.States.VIP or "Locked"
 vip.RewardText.Text=RewardDisplay.GetText(ShopConfig.Get("VIP").DailyBonus)
 vip.DayText.Text="VIP 窶｢ Daily bonus"
 vip.Locked.Visible=state=="Locked"
 vip.Locked.TextLabel.Text="VIP ONLY"
 vip.Redeem.Visible=not vip.Locked.Visible
 vip.Redeem.Active=state=="Ready" and pending==nil
 vip.Redeem.AutoButtonColor=vip.Redeem.Active
 setClaimedVisual(vip.Redeem,state=="Claimed")
 vip.Redeem.TextLabel.Text=state=="Claimed" and "CLAIMED" or pending=="VIP" and "SAVING..." or "CLAIM"
 menu.DailyRewardsButton.NotificationBadge.Visible=snapshot~=nil and snapshot.Loaded==true and snapshot.HasReady==true
 for day,reward in ipairs(Config.Rewards) do
  local card=panel.Holder["Day"..day]
  local state=snapshot and snapshot.States and snapshot.States["Day"..day] or "Locked"
  local ready=snapshot and snapshot.Loaded and state=="Ready"
  card.RewardText.Text=RewardDisplay.GetText(reward)
  card.DayText.Text="Day "..day..(ready and " 窶｢ READY" or "")
  card.Locked.Visible=state=="Locked" or state=="Failed"
  card.Redeem.Visible=not card.Locked.Visible
  card.Redeem.Active=ready==true and pending==nil
  card.Redeem.AutoButtonColor=card.Redeem.Active
  setClaimedVisual(card.Redeem,state=="Claimed")
  card.Redeem.TextLabel.Text=state=="Claimed" and "CLAIMED" or (state=="Pending" and "SAVING..." or "CLAIM")
  card.Locked.TextLabel.Text=state=="Failed" and "ERROR" or "LOCKED"
 end
end
local function refresh()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if ok and typeof(state)=="table" then snapshot=state end
 render()
end
for day=1,Config.GetDayCount() do
 Responsive.ConnectActivation(panel.Holder["Day"..day].Redeem,function()
  if pending or not snapshot or not snapshot.States or snapshot.States["Day"..day]~="Ready" then return end
  pending=day request:FireServer(day) render()
  task.delay(5,function() if pending==day then pending=nil;refresh() end end)
 end)
end
Responsive.ConnectActivation(vip.Redeem,function()
 if pending or not snapshot or not snapshot.States or snapshot.States.VIP~="Ready" then return end
 pending="VIP";request:FireServer("VIP");render()
 task.delay(5,function()if pending=="VIP" then pending=nil;refresh()end end)
end)
request.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" then return end
 if typeof(result.State)=="table" then snapshot=result.State end
 if result.Code then pending=nil end
 render()
end)
local function layout()
 require(game.ReplicatedStorage.Modules.ResponsivePanels).Fit(panel,gui)
end
menu.DailyRewardsButton.Activated:Connect(function()
 panel.Visible=not panel.Visible
 if panel.Visible then
  for _,name in ipairs({"TimeRewardsPanel","InventoryPanel","ShopPanel","RebirthPanel","MergePanel"}) do
   local other=gui:FindFirstChild(name) if other then other.Visible=false end
  end
  refresh()
 end
end)
Responsive.ConnectActivation(panel.Top.Close,function() panel.Visible=false end)
for _,name in ipairs({"TimeRewardsButton","InventoryButton","ShopButton","RebirthButton","MergeButton","SkipButton"}) do
 local button=menu:FindFirstChild(name)
 if button then button.Activated:Connect(function() panel.Visible=false end) end
end
local function order()
 task.defer(function()
  gui.DisplayOrder=(panel.Visible or gui.TimeRewardsPanel.Visible) and 26 or 10
 end)
end
panel:GetPropertyChangedSignal("Visible"):Connect(order)
gui.TimeRewardsPanel:GetPropertyChangedSignal("Visible"):Connect(order)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout() order() render() task.spawn(refresh)

