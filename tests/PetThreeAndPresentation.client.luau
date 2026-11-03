local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local Q=require(RS.__P3QAConnections)
local Pet=require(RS.Modules.Pet)
local PC=require(p.PlayerScripts.Services.PetClient)
local remote=RS:WaitForChild("__P3QARemote")
local function gui()return p.PlayerGui:WaitForChild("StrengthGui")end
local function text(x)return {Path=x:GetFullName(),Text=x.Text,Size=tostring(x.AbsoluteSize),Fits=x.TextFits,Font=x.FontFace.Family}end
local function shop()
 local g=gui();g.ShopPanel.Visible=true;require(RS.Modules.ResponsivePanels).Fit(g.ShopPanel,g);task.wait(.25)
 local rows={}
 for _,card in ipairs(g.ShopPanel.MainScrollingFrame.Holder:GetChildren())do
  local b=card:FindFirstChild("Purchase",true);local v=b and b:FindFirstChild("PurchasedButtonVisual")
  if v then rows[#rows+1]={Name=card.Name,Button=tostring(b.AbsoluteSize),Visual=tostring(v.AbsoluteSize),Amount=text(v.Main.Amount),Currency=v.Main:FindFirstChild("Icon") and tostring(v.Main.Icon.AbsoluteSize),Input=b.Active and b.Interactable}end
 end
 return rows
end
local function followers()
 local out={}
 for _,m in ipairs(workspace:WaitForChild("Pets"):GetChildren())do
  local owner=game.Players:GetPlayerByUserId(m:GetAttribute("OwnerUserId") or 0)
  local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
  out[#out+1]={Owner=m:GetAttribute("OwnerUserId"),Id=m:GetAttribute("PetInstanceId"),Species=m:GetAttribute("PetSpeciesId"),Side=m:GetAttribute("FormationSide"),Position=root and tostring(root.CFrame:PointToObjectSpace(m:GetPivot().Position))}
 end
 return out
end
local function pets()
 PC.refresh();task.wait(.2)
 require(p.PlayerScripts.Services.MenuClient).open("Inventory");task.wait(.3)
 local panel=p.PlayerGui.ScreenGui.Menus.Inventory
 return {State=PC.state(),Info=text(panel.Main["2PetsEquipInfo"]),Followers=followers()}
end
local function candidates()
 local rows={}
 for _,sheet in ipairs(p.PlayerGui.ScreenGui:GetChildren())do
  if sheet:IsA("BillboardGui") and sheet:FindFirstChild("Background") and sheet.Background:FindFirstChild("Pets")then
   local entries={}
   for _,frame in ipairs(sheet.Background.Pets:GetChildren())do
    if frame:IsA("ImageLabel") and frame.Visible then
     local vp=frame:FindFirstChild("LimitedPetViewport")
     entries[#entries+1]={Species=frame:GetAttribute("PetSpeciesId"),Silhouette=frame:GetAttribute("PetSilhouette"),Tint=tostring(frame.ImageColor3),ModelTint=vp and tostring(vp.ImageColor3),Percent=frame.Percent.Text}
    end
   end
   rows[sheet.Name]=entries
  end
 end
 return rows
end
local function mergeSnap()
 local host=p.PlayerGui:FindFirstChild("MergeShopGui");local out={Labels={},Stars=0,Counts={}}
 if not host then return out end
 for _,o in ipairs(host:GetDescendants())do
  if o.Name=="RarityStars"then out.Stars+=1 end
  if o:IsA("TextLabel") and (o.Name=="Value" or o.Name=="Unit" or o.Name=="Total" or o.Name=="Selected" or o.Name=="OwnedCount" or o.Name=="Percent")then out.Labels[#out.Labels+1]=text(o)end
  if o:GetAttribute("SelectedCount")then out.Counts[o.Name]=o:GetAttribute("SelectedCount")end
 end
 return out
end
local probe=Instance.new("BindableFunction");probe.Name="__P3QAClient";probe.Parent=RS
probe.OnInvoke=function(action,arg)
 if action=="Hide"then Q.View:Hide();return true
 elseif action=="Submit"then Q.View:SubmitItem();task.wait(1);return mergeSnap()
 elseif action=="Hatch"then local id=remote:InvokeServer("Hatch",arg);task.wait(.8);return {Id=id,Rows=candidates()}
 elseif action=="Shop"then return shop()
 elseif action=="ShopReopen"then gui().ShopPanel.Visible=false;task.wait(.2);return shop()
 elseif action=="ShopNarrow"then local g=gui();g:SetAttribute("PanelReserveRight",g.AbsoluteSize.X-540);return shop()
 elseif action=="Normal"then local g=gui();g:SetAttribute("PanelReserveRight",nil);return shop()
 elseif action=="ShopClick"then
  local card=gui().ShopPanel.MainScrollingFrame.Holder[arg];local b=card:FindFirstChild("Purchase",true)
  local n=Q.Fire(b,"Activated");task.wait(.5);return {Callbacks=n,Rows=shop()}
 elseif action=="Pets"then gui().ShopPanel.Visible=false;return pets()
 elseif action=="Equip"then local ok,why=PC.request("Equip",arg);return {Ok=ok,Why=why,View=pets()}
 elseif action=="Followers"then return followers()
 elseif action=="Candidates"then PC.refresh();task.wait(.3);return candidates()
 elseif action=="Egg"then
  require(p.PlayerScripts.Services.MenuClient).close();gui().ShopPanel.Visible=false
  Q.Egg=arg
  local part=require(RS.Modules.Egg).part(arg)
  p.Character:PivotTo(CFrame.new(part.Position+Vector3.new(0,0,9)))
  task.wait(1)
  return candidates()
 elseif action=="Merge"then
  require(p.PlayerScripts.Services.MenuClient).close();gui().ShopPanel.Visible=false
  Q.View:Show();Q.View:SetItemState(arg,true,false);task.wait(.3);return mergeSnap()
 elseif action=="Select"then Q.View:ActivateMaterial(arg);task.wait(.2);return mergeSnap()
 elseif action=="Remove"then Q.View:RemoveMaterial(arg);task.wait(.2);return mergeSnap()
 elseif action=="MergeResult"then Q.View:CompleteItem(arg);task.wait(.2);return mergeSnap()
 elseif action=="MergeTab"then Q.View:SelectTab(arg);task.wait(.2);return mergeSnap()
 elseif action=="HUD"then
  if Q.View then Q.View:Hide()end;require(p.PlayerScripts.Services.MenuClient).close();gui().ShopPanel.Visible=false
  local state=remote:InvokeServer("HUD",arg);task.wait(.4)
  local hud=gui().StrengthLevelHUD;local out={State=state,Icons={},Badge=text(hud.ElementSetBonus.Multiplier)}
  for _,x in ipairs(hud.ItemEffectHUD:GetChildren())do if x:IsA("Frame")then out.Icons[x.Name]={Image=x.IconSlot.Icon.Image,Effect=x.Effect.Text,Visible=x.Visible}end end
  local st=hud.ElementSetBonus.Multiplier:FindFirstChildOfClass("UIStroke");out.Stroke={Color=tostring(st.Color),Width=st.Thickness}
  return out
 elseif action=="Drop"then
  remote:InvokeServer("Drop",arg);task.wait(.5);local rows={}
  for _,g in ipairs(p.PlayerGui:GetChildren())do if g.Name=="PersonalDropReward"then
   rows[#rows+1]={Id=g:GetAttribute("RewardId"),Quantity=g:FindFirstChild("Quantity")~=nil,Points=g:FindFirstChild("Points") and g.Points.Text,Icon=g.Icon.Image}
  end end
  return rows
 elseif action=="RefitShop"then
  for _,o in ipairs(gui().ShopPanel:GetDescendants())do if o:FindFirstChild("PurchasedButtonVisual")then require(RS.Modules.HUDLayout).RefitPurchaseButton(o)end end
  task.wait(.3);return shop()
 end
end
