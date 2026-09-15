local RS=game:GetService("ReplicatedStorage")
local GroupService=game:GetService("GroupService")
local Config=require(RS.Config:WaitForChild("CommunityRewardConfig"))
local RewardDisplay=require(RS.Modules:WaitForChild("RewardDisplay"))
local gui=script.Parent
local panel=gui:WaitForChild("CommunityRewardsPanel")
local menu=gui:WaitForChild("LeftMenu")
local button=menu:WaitForChild("CommunityRewardsButton")
local stateRemote=RS.Remotes:WaitForChild("CommunityRewardState")
local claim=RS.Remotes:WaitForChild("CommunityRewardClaim")
local snapshot,pending,checking,message
local function render()
 local status=snapshot and snapshot.Status or "Loading"
 -- Loaded non-Claimed states all represent an unclaimed reward, including NotJoined.
 -- Keep the last known badge during a transient Loading response.
 if snapshot and snapshot.Loaded==true then
  button.NotificationBadge.Visible=snapshot.Status~="Claimed"
 end
 local done=status=="Claimed"
 panel.Redeemed.Visible=done panel.Redeem.Visible=not done
 local usable=not pending and (status=="Ready" or status=="NotJoined")
 panel.Redeem.Active=usable==true panel.Redeem.Interactable=usable==true panel.Redeem.AutoButtonColor=usable==true
 panel.Redeem.MainText.Text=pending and "PLEASE WAIT" or (status=="Ready" and "CLAIM" or (status=="NotJoined" and "JOIN COMMUNITY" or string.upper(status)))
 panel.Description.Text=message or ("Join our community for\n"..RewardDisplay.GetCommunityText(Config).."!")
 panel.RewardWin.ImageText.Text="Win +"..tostring(Config.WinAmount)
 local itemCard=panel:FindFirstChild("RewardItem")
 if itemCard and itemCard:FindFirstChild("ImageText") then itemCard.ImageText.Text="Item ×"..tostring(Config.ItemAmount) end
 panel.Refresh.Active=not checking panel.Refresh.Interactable=not checking
end
local function refresh()
 if checking then return end
 checking=true render()
 local ok,state=pcall(function()return stateRemote:InvokeServer()end)
 checking=false
 if ok and typeof(state)=="table" then snapshot=state else message="Check unavailable. Please try again." end
 render()
end
panel.Refresh.Activated:Connect(function() message=nil refresh() end)
panel.Redeem.Activated:Connect(function()
 if pending or not snapshot then return end
 if snapshot.Status=="Ready" then
  pending=true render() claim:FireServer()
  task.delay(8,function()if pending then pending=nil refresh()end end)
 elseif snapshot.Status=="NotJoined" then
  pending=true render()
  local ok=pcall(function()GroupService:PromptJoinAsync(Config.GroupId)end)
  pending=nil
  message=ok and "Joined? Press CHECK.\nIf unchanged, rejoin the game." or "Open our Roblox community to join.\nThen CHECK or rejoin the game."
  refresh()
 end
end)
claim.OnClientEvent:Connect(function(data)
 if typeof(data)~="table" then return end
 if typeof(data.State)=="table" then snapshot=data.State end
 if data.Code then
  pending=nil
  message=data.Success and ("Claimed! "..RewardDisplay.GetCommunityText(Config)) or tostring(data.Code)
 end
 render()
end)
button.Activated:Connect(function()
 panel.Visible=not panel.Visible
 if panel.Visible then
  for _,n in ipairs({"TimeRewardsPanel","DailyRewardsPanel","InventoryPanel","ShopPanel","RebirthPanel","MergePanel"}) do
   local other=gui:FindFirstChild(n) if other then other.Visible=false end
  end
  refresh()
 end
end)
panel.Top.Close.Activated:Connect(function()panel.Visible=false end)
for _,x in menu:GetChildren() do
 if x:IsA("GuiButton") and x~=button then x.Activated:Connect(function()panel.Visible=false end) end
end
local function order()
 task.defer(function()
  if panel.Visible then gui.DisplayOrder=26
  elseif not gui.TimeRewardsPanel.Visible and not gui.DailyRewardsPanel.Visible then gui.DisplayOrder=10 end
 end)
end
panel:GetPropertyChangedSignal("Visible"):Connect(order)
gui.TimeRewardsPanel:GetPropertyChangedSignal("Visible"):Connect(order)
gui.DailyRewardsPanel:GetPropertyChangedSignal("Visible"):Connect(order)
render() task.spawn(refresh)

