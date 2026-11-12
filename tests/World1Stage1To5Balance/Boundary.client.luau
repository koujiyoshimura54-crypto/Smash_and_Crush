-- Native client probes for a separate, explicitly injected boundary session.
local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer
local q=RS:WaitForChild("__W1BalanceBoundary")
local packets={};local replies={}
RS.Remotes.RebirthRequest.OnClientEvent:Connect(function(r)table.insert(replies,r)end)
for w=1,2 do
 RS.Remotes.GameRemotes:WaitForChild(w==1 and "CombatState"or"World2CombatState").OnClientEvent:Connect(function(r)
  if r.Type=="BossGauge"or r.Type=="BossInitialize"then packets[w]=packets[w]or{};packets[w][r.Stage]=r end
 end)
end
local function status()
 local gui=p.PlayerGui.StrengthGui;local bar=gui.StrengthLevelHUD.LevelPanel.StrengthProgressBar
 local panel=gui.RebirthPanel
 return {Level=p:GetAttribute("Level"),Progress=p:GetAttribute("LevelProgress"),Curve=p:GetAttribute("LevelCurveVersion"),
  Strength=p:GetAttribute("Strength"),Auto=p:GetAttribute("AutoTapEnabled"),Rebirth=p:GetAttribute("RebirthCount"),
  LevelText=bar.Level.Text,ProgressText=bar.Exp.Text,RequiredText=panel.RebirthProgress.Text,
  RebirthEnabled=panel.RebirthConfirmButton.Active,RebirthReplies=table.clone(replies),
  TutorialTarget=workspace:FindFirstChild("TutorialFloorGuide")and workspace.TutorialFloorGuide:GetAttribute("Target"),
  Viewport=tostring(workspace.CurrentCamera.ViewportSize),Orientation=tostring(p.PlayerGui.CurrentScreenOrientation)}
end
q.Call.OnClientInvoke=function(action,value)
 if action=="State"then task.wait(.2);return status()end
 if action=="Rebirth"then
  for i=1,(value or 1)do RS.Remotes.RebirthRequest:FireServer("Request")end
  task.wait(.3);return status()
 end
 if action=="Tap"then RS.Remotes.AutoTapRequest:FireServer("Tap");task.wait(.3);return status()end
 if action=="Auto"then
  if p:GetAttribute("AutoTapEnabled")~=value then RS.Remotes.AutoTapRequest:FireServer("Toggle")end
  task.wait(.2);return status()
 end
 if action=="Fight"then
  local w,n=value.World,value.Stage
  local char=p.Character;local h=char.Humanoid;local root=char.HumanoidRootPart
  local folder=workspace[w==1 and"Enemies"or"World2Enemies"]
  local started=os.clock();local nextTap=0;local traces={};local last
  while os.clock()-started<15 and p.Character==char and h.Health>0 do
   local owner=folder:FindFirstChild("Owner_"..p.UserId)
   local actor=owner and owner:FindFirstChild(("Stage%02d_Enemy"):format(n))
   if not actor then break end
   local bossRoot=actor:FindFirstChild("HumanoidRootPart")
   if bossRoot then h:MoveTo(Vector3.new(bossRoot.Position.X,root.Position.Y,bossRoot.Position.Z))end
   if value.Mode=="Manual"and os.clock()>=nextTap then RS.Remotes.AutoTapRequest:FireServer("Tap");nextTap=os.clock()+.25 end
   local packet=packets[w]and packets[w][n]
   if packet and packet.Current~=last then
    table.insert(traces,{At=os.clock()-started,HP=packet.Current,Max=packet.Max,Health=h.Health});last=packet.Current
   end
   task.wait(.025)
  end
  if h.Health>0 then h:MoveTo(root.Position)end
  return {Seconds=os.clock()-started,Health=h.Health,Traces=traces,State=status()}
 end
 if action=="Back"then
  for i=1,(value or 1)do RS.Remotes.RunReturn:FireServer(p:GetAttribute("RunInventoryId"))end
  task.wait(1);return status()
 end
 error("Unknown boundary client action")
end
