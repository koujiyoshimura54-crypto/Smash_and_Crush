-- Temporary native fixture; requires isolated memory services, never production data.
local RS=game.ReplicatedStorage
local Q=RS:WaitForChild("__AutoJoinQA")
local RF=Q.Call
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Auto=require(game.ServerScriptService.Services.AutoTapService)
local Memory=require(RS.__EarlyQAMemory)
local report={Checks={},Profiles={},InitialObservations={},Input="Native clients through existing game Remotes; no OS input"}
local function waitFor(fn,t)
 local endAt=os.clock()+(t or 15)
 repeat local v=fn();if v then return v end;task.wait(.03) until os.clock()>endAt
 error("AutoJoin QA timeout")
end
local function check(name,ok,evidence)
 table.insert(report.Checks,{Name=name,Passed=not not ok,Evidence=evidence})
 assert(ok,name)
end
local function ask(p,action,arg)
 local r=RF:InvokeClient(p,action,arg)
 assert(r.OK,r.Error)
 return r.Value
end
local function state(p)
 local s=Data.Get(p)
 return {Enabled=Data.IsAutoTapEnabled(p),Attribute=p:GetAttribute("AutoTapEnabled"),StoredSession=s and s.Loaded and s.Data.AutoTapEnabled,
 Strength=p:GetAttribute("Strength"),World=p:GetAttribute("CurrentWorld")}
end
local seen={}
local watch=game:GetService("RunService").Heartbeat:Connect(function()
 for _,p in game.Players:GetPlayers() do
  local s=Data.Get(p);local row=seen[p] or {LoadingSamples=0,LoadingEnabled=false,BeforeInputEnabled=false};seen[p]=row
  if not s or not s.Loaded then row.LoadingSamples+=1;row.LoadingEnabled=row.LoadingEnabled or Data.IsAutoTapEnabled(p) end
  if not Q:GetAttribute("InputsStarted") then row.BeforeInputEnabled=row.BeforeInputEnabled or p:GetAttribute("AutoTapEnabled")==true end
 end
end)
local function settled(p)
 return waitFor(function()
  local s=Data.Get(p);local c=p.Character
  return s and s.Loaded and c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")
   and c.Humanoid.Health>0 and c:GetAttribute("LobbySpawnPlaced") and not c.HumanoidRootPart.Anchored and s
 end,50)
end
local function death(p,expected)
 local old=p.Character;old.Humanoid.Health=0
 waitFor(function()return p.Character~=old end,20);settled(p);task.wait(.4)
 local ui=ask(p,"Status")
 check("Respawn retains "..tostring(expected),Data.IsAutoTapEnabled(p)==expected and ui.Text==(expected and "ON" or "OFF"),ui)
end
local function travel(p,target,expected)
 local Contact=require(RS.Modules.WorldGateContact)
 local Placement=require(game.ServerScriptService.Services.LobbySpawnService)
 local w=p:GetAttribute("CurrentWorld")==2 and 2 or 1
 local wall=Contact.Wall(w);local floor=select(2,Placement.GetLobby(w))
 local c=p.Character;local r=c.HumanoidRootPart
 local pos=wall.CFrame:PointToWorldSpace(Vector3.new(0,0,8))
 pos=Vector3.new(pos.X,floor.Position.Y+floor.Size.Y/2+Placement.GetRootClearance(p,c)+.15,pos.Z)
 c:PivotTo(CFrame.lookAt(pos,Vector3.new(wall.Position.X,pos.Y,wall.Position.Z))*r.CFrame:ToObjectSpace(c:GetPivot()))
 r.AssemblyLinearVelocity=Vector3.zero
 local ui=ask(p,"Travel",target)
 check("World travel retains "..tostring(expected),p:GetAttribute("CurrentWorld")==target and Data.IsAutoTapEnabled(p)==expected and ui.Text==(expected and "ON" or "OFF"),ui)
