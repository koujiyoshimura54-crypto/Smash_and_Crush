-- Temporary native callback driver, not shipped in StarterPlayer.
local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer
local control=Instance.new("BindableFunction");control.Name="__InvQAClient";control.Parent=RS
local gui=p.PlayerGui:WaitForChild("StrengthGui");local shell=gui:WaitForChild("InventoryPanel")
local observations={}
control.OnInvoke=function(action,args)
 if action=="Open" then gui.__InvQAOpen:Invoke(args or "Dumbbells")
 elseif action=="Click" then local o=shell for part in args:gmatch("[^.]+") do o=o[part] end
  assert(o.Active and o.Interactable,"Disabled control");o.__InvQAActivate:Invoke()
 elseif action=="Scroll" then shell.Content.Dumbbells.Items.CanvasPosition=Vector2.new(0,args)
 elseif action=="Close" then shell.Visible=false
 elseif action=="Narrow" then gui:SetAttribute("PanelReserveRight",gui.AbsoluteSize.X-650)
 elseif action=="Normal" then gui:SetAttribute("PanelReserveRight",0)
 end
 task.wait(.2)
 local page=shell.Content.Dumbbells;local pop=page:FindFirstChild("DumbbellSellPanel")
 local cards={}
 for _,o in page.Items:GetChildren() do if o:IsA("GuiButton") then
  cards[o.Name]={Visible=o.Visible,Count=o.OwnedCount.Text,Effect=o.Multiplier.Text,Pos=tostring(o.AbsolutePosition),Size=tostring(o.AbsoluteSize),
   Buy=o.BuyButton.PurchasedButtonVisual.Main.Amount.Text,Sell=o.SellButton.Visible}
 end end
 local textRows={}
 for _,o in page:GetDescendants() do if o:IsA("TextLabel") and o.Visible and o.TextTransparency<1 then
  textRows[o:GetFullName()]={Text=o.Text,Font=tostring(o.FontFace.Family),Fits=o.TextFits,Size=tostring(o.AbsoluteSize)}
 end end
 return {Cards=cards,Text=textRows,Popup=pop and {Visible=pop.Visible,Item=pop:GetAttribute("ItemId"),Count=pop:GetAttribute("SellableCount"),Position=tostring(pop.AbsolutePosition),Size=tostring(pop.AbsoluteSize),
 One=pop.SellOne.Active,All=pop.SellAll.Active,OnePrice=pop.SellOne:FindFirstChild("PurchasedButtonVisual") and pop.SellOne.PurchasedButtonVisual.Main.Amount.Text,AllPrice=pop.SellAll:FindFirstChild("PurchasedButtonVisual") and pop.SellAll.PurchasedButtonVisual.Main.Amount.Text},
 Equipped={Image=page.Equipped.Preview.Image,Effect=page.Equipped.Multiplier.Text},Viewport=tostring(gui.AbsoluteSize),
 SourceStrength=p:GetAttribute("Strength"),Win=p:GetAttribute("Win"),Panel=tostring(shell.AbsoluteSize),Scale=shell.ResponsiveScale.Scale}
end
