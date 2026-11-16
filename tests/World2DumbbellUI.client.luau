assert(game.PlaceId==0 and game.ReplicatedStorage:GetAttribute('World2UIFixture'))
local RS=game.ReplicatedStorage
local P=game.Players.LocalPlayer
local report={Checks={}}
local function check(value,name)assert(value,name);table.insert(report.Checks,name)end
local ok,err=xpcall(function()
 local image='rbxassetid://112266643972428'
 local master=require(RS.Config.DumbbellItemMaster)
 check(master.Get('W2_NORMAL_08').Image==image,'Common World2 08 image')
 check(master.Get('NORMAL_08').Image=='rbxassetid://110171141876908','World1 08 unchanged')
 local gui=P.PlayerGui:WaitForChild('StrengthGui',20)
 P.PlayerGui:WaitForChild('ScreenGui',10).Enabled=false
 gui.ShopPanel.Visible=false
 local panel=gui.InventoryPanel;local content=panel.Content;local page=content.Dumbbells
 panel.BackgroundTransparency=1;panel.Visible=true;panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
 panel.Size=UDim2.fromScale(.96,.88);content.Size=UDim2.fromScale(1,1);content.Position=UDim2.new();content.BackgroundTransparency=1
 page.Size=UDim2.fromScale(1,1);page.Position=UDim2.new();page.Visible=true;page.BackgroundTransparency=1
 for _,x in page.Items:GetChildren()do if x:IsA('GuiObject')then x:Destroy()end end
 local inv=require(RS.Modules.DumbbellInventoryView)
 local mounted=inv.Mount(page,gui);local cards={}
 for i=7,9 do local item=master.Get(string.format('W2_NORMAL_%02d',i));local c=inv.CreateCard(page.Items,item,i);c.Visible=true;c.OwnedCount.Text='1';c.SellButton.Visible=false;cards[item.ItemId]=c end
 -- Same shared-master image assignment used by InventoryPanelClient.updateButtons;
 -- this fixture renders the actual view, without loading transactional UI controllers.
 page.Equipped.Preview.Image=master.Get('W2_NORMAL_08').Image;page.Equipped.Multiplier.Text='+1800 STR'
 local function layout()mounted:Layout(cards)end
 page:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout);task.wait(.4);layout()
 local card=cards.W2_NORMAL_08.Icon;local detail=page.Equipped.Preview
 for name,obj in {InventoryCard=card,InventoryDetail=detail}do
  check(obj.Image==image,name..' shared image');check(obj.ScaleType==Enum.ScaleType.Fit,name..' Fit');check(obj.BackgroundTransparency==1,name..' transparent background')
 end
 local Forge=require(RS.Modules.ForgeClient)
 local view=require(RS.Modules.MergeShopView)({RS=RS,gui=gui,Master=require(RS.Config.ItemMaster),
  PetClient={busy=function()return false end,state=function()return {Owned={},Equipped={}}end},Egg=require(RS.Modules.Egg),OnMerge=function()error('Transactions forbidden')end})
 local function candidates()
  panel.Visible=false;view:Show();view:SelectTab('Ore');view:ActivateMaterial('ORE_032');view:ActivateMaterial('ORE_028')
 end
 local function find08()
  for _,x in view.Root:GetDescendants()do if x:GetAttribute('ResultId')=='W2_NORMAL_08'then
   for _,i in x:GetDescendants()do if i:IsA('ImageLabel')and i.Image==image then return i end end
  end end
 end
 candidates();task.wait(.3)
 local candidate=assert(find08(),'08 candidate absent')
 check(candidate.ScaleType==Enum.ScaleType.Fit and candidate.BackgroundTransparency==1,'Merge candidate Fit and transparency')
 Forge.Complete();task.wait(.3)
 local completed=assert(find08(),'08 completed result absent')
 check(completed.ScaleType==Enum.ScaleType.Fit and completed.BackgroundTransparency==1,'Merge completed Fit and transparency')
 local loaded={}
 game.ContentProvider:PreloadAsync({image},function(id,status)loaded[id]=status.Name end)
 task.wait(.3);check(game.ContentProvider:GetAssetFetchStatus(image)==Enum.AssetFetchStatus.Success,'Specified PNG fetch succeeds')
 check(card.IsLoaded and detail.IsLoaded and completed.IsLoaded,'Inventory and merge images loaded')
 report.Image=image;report.Fetch=loaded;report.PreviewDimensions=tostring(detail.AbsoluteSize)
 local action=Instance.new('BindableEvent');action.Name='__World2UIPhase';action.Parent=P.PlayerGui
 local function phase(name)
  if name=='Inventory'then view:Hide();panel.Visible=true;layout()
  elseif name=='Candidates'then candidates()
  elseif name=='Completed'then candidates();Forge.Complete()
  end
  P.PlayerGui:SetAttribute('FixturePhase',name)
 end
 action.Event:Connect(phase);phase('Inventory')
 P.PlayerGui:SetAttribute('FixtureUIReady',true)
end,debug.traceback)
report.Passed=ok;report.Error=not ok and err or nil
RS:WaitForChild('__World2UIResult'):FireServer(report)
