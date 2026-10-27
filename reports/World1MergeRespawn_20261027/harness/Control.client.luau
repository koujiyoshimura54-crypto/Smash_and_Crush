-- Ordinary movement + read-only UI discovery. No gameplay RemoteFunction/service invocation.
local p=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local measure=RS:WaitForChild('__AdaptiveMeasure')
local bridge=Instance.new('BindableFunction');bridge.Name='__AdaptiveControl';bridge.Parent=p.PlayerScripts
local generation=0
local moving=false
task.spawn(function()
 while true do
  local gui=p:FindFirstChild('PlayerGui');local strength=gui and gui:FindFirstChild('StrengthGui')
  local hud=strength and strength:FindFirstChild('StrengthLevelHUD');local panel=hud and hud:FindFirstChild('LevelPanel')
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  local humanoid=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if panel and panel:FindFirstChild('AutoTapButton')and root and humanoid and humanoid.Health>0 and type(p:GetAttribute('Strength'))=='number'then break end
  task.wait(.05)
 end
 game:GetService('RunService').RenderStepped:Wait()
 measure:FireServer('Start',{ClientUTC=DateTime.now().UnixTimestampMillis/1000})
end)
local function visible(x)
 local q=x
 while q and q~=p.PlayerGui do
  if q:IsA('GuiObject')and not q.Visible or q:IsA('ScreenGui')and not q.Enabled then return false end;q=q.Parent
 end
 return true
end
local function rect(x)return {x.AbsolutePosition.X,x.AbsolutePosition.Y,x.AbsoluteSize.X,x.AbsoluteSize.Y}end
bridge.OnInvoke=function(op,arg)
 if op=='Start' then measure:FireServer('Start');return true end
 if op=='Phase' then measure:FireServer('Phase',arg.Phase,arg.Reason);return true end
 local function stop()
  generation+=1;moving=false
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  if h and root then h:MoveTo(root.Position);h:Move(Vector3.zero,false) end
 end
 if op=='Move' then
  assert(type(arg)=='table' and type(arg.X)=='number' and type(arg.Y)=='number' and type(arg.Z)=='number','Move requires numeric X/Y/Z')
  for _,n in {arg.X,arg.Y,arg.Z} do assert(n==n and math.abs(n)<100000,'Invalid coordinate') end
  stop();local own=generation;moving=true
  local character=p.Character;local h=character and character:FindFirstChildOfClass('Humanoid');assert(h and h.Health>0)
  local destination=Vector3.new(arg.X,arg.Y,arg.Z)
  measure:FireServer('Phase','movement',arg.Reason or 'Ordinary Humanoid MoveTo')
  task.spawn(function()
   local began=os.clock();local last=character.HumanoidRootPart.Position;local previousStage=p:GetAttribute('CurrentStage') or 1;local world=p:GetAttribute('CurrentWorld')
   while generation==own and p.Character==character and h.Health>0 and os.clock()-began<60 do
    local root=character:FindFirstChild('HumanoidRootPart');if not root then break end
    local stage=p:GetAttribute('CurrentStage') or 1
    if (root.Position-last).Magnitude>math.max(30,h.WalkSpeed*.7) or stage<previousStage or p:GetAttribute('CurrentWorld')~=world then break end
    if (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(destination.X,0,destination.Z)).Magnitude<2 then break end
    h:MoveTo(destination);last=root.Position;previousStage=stage;task.wait(.25)
   end
   if generation==own then stop() end
  end);return true
 end
 if op=='StopMove' then stop();return true end
 if op=='Jump' then local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if h then h.Jump=true end;return true end
 if op=='UI' then
  local out={};for _,x in p.PlayerGui:GetDescendants()do
   if x:IsA('GuiButton')and visible(x)and x.AbsoluteSize.X>2 and x.AbsoluteSize.Y>2 then
    local texts={};if x:IsA('TextButton')and x.Text~=''then table.insert(texts,x.Text)end
    for _,v in x:GetDescendants()do if v:IsA('TextLabel')and visible(v)and v.Text~=''then table.insert(texts,v.Text)end end
    table.insert(out,{Path=x:GetFullName(),Text=table.concat(texts,' / '),Bounds=rect(x),Enabled=x.Interactable})
   end
  end;return out
 end
 if op=='Status' then
  local c=p.Character;local r=c and c:FindFirstChild('HumanoidRootPart');local cam=workspace.CurrentCamera
  return {Moving=moving,Position=r and {r.Position.X,r.Position.Y,r.Position.Z},Viewport={cam.ViewportSize.X,cam.ViewportSize.Y},
   Inset=tostring(game.GuiService:GetGuiInset()),Loaded=p:GetAttribute('DataLoaded'),Strength=p:GetAttribute('Strength'),Stage=p:GetAttribute('CurrentStage')}
 end
 error('Unknown measurement/control operation')
end
for _,remote in RS:WaitForChild('Remotes'):GetChildren()do
 if remote:IsA('RemoteEvent')and (remote.Name:find('Enemy')or remote.Name:find('Drop')or remote.Name:find('Merge')or remote.Name:find('Trophy'))then
  remote.OnClientEvent:Connect(function(data)
   if type(data)=='table'and data.Type~='Gauge'and data.Type~='Fighting'and data.Type~='WallGauge'then measure:FireServer('ClientEvent',{Remote=remote.Name,Data=data})end
  end)
 end
end

-- External lifecycle observer survives the target LocalScript's destruction.
local observations={};local firstScript,firstGui,firstHost
local function observe(why)
 local pg=p:FindFirstChild('PlayerGui');local folder=pg and pg:FindFirstChild('StrengthUI');local panel=folder and folder:FindFirstChild('MergePanel_New')
 local gui=pg and pg:FindFirstChild('StrengthGui');local target=(p.PlayerScripts:FindFirstChild('UI') and p.PlayerScripts.UI:FindFirstChild('MergePanelClient_New')) or (gui and gui:FindFirstChild('MergePanelClient_New')) or (panel and panel:FindFirstChild('MergePanelClient_New'));local host=pg and pg:FindFirstChild('MergeShopGui')
 firstScript=firstScript or target;firstGui=firstGui or gui;firstHost=firstHost or host
 table.insert(observations,{Time=os.clock(),Reason=why,ScriptExists=target~=nil,SameScript=target==firstScript,OldScriptParent=firstScript and firstScript.Parent~=nil,SameGui=gui==firstGui,SameHost=host==firstHost,Mounted=gui and gui:GetAttribute('MergeShopMounted'),HostExists=host~=nil})
end
local trace=Instance.new('BindableFunction');trace.Name='__AdaptiveLifecycle';trace.Parent=p.PlayerScripts
trace.OnInvoke=function()observe('Read');return observations end
p.CharacterRemoving:Connect(function()generation+=1;moving=false;observe('CharacterRemoving')end)
p.CharacterAdded:Connect(function()task.delay(.5,function()observe('Respawn +0.5')end);task.delay(2,function()observe('Respawn +2')end)end)
task.delay(3,function()observe('Initial')end)
