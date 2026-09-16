local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Badges=require(RS.Modules:WaitForChild("BadgeRenderer"))
local NotificationState=require(RS.Modules:WaitForChild("InventoryNotificationState"))
local Presentation=require(RS.Modules:WaitForChild("InventoryPresentation"))
local Marketplace=game:GetService("MarketplaceService")
local Config=require(RS.Config:WaitForChild("SpeedConfig"))
local MarketplacePrice=require(RS.Modules:WaitForChild("MarketplacePrice"))
local player=Players.LocalPlayer
local gui=script.Parent
local shell=gui:WaitForChild("InventoryPanel")
local page=shell.Content:WaitForChild("Speed")
local tab=shell.Tabs:WaitForChild("Speed")
local purchase=RS.Remotes:WaitForChild("SpeedPurchaseRequest")
local stateRemote=RS.Remotes:WaitForChild("SpeedInventoryState")
local prompt=RS.Remotes:WaitForChild("SpeedPremiumPrompt")
local placeholder=page:FindFirstChild("Placeholder")
if placeholder then placeholder.Visible=false end
local list=page:FindFirstChild("SpeedList")
if not list then
 list=shell.Content.Aura:WaitForChild("AuraList"):Clone()
 list.Name="SpeedList"
 for _,v in list:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
 list.Position=UDim2.fromOffset(10,10)
 list.Size=UDim2.new(1,-20,1,-48)
 list.Visible=true
 list.Parent=page
end
local template=shell.Content.Aura.AuraList:WaitForChild("PinkAuraCard")
local cards={}
for order,id in ipairs(Config.Order) do
 local item=Config[id]
 local card=list:FindFirstChild(id)
 if not card then
  card=template:Clone();card.Name=id
  card.AuraIcon.Name="Icon";card.AuraName.Name="Title";card.StrengthBonus.Name="SpeedValue"
  local oldBadge=card.BuyButton:FindFirstChild("AuraPurchaseBadge")
  if oldBadge then oldBadge:Destroy() end
  card.Parent=list
 end
 card.LayoutOrder=order;card.Visible=true
 Presentation.SetIdentity(card.Title,card.Icon,item.Name,"rbxassetid://"..tostring(item.ImageAssetId))
 card.Title.Position=UDim2.new(.29,4,.15,0)
 card.Title.Size=UDim2.new(.43,-12,.7,0)
 card.Title.Font=Enum.Font.GothamBold
 -- Roblox enables wrapping with TextScaled; the shared width keeps both names on one line.
 card.Title.TextWrapped=false
 card.Title.TextScaled=true
 local limit=card.Title:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
 limit.MinTextSize=18;limit.MaxTextSize=26;limit.Parent=card.Title
 local speedValue=card:FindFirstChild("SpeedValue")
 if speedValue then speedValue:Destroy() end
 local button=card.BuyButton
 button.Position=UDim2.new(.73,0,.5,-23)
 button.Label.Text=""
 local price=button:FindFirstChild("Price") or card:FindFirstChild("Price")
 price.Parent=button
 price.Position=UDim2.fromScale(0,0);price.Size=UDim2.fromScale(1,1)
 price.BackgroundTransparency=1;price.Text="";price.Active=false
 price.ZIndex=button.ZIndex+1
 price.Amount.ZIndex=button.ZIndex+2
 price.CurrencyIcon.ZIndex=button.ZIndex+2
 price.Amount.Text=item.PriceType=="Win" and tostring(item.PriceWin) or "..."
 price.Amount.TextWrapped=false;price.Amount.TextScaled=true
 price.CurrencyIcon.Position=UDim2.new(.12,0,.18,0)
 price.CurrencyIcon.Size=UDim2.new(.22,0,.64,0)
 price.Amount.Position=UDim2.new(.38,0,.1,0)
 price.Amount.Size=UDim2.new(.52,0,.8,0)
 if item.PriceType=="Win" then
  price.CurrencyIcon.Image=gui.WinLabel.TrophyIcon.Image
 else
  price.CurrencyIcon.Image=shell.Content.Aura.AuraList.RedAuraCard.Price.CurrencyIcon.Image
 end
 price.CurrencyIcon.Visible=true
 cards[id]=card
end
local status=page:FindFirstChild("Status")
if not status then
 status=Instance.new("TextLabel");status.Name="Status";status.BackgroundTransparency=1
 status.Position=UDim2.new(0,10,1,-32);status.Size=UDim2.new(1,-20,0,26)
 status.Font=Enum.Font.GothamBold;status.TextSize=14;status.TextColor3=Color3.new(1,1,1)
 status.TextWrapped=true;status.ZIndex=32;status.Text="";status.Parent=page
