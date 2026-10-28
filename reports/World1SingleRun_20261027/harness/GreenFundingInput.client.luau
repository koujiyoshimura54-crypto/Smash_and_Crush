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
local function visibleFrame()waitFor(function()return os.clock()-lastRender<.25 end);task.wait(.2);waitFor(function()return os.clock()-lastRender<.2 end)end
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
 virtual:SendMousePosition(pos);task.wait(.12);virtual:SendMouseButton(pos,Enum.UserInputType.MouseButton1,true);task.wait(.12)
 virtual:SendMouseButton(pos,Enum.UserInputType.MouseButton1,false);task.wait(.2)
end
local function inventory()
 if not get('StrengthGui.InventoryPanel').Visible then click('StrengthGui.LeftMenu.InventoryButton')end
 waitFor(function()return get('StrengthGui.InventoryPanel').Visible end)
end

script:SetAttribute('State','Waiting/Running')
local ok,why=xpcall(function()
 visibleFrame()
 assert(p:GetAttribute('EquippedDumbbell')=='NORMAL_07' and p:GetAttribute('RebirthCount')==5)
 control:Invoke('Move',{X=307.8357,Y=11.25,Z=37.6858,Reason='Use surplus100point ore for GreenAura funding'})
 waitFor(function()local g=p.PlayerGui:FindFirstChild('MergeShopGui');return g and g.MergeShopPanel.Visible end)
 click('MergeShopGui.MergeShopPanel.Body.Ore');click('MergeShopGui.MergeShopPanel.Body.Clear')
 for _=1,5 do click('MergeShopGui.MergeShopPanel.Body.Materials.ORE_006.Button')end
 waitFor(function()return Forge.State and Forge.State.Loaded and not Forge.IsPending()end)
 local before=Forge.State.Sequence
 click('MergeShopGui.MergeShopPanel.Body.Merge')
 waitFor(function()return Forge.State and Forge.State.Sequence>before and not Forge.IsPending()end)
 local id=Forge.State.Journal.ResultId;assert(id=='NORMAL_04'or id=='NORMAL_05','Unexpected100point result')
 script:SetAttribute('ResultBell',id)
 click('MergeShopGui.MergeShopPanel.Top.Close');inventory();click('StrengthGui.InventoryPanel.Tabs.Dumbbells')
 local times=id=='NORMAL_04'and 2 or 1
 for _=1,times do
  local count=Forge.State.DumbbellCounts[id]or 0;local win=p:GetAttribute('Win');assert(count>=1 and p:GetAttribute('EquippedDumbbell')~=id)
  click('StrengthGui.InventoryPanel.Content.Dumbbells.Items.'..id..'.SellButton')
  waitFor(function()return(Forge.State.DumbbellCounts[id]or 0)==count-1 and(p:GetAttribute('Win')or 0)>win end)
 end
 assert((p:GetAttribute('Win')or 0)>=500)
 click('StrengthGui.InventoryPanel.Tabs.Aura')
 click('StrengthGui.InventoryPanel.Content.Aura.AuraList.GreenAuraCard.BuyButton')
 waitFor(function()return p:GetAttribute('EquippedAura')=='Green'end)
 click('StrengthGui.InventoryPanel.CloseButton')
 local a=workspace.Treadmills.Gold02.Area.Position
 control:Invoke('Move',{X=a.X,Y=a.Y,Z=a.Z,Reason='Green+07 Gold rebuild toward3.9M Stage8'})
 script:SetAttribute('State','Completed')
end,debug.traceback)
if not ok then script:SetAttribute('State','Failed');script:SetAttribute('Error',tostring(why));warn('[One Green input] '..tostring(why))end
render:Disconnect();finish:Disconnect()
