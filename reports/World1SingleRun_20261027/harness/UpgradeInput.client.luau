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
 inventory();click('StrengthGui.InventoryPanel.Tabs.Aura')
 if p:GetAttribute('EquippedAura')~='Yellow'then
  assert((p:GetAttribute('Win')or 0)>=200,'Yellow budget changed')
  click('StrengthGui.InventoryPanel.Content.Aura.AuraList.YellowAuraCard.BuyButton')
  waitFor(function()return p:GetAttribute('EquippedAura')=='Yellow'end)
 end
 click('StrengthGui.InventoryPanel.CloseButton')
 control:Invoke('Move',{X=307.8357,Y=11.25,Z=37.6858,Reason='Chosen130point forge; ordinary approach'})
 waitFor(function()local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');return root and (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(307.8357,0,37.6858)).Magnitude<2 end)
 waitFor(function()local g=p.PlayerGui:FindFirstChild('MergeShopGui');return g and g.MergeShopPanel.Visible end)
 click('MergeShopGui.MergeShopPanel.Body.Ore');click('MergeShopGui.MergeShopPanel.Body.Clear')
 for _,id in {'ORE_010','ORE_008','ORE_006','ORE_006','ORE_006'}do click('MergeShopGui.MergeShopPanel.Body.Materials.'..id..'.Button')end
 waitFor(function()return Forge.State and Forge.State.Loaded and not Forge.IsPending()end)
 local before=Forge.State.Sequence
 click('MergeShopGui.MergeShopPanel.Body.Merge')
 waitFor(function()return Forge.State and Forge.State.Sequence>before and not Forge.IsPending()end)
 local best='';for id,n in Forge.State.DumbbellCounts do if id:match('^NORMAL_%d%d$')and n>0 and id>best then best=id end end
 assert(best~='');script:SetAttribute('ResultBell',best)
 click('MergeShopGui.MergeShopPanel.Top.Close');inventory();click('StrengthGui.InventoryPanel.Tabs.Dumbbells')
 click('StrengthGui.InventoryPanel.Content.Dumbbells.Items.'..best..'.BuyButton')
 waitFor(function()return p:GetAttribute('EquippedDumbbell')==best end)
 click('StrengthGui.InventoryPanel.CloseButton')
 if (p:GetAttribute('Strength')or 0)<1100000 and p:GetAttribute('RebirthCount')==3 then
  click('StrengthGui.LeftMenu.RebirthButton');click('StrengthGui.RebirthPanel.RebirthConfirmButton')
  waitFor(function()return p:GetAttribute('RebirthCount')==4 end)
  click('StrengthGui.RebirthPanel.Top.Close')
 end
 control:Invoke('Move',{X=284.2148,Y=12,Z=-40.7021,Reason='Rebuild toward Gold or Stage7; reassess actual result'})
 script:SetAttribute('State','Completed')
end,debug.traceback)
if not ok then script:SetAttribute('State','Failed');script:SetAttribute('Error',tostring(why));warn('[One input macro] '..tostring(why))end
render:Disconnect();finish:Disconnect()
