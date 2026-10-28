-- Temporary normal-input automation for the selected R5/Gold decision, exactly once.
local p=game.Players.LocalPlayer
local v=assert(game.UserInputService:CreateVirtualInput())
local last=-math.huge
local stopped=false
local deadline=os.clock()+1200
local r=game.RunService.RenderStepped:Connect(function()last=os.clock()end)
local f=game.ReplicatedStorage.__OneMeasure.OnClientEvent:Connect(function(op)if op=='Finished'then stopped=true end end)
local function waitFor(fn)
 repeat assert(not stopped and script.Parent and os.clock()<deadline,'Gold input ended/timed out');if fn()then return end;task.wait(.1)until false
end
local function get(path)local o=p.PlayerGui;for _,n in string.split(path,'.')do o=assert(o:FindFirstChild(n),n)end;return o end
local function click(path)
 script:SetAttribute('Step',path);waitFor(function()return os.clock()-last<.25 end)
 local b=get(path);local q=b;while q and q~=p.PlayerGui do if q:IsA('GuiObject')then assert(q.Visible,'Hidden target')end;q=q.Parent end
 local pos=b.AbsolutePosition+b.AbsoluteSize/2+game.GuiService:GetGuiInset()
 v:SendMousePosition(pos);v:SendMouseButton(pos,Enum.UserInputType.MouseButton1,true);task.wait(.12);v:SendMouseButton(pos,Enum.UserInputType.MouseButton1,false);task.wait(.2)
end
script:SetAttribute('State','Awaiting LV45 / rendered input')
local ok,why=xpcall(function()
 assert(p:GetAttribute('RebirthCount')==4)
 waitFor(function()return (p:GetAttribute('Level')or 0)>=45 end)
 if not get('StrengthGui.RebirthPanel').Visible then click('StrengthGui.LeftMenu.RebirthButton')end
 waitFor(function()return get('StrengthGui.RebirthPanel').Visible end)
 click('StrengthGui.RebirthPanel.RebirthConfirmButton')
 waitFor(function()return p:GetAttribute('RebirthCount')==5 end)
 click('StrengthGui.RebirthPanel.Top.Close')
 local a=workspace.Treadmills.Gold02.Area.Position
 p.PlayerScripts.__OneControl:Invoke('Move',{X=a.X,Y=a.Y,Z=a.Z,Reason='R5 legitimately unlocks Gold02; train toward Stage7 short fight'})
 script:SetAttribute('State','Completed')
end,debug.traceback)
if not ok then script:SetAttribute('State','Failed');script:SetAttribute('Error',tostring(why))end
r:Disconnect();f:Disconnect()
