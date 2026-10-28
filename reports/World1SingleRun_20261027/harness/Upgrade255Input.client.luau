-- Temporary input macro for ONE already chosen in-run decision. No gameplay calls.
local p=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local virtual=assert(game.UserInputService:CreateVirtualInput())
local Forge=require(RS.Modules.ForgeClient)
local control=p.PlayerScripts.__OneControl
local lastRender=-math.huge
local cancelled=false
local render=game.RunService.RenderStepped:Connect(function()lastRender=os.clock()end)
local finish=RS.__OneMeasure.OnClientEvent:Connect(function(op)if op=='Finished'then cancelled=true end end)
local deadline=os.clock()+1200
local function waitFor(fn)
 repeat assert(not cancelled and script.Parent and os.clock()<deadline,'Input macro ended/timed out');if fn()then return end;task.wait(.1)until false
end
local function visibleFrame()waitFor(function()return os.clock()-lastRender<.25 end)end
local function get(path)
 local o=p.PlayerGui;for _,n in string.split(path,'.')do o=assert(o:FindFirstChild(n),n)end;return o
end
local function click(path)
 script:SetAttribute('Step',path);visibleFrame()
 local o=get(path);local a=o
 while a and a~=p.PlayerGui do if a:IsA('GuiObject')then assert(a.Visible,'Hidden '..path)end;a=a.Parent end
 local sc=o:FindFirstAncestorWhichIsA('ScrollingFrame')
 if sc then for _=1,30 do
  visibleFrame();local center=o.AbsolutePosition+o.AbsoluteSize/2
  if center.Y>sc.AbsolutePosition.Y+3 and center.Y<sc.AbsolutePosition.Y+sc.AbsoluteSize.Y-3 then break end
  local pos=sc.AbsolutePosition+sc.AbsoluteSize/2+game.GuiService:GetGuiInset()
  virtual:SendMousePosition(pos);virtual:SendPointerAction(pos,{Wheel=center.Y<sc.AbsolutePosition.Y and 3 or -3});task.wait(.15)
 end end
 visibleFrame();local pos=o.AbsolutePosition+o.AbsoluteSize/2+game.GuiService:GetGuiInset()
 assert(pos.Y>=0 and pos.Y<workspace.CurrentCamera.ViewportSize.Y,'Offscreen '..path)
 virtual:SendMousePosition(pos);virtual:SendMouseButton(pos,Enum.UserInputType.MouseButton1,true);task.wait(.12)
 virtual:SendMouseButton(pos,Enum.UserInputType.MouseButton1,false);task.wait(.2)
end
local function inventory()
 if not get('StrengthGui.InventoryPanel').Visible then click('StrengthGui.LeftMenu.InventoryButton')end
 waitFor(function()return get('StrengthGui.InventoryPanel').Visible end)
end

script:SetAttribute('State','Waiting/Running')
local ok,why=xpcall(function()
 control:Invoke('Move',{X=284.2148,Y=12,Z=-40.7021,Reason='Use current Iron while waiting for rendering, no desktop input'})
 visibleFrame()
 inventory();click('StrengthGui.InventoryPanel.Tabs.Items')
 click('StrengthGui.InventoryPanel.Content.Items.RarityTabs.Star3')
 waitFor(function()return get('StrengthGui.InventoryPanel.Content.Items.OwnedItems'):FindFirstChild('PROTEIN_RARE_ICE')end)
 click('StrengthGui.InventoryPanel.Content.Items.OwnedItems.PROTEIN_RARE_ICE.EquipButton')
 waitFor(function()local c=get('StrengthGui.InventoryPanel.Content.Items.OwnedItems'):FindFirstChild('PROTEIN_RARE_ICE');return c and c:FindFirstChild('EquippedStatus')end)
 click('StrengthGui.InventoryPanel.CloseButton')
 control:Invoke('Move',{X=307.8357,Y=11.25,Z=37.6858,Reason='Chosen255point forge, ordinary walk'})
 waitFor(function()local g=p.PlayerGui:FindFirstChild('MergeShopGui');return g and g.MergeShopPanel.Visible end)
 click('MergeShopGui.MergeShopPanel.Body.Ore');click('MergeShopGui.MergeShopPanel.Body.Clear')
 for _,id in {'ORE_014','ORE_013','ORE_009','ORE_008','ORE_008'}do click('MergeShopGui.MergeShopPanel.Body.Materials.'..id..'.Button')end
 waitFor(function()return Forge.State and Forge.State.Loaded and not Forge.IsPending()end)
 local before=Forge.State.Sequence
 click('MergeShopGui.MergeShopPanel.Body.Merge')
 waitFor(function()return Forge.State and Forge.State.Sequence>before and not Forge.IsPending()end)
 local best='';for id,n in Forge.State.DumbbellCounts do if id:match('^NORMAL_%d%d$')and n>0 and id>best then best=id end end
 assert(best=='NORMAL_07'or best=='NORMAL_08','Unexpected result '..best);script:SetAttribute('ResultBell',best)
 click('MergeShopGui.MergeShopPanel.Top.Close');inventory();click('StrengthGui.InventoryPanel.Tabs.Dumbbells')
 click('StrengthGui.InventoryPanel.Content.Dumbbells.Items.'..best..'.BuyButton')
 waitFor(function()return p:GetAttribute('EquippedDumbbell')==best end)
 local count=Forge.State.DumbbellCounts.NORMAL_05 or 0;local win=p:GetAttribute('Win')
 assert(count>=1)
 click('StrengthGui.InventoryPanel.Content.Dumbbells.Items.NORMAL_05.SellButton')
 waitFor(function()return(p:GetAttribute('Win')or 0)>=win+125 and(Forge.State.DumbbellCounts.NORMAL_05 or 0)==count-1 end)
 script:SetAttribute('SaleWin',p:GetAttribute('Win')-win)
 click('StrengthGui.InventoryPanel.CloseButton')
 assert(p:GetAttribute('RebirthCount')==4 and(p:GetAttribute('Level')or 0)>=45)
 if not get('StrengthGui.RebirthPanel').Visible then click('StrengthGui.LeftMenu.RebirthButton')end
 waitFor(function()return get('StrengthGui.RebirthPanel').Visible end)
 click('StrengthGui.RebirthPanel.RebirthConfirmButton');waitFor(function()return p:GetAttribute('RebirthCount')==5 end)
 click('StrengthGui.RebirthPanel.Top.Close')
 local a=workspace.Treadmills.Gold02.Area.Position
 control:Invoke('Move',{X=a.X,Y=a.Y,Z=a.Z,Reason='R5 Gold rebuild, compare measured gain for next Stage8'})
 script:SetAttribute('State','Completed')
end,debug.traceback)
if not ok then script:SetAttribute('State','Failed');script:SetAttribute('Error',tostring(why));warn('[One255point input] '..tostring(why))end
render:Disconnect();finish:Disconnect()