end
local badge=tab:FindFirstChild("SpeedPurchaseBadge")
if not badge then
 badge=Badges.GetOrClone(gui.LeftMenu.InventoryButton.NotificationBadge,tab,"SpeedPurchaseBadge");badge.Size=UDim2.fromOffset(24,24)
 badge.Position=UDim2.new(1,-2,0,2);badge.AnchorPoint=Vector2.new(1,0)
 badge.ZIndex=tab.ZIndex+3
 for _,v in badge:GetDescendants() do if v:IsA("GuiObject") then v.ZIndex=badge.ZIndex+1 end end
 badge.Parent=tab
end
local state={Loaded=false,OwnedSpeeds={},PremiumOwned=false}
local pending=false
local revision=0
local function render()
 for id,card in pairs(cards) do
  local owned=id=="Premium" and state.PremiumOwned or (id=="Speed1" and state.OwnedSpeeds.Speed1==true)
  card.BuyButton.Label.Text=owned and "OWNED" or ""
  card.BuyButton.Label.Visible=owned
  Presentation.SetButtonEnabled(card.BuyButton,state.Loaded and not owned and not pending)
  card.BuyButton.BackgroundColor3=owned and Color3.fromRGB(70,76,88) or Color3.fromRGB(43,121,88)
  card.BuyButton.Price.Visible=not owned
 end
 local win=player:GetAttribute("Win")
 local notify=state.Loaded and typeof(win)=="number" and win>=Config.Speed1.PriceWin and not NotificationState.IsSeen("Speed","Speed1")
 Badges.SetVisible(badge,notify)
 gui.LeftMenu.InventoryButton:SetAttribute("SpeedPurchaseAvailable",notify)
end
local function apply(s)
 if typeof(s)~="table" or s.Loaded~=true or typeof(s.OwnedSpeeds)~="table" then return end
 revision+=1;state=s;render()
end
local function refresh()
 local version=revision
 local ok,s=pcall(function() return stateRemote:InvokeServer() end)
 if ok and version==revision then apply(s) end
end
local messages={NotEnoughWin="Not enough Win",AlreadyOwned="Already owned",SaveFailed="Save failed. Please try again.",DataSaving="Please wait and try again.",DataNotLoaded="Loading player data...",RequestInProgress="Please wait.",OwnershipUnavailable="Ownership check unavailable. Please try again.",PromptUnavailable="Purchase unavailable."}
Responsive.ConnectActivation(cards.Speed1.BuyButton,function()
 if not cards.Speed1.BuyButton.Active then return end
 pending=true;status.Text="";render();purchase:FireServer("Speed1")
end)
Responsive.ConnectActivation(cards.Premium.BuyButton,function()
 if not cards.Premium.BuyButton.Active then return end
 pending=true;status.Text="";render();prompt:FireServer("Prompt")
end)
purchase.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" then return end
 if result.Success~=nil then pending=false;status.Text=result.Success and "" or (messages[result.Code] or "Please try again.") end
 apply(result.State);render()
end)
prompt.OnClientEvent:Connect(function(result)
 if typeof(result)=="table" and result.Success~=true then
  pending=false;status.Text=messages[result.Code] or "Please try again.";refresh();render()
 end
end)
Marketplace.PromptGamePassPurchaseFinished:Connect(function(p,id)
 if p==player and id==Config.Premium.GamePassId then pending=false;refresh();render() end
end)
player:GetAttributeChangedSignal("Win"):Connect(render)
local function opened()
 if shell.Visible and page.Visible then
  refresh()
  local win=player:GetAttribute("Win")
  if state.Loaded and typeof(win)=="number" and win>=Config.Speed1.PriceWin then NotificationState.MarkSeen("Speed",{"Speed1"}) end
 end
end
page:GetPropertyChangedSignal("Visible"):Connect(opened)
shell:GetPropertyChangedSignal("Visible"):Connect(opened)
NotificationState.Changed:Connect(render)
task.spawn(function()
 local price,source=MarketplacePrice.Get(Config.Premium.GamePassId,Enum.InfoType.GamePass,Config.Premium.FallbackPrice)
 MarketplacePrice.Apply(cards.Premium.BuyButton.Price.Amount,price,source)
 cards.Premium.BuyButton.Price:SetAttribute("PriceSource",source)
end)
render()
task.spawn(function()
 while script.Parent and not NotificationState.Load() do task.wait(2) end
 while script.Parent and not state.Loaded do refresh();if not state.Loaded then task.wait(2) end end
 render()
end)