end
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==3 end,60)
 local ps=game.Players:GetPlayers();table.sort(ps,function(a,b)return a.UserId>b.UserId end)
 for _,p in ps do settled(p) end
 task.wait(.5)
 for _,p in ps do
  local ui=ask(p,"Status");local s=state(p);local initial=seen[p]
  table.insert(report.InitialObservations,{Profile=p.UserId,Server=initial,Client=ui})
  local expected=p.UserId==-2 and 11 or (p.UserId==-3 and (Q:GetAttribute("SavedStrength") or 23) or 0)
  check("Join OFF profile "..p.UserId,s.Enabled==false and s.Attribute==false and s.StoredSession==false and ui.Text=="OFF" and not ui.SawOnBeforeInput,s)
  check("Loading OFF profile "..p.UserId,initial.LoadingSamples>0 and not initial.LoadingEnabled and not initial.BeforeInputEnabled,initial)
  check("No initial automatic gain "..p.UserId,s.Strength==expected,s)
 end
 if Q:GetAttribute("RejoinOnly") then return end
 Q:SetAttribute("InputsStarted",true)
 for _,p in ps do
  local before=p:GetAttribute("Strength");local walk=ask(p,"Walk")
  check("OFF walking no gain "..p.UserId,p:GetAttribute("Strength")==before and walk.Distance>2,walk)
  local ui=ask(p,"Toggle")
  check("Toggle ON "..p.UserId,Data.IsAutoTapEnabled(p) and ui.Text=="ON",ui)
  task.wait(.3);before=p:GetAttribute("Strength");ask(p,"Tap");task.wait(.2)
  check("Manual while ON "..p.UserId,p:GetAttribute("Strength")==before+1,{Before=before,After=p:GetAttribute("Strength")})
  task.wait(.7);before=p:GetAttribute("Strength");task.wait(.7)
  check("Stationary ON no gain "..p.UserId,p:GetAttribute("Strength")==before)
  walk=ask(p,"Walk")
  check("ON walking gains "..p.UserId,p:GetAttribute("Strength")>before and walk.Distance>2,{Walk=walk,Delta=p:GetAttribute("Strength")-before})
  ui=ask(p,"Toggle")
  check("Toggle OFF "..p.UserId,not Data.IsAutoTapEnabled(p) and ui.Text=="OFF",ui)
 end
 local p=ps[1]
 ask(p,"Toggle");local same=Data.Get(p);assert(Data.Load(p))
 check("Repeated Load within same session keeps ON",same==Data.Get(p) and Data.IsAutoTapEnabled(p))
 death(p,true)
 assert(Data.UnlockWorld(p,2));travel(p,2,true)
 ask(p,"Toggle");death(p,false);travel(p,1,false)
 -- Confirm an actual ON save, then reload that exact isolated record.
 local previous=ps[3];ask(previous,"Toggle")
 Data.WaitForSave(previous,10);assert(Data.Save(previous))
 local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
 local raw=store:GetAsync("Player_"..previous.UserId)
 check("Memory save retains ON as legacy field",raw.AutoTapEnabled==true)
 local strength=previous:GetAttribute("Strength")
 Data.Release(previous);Memory.Delay=.5
 check("Unloaded authority OFF",Data.IsAutoTapEnabled(previous)==false)
 assert(Data.Load(previous));Memory.Delay=0
 local ui=ask(previous,"Status")
 check("Saved ON new session reload OFF",not Data.IsAutoTapEnabled(previous) and ui.Text=="OFF" and previous:GetAttribute("Strength")==strength,ui)
 for _,person in ps do table.insert(report.Profiles,{Profile=person.UserId,State=state(person),UI=ask(person,"Status")}) end
end,debug.traceback)
watch:Disconnect()
report.Passed=ok;report.Error=not ok and err or nil
Q:SetAttribute("Result",game:GetService("HttpService"):JSONEncode(report))
Q:SetAttribute("Completed",true)
print("[AutoJoinQA] "..(ok and "PASS" or tostring(err)))
while Q:GetAttribute("Hold")==true do task.wait(.1) end
game:GetService("StudioTestService"):EndTest(game:GetService("HttpService"):JSONEncode(report))
