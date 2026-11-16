assert(game.PlaceId==0 and game.ReplicatedStorage:GetAttribute("BodyDumbbellFixture")==true)
local P=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local Run=game:GetService("RunService")
local control=RS:WaitForChild("__BodyDumbbellControl",40)
local observer=RS:WaitForChild("__BodyDumbbellObserver",40)
local function displays(c)
 local rows={};if c then for _,x in c:GetChildren()do if x.Name=="TrainingDumbbellRight"or x.Name=="TrainingDumbbellLeft"then table.insert(rows,{Name=x.Name,ItemId=x:GetAttribute("ItemId")})end end end;return rows
end
observer.OnClientInvoke=function()local rows={};for _,p in game.Players:GetPlayers()do table.insert(rows,{Index=p:GetAttribute("FixtureIndex"),Displays=displays(p.Character)})end;return rows end
local function waitFor(fn,seconds)
 local finish=os.clock()+seconds
 repeat if fn()then return true end task.wait(.05)until os.clock()>finish
 return false
end
local function ready()
 local c=P.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 return c and r and h and h.Health>0 and c:GetAttribute("SpawnEngineReady")and c:GetAttribute("MuscleScaleReady")and c:GetAttribute("LobbySpawnPlaced")and not r.Anchored
end
if not waitFor(ready,60)then
 RS:WaitForChild("__BodyDumbbellResults"):FireServer({Passed=false,FixtureFailure="Actual character loading / placement did not become ready",Attributes=P.Character and P.Character:GetAttributes()})
 return
end
if P:GetAttribute("FixtureIndex")~=1 then return end
local controls=require(P.PlayerScripts:WaitForChild("PlayerModule",20)):GetControls();controls:Disable()
local input=Vector3.zero
Run:BindToRenderStep("__BodyDumbbellInput",Enum.RenderPriority.Input.Value+1,function()
 local c=P.Character;local h=c and c:FindFirstChildOfClass("Humanoid");if h then h:Move(input,false)end
end)
local report={Checks={},Measurements={},Training={},Snapshots={}}
local function check(value,name,details)table.insert(report.Checks,{Name=name,Passed=value==true,Details=details});print("BODY_DIAG_CHECK",name,value)end
local function rig()local c=P.Character;return c,c.Humanoid,c.HumanoidRootPart end
local function settle()
 local _,h,r=rig();local stable=0;local start=os.clock()
 local ok=waitFor(function()
  local state=h:GetState()
  local good=not r.Anchored and math.abs(r.AssemblyLinearVelocity.Y)<.5 and state~=Enum.HumanoidStateType.Freefall and state~=Enum.HumanoidStateType.Jumping
  stable=good and stable+1 or 0;return stable>=10
 end,6)
 return {OK=ok,Seconds=os.clock()-start,State=h:GetState().Name,Floor=h.FloorMaterial.Name,Velocity=tostring(r.AssemblyLinearVelocity),Root=tostring(r.Position)}
end
local function place(x,z,top)
 input=Vector3.zero;local c,h,r=rig()
 c:PivotTo(CFrame.new(x,top+h.HipHeight+r.Size.Y/2+.18,z)*r.CFrame:ToObjectSpace(c:GetPivot()))
 r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
 return settle()
end
local function equip(id)assert(control:InvokeServer("Equip",id));task.wait(.5)end
local comparison=RS:WaitForChild("BodyComparison",30):WaitForChild("Request",15)
local request=1000;local response
comparison.OnClientEvent:Connect(function(r)if r.RequestId==request and (r.Code=="Success"or r.Code=="Failed"or r.Code=="Unavailable")then response=r end end)
local function body(setting)
 input=Vector3.zero;control:InvokeServer("Stop");request+=1;response=nil
 if RS:GetAttribute("FixtureVariant")=="legacy_transition"then
  local _,h,r=rig();h.RequiresNeck=false;r.Anchored=true
  assert(control:InvokeServer("LegacyBody",setting));task.wait(.5)
  control:InvokeServer("LegacyRelease");r.Anchored=false;h.RequiresNeck=true
  return
 end
 setting.Height=setting.Height or 1;setting.Thickness=setting.Thickness or 1
 comparison:FireServer({Id=request,Action="Set",Settings=setting,Character=P.Character})
 assert(waitFor(function()return response~=nil end,12),"Body comparison response timed out")
 assert(response.Code=="Success",response.Code..":"..tostring(response.Message))
 assert(waitFor(ready,8),"Body transition did not release")
 task.wait(.5)
end
local function measure(name,trial)
 local settled=place(310,60,4);local c,h,r=rig()
 assert(settled.OK,"Walking fixture did not settle")
 input=Vector3.new(0,0,-1);task.wait(1)
 local start=r.Position;local began=os.clock();local samples={};local simdt=0;local nextSample=0
 repeat
  local dt=Run.Heartbeat:Wait();simdt+=dt
  if os.clock()>=nextSample then nextSample=os.clock()+.1;table.insert(samples,{Time=os.clock()-began,Position={r.Position.X,r.Position.Y,r.Position.Z},Velocity={r.AssemblyLinearVelocity.X,r.AssemblyLinearVelocity.Y,r.AssemblyLinearVelocity.Z},State=h:GetState().Name,Floor=h.FloorMaterial.Name,Move={h.MoveDirection.X,h.MoveDirection.Y,h.MoveDirection.Z}})end
 until os.clock()-began>=2
 local duration=os.clock()-began;local delta=r.Position-start;input=Vector3.zero
 local row={Name=name,Trial=trial,Speed=Vector3.new(delta.X,0,delta.Z).Magnitude/duration,Seconds=duration,HeartbeatSeconds=simdt,WalkSpeed=h.WalkSpeed,HipHeight=h.HipHeight,Mass=r.AssemblyMass,Settled=settled,Samples=samples}
 table.insert(report.Measurements,row);print("BODY_DIAG_SPEED",name,trial,row.Speed,row.Mass,settled.OK)
 settle();local y=r.Position.Y;h.Jump=true
 local peak=y;local finish=os.clock()+1.4
 repeat Run.Heartbeat:Wait();peak=math.max(peak,r.Position.Y)until os.clock()>=finish
 row.JumpRise=peak-y;row.AfterJump=settle()
 return row
end
local function treadmill(world,name)
 input=Vector3.zero;assert(control:InvokeServer("World",world));assert(waitFor(ready,10))
 local m=world==2 and workspace.World2Map.TrainingArea.TreadmillDisplays["01"]or workspace.Treadmills.Normal01
 local a=m.Area;local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={m};params.RespectCanCollide=true
 local hit=workspace:Raycast(a.Position+Vector3.new(0,50,0),Vector3.new(0,-100,0),params);assert(hit,"Actual treadmill deck missing")
 local settled=place(a.Position.X,a.Position.Z,hit.Position.Y)
 assert(settled.OK,"Treadmill fixture did not settle")
 local before=control:InvokeServer("Snapshot",world)
 local started=control:InvokeServer("Training",world);task.wait(1.65)
 local after=control:InvokeServer("Snapshot",world)
 local row={Name=name,World=world,Settled=settled,Started=started,Before=before,After=after,Gain=after.Data.Strength-before.Data.Strength,Ticks=#after.Events-#before.Events,SupportY=hit.Position.Y}
 table.insert(report.Training,row);check(started and row.Gain>0 and row.Ticks>=2,"Grounded training "..name.." W"..world,{Gain=row.Gain,Ticks=row.Ticks,Inside=after.Inside})
 local c,h=rig();h.Jump=true;task.wait(.15)
 row.Airborne=control:InvokeServer("Snapshot",world)
 check(not row.Airborne.Inside,"Airborne rejected "..name.." W"..world,{State=row.Airborne.State,Root=row.Airborne.Root,Inside=row.Airborne.Inside})
 if RS:GetAttribute("FixtureRegression")then
  task.wait(.45);row.AfterAir=control:InvokeServer("Snapshot",world)
  check(row.AfterAir.Data.Strength==row.Airborne.Data.Strength and not row.AfterAir.Training,"Airborne stops actual gain "..name.." W"..world)
  settle();place(a.Position.X,a.Position.Z,hit.Position.Y)
  local beforeAgain=control:InvokeServer("Snapshot",world);assert(control:InvokeServer("Training",world));task.wait(.7)
  local afterAgain=control:InvokeServer("Snapshot",world)
  check(afterAgain.Data.Strength>beforeAgain.Data.Strength,"Reentry resumes gain "..name.." W"..world)
  control:InvokeServer("Loaded",false);task.wait(.7)
  row.Ineligible=control:InvokeServer("Snapshot",world)
  check(row.Ineligible.Data.Strength==afterAgain.Data.Strength and not row.Ineligible.Training,"Lost eligibility stops gain "..name.." W"..world)
  control:InvokeServer("Loaded",true);assert(control:InvokeServer("Training",world))
 end
 if not RS:GetAttribute("FixtureRegression")then control:InvokeServer("Stop")end;settle()
 place(a.Position.X+a.Size.X+20,a.Position.Z,world==1 and 4 or 2)
 local exit=control:InvokeServer("Snapshot",world);check(not exit.Inside,"Exit rejected "..name.." W"..world)
 row.Exited=exit
 if RS:GetAttribute("FixtureRegression")then
  task.wait(.7);row.AfterExit=control:InvokeServer("Snapshot",world)
  check(row.AfterExit.Data.Strength==exit.Data.Strength and not row.AfterExit.Training,"Exit stops gain "..name.." W"..world)
 end
 control:InvokeServer("Stop")
end
local ok,err=xpcall(function()
 local cases={{Body="Normal",Mode="Growth",Stage=0},{Body="Normal",Mode="Growth",Stage=10},{Body="Muscle",Mode="Growth",Stage=0},{Body="Muscle",Mode="Growth",Stage=10}}
 if RS:GetAttribute("FixtureMuscleOnly")then cases={{Body="Muscle",Mode="Growth",Stage=0}}end
 if RS:GetAttribute("FixtureTrainingOnly")then cases={{Body="Normal",Mode="Growth",Stage=10},{Body="Muscle",Mode="Growth",Stage=0}}end
 if RS:GetAttribute("FixtureLifecycleOnly")then cases={}end
 for _,setting in cases do
  assert(control:InvokeServer("World",1));assert(waitFor(ready,10));body(setting)
  local name=setting.Body..setting.Stage
  for _,held in {false,true}do
   equip(held and "NORMAL_01"or "")
   local key=name..(held and "Held"or "Empty")
   report.Snapshots[key]=control:InvokeServer("Snapshot",1)
   if not RS:GetAttribute("FixtureTrainingOnly")then for trial=1,3 do measure(key,trial)end end
   treadmill(1,key);treadmill(2,key)
   assert(control:InvokeServer("World",1));assert(waitFor(ready,10))
  end
 end
 if RS:GetAttribute("FixtureRegression")then
  body({Body="Normal",Mode="Growth",Stage=0});equip("NORMAL_01")
  local returned=measure("Normal0AfterBodyRequest",1)
  check(returned.Speed>23 and returned.Speed<25,"Body request completes normal motion",returned.Speed)
  if #game.Players:GetPlayers()>=2 then
   assert(control:InvokeServer("PeerEquip","NORMAL_12"));task.wait(.5)
   local peer=control:InvokeServer("Observer");local correct=false
   for _,row in peer do if row.Index==1 then correct=#row.Displays==2 and row.Displays[1].ItemId=="NORMAL_01"and row.Displays[2].ItemId=="NORMAL_01"end end
   check(correct,"Peer sees first player's independent held ItemId",peer)
   local other;for _,p in game.Players:GetPlayers()do if p~=P then other=p end end
   local otherDisplays=displays(other and other.Character)
   check(#otherDisplays==2 and otherDisplays[1].ItemId=="NORMAL_12"and otherDisplays[2].ItemId=="NORMAL_12","First sees peer's independent held ItemId",otherDisplays)
  end
  for world=1,2 do
   assert(control:InvokeServer("World",world));assert(waitFor(ready,10))
   local m=world==2 and workspace.World2Map.TrainingArea.TreadmillDisplays["01"]or workspace.Treadmills.Normal01
   local a=m.Area;local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={m};params.RespectCanCollide=true
   local hit=assert(workspace:Raycast(a.Position+Vector3.new(0,50,0),Vector3.new(0,-100,0),params))
   place(a.Position.X,a.Position.Z,hit.Position.Y);assert(control:InvokeServer("Training",world));task.wait(.6)
   local old=P.Character;local strengthAtDeath=control:InvokeServer("Death")
   task.wait(.7);local dead=control:InvokeServer("Snapshot",world)
   check(dead.Data.Strength==strengthAtDeath and not dead.Training,"Death stops real gain W"..world)
   assert(waitFor(function()return P.Character~=old and ready()end,25),"Actual death/respawn path failed")
   controls:Disable();task.wait(.5)
   check(#displays(P.Character)==2 and #displays(old)==0,"Death leaves no duplicate displays W"..world)
   place(a.Position.X,a.Position.Z,hit.Position.Y);local beforeAgain=control:InvokeServer("Snapshot",world)
   assert(control:InvokeServer("Training",world));task.wait(.6);local afterAgain=control:InvokeServer("Snapshot",world)
   check(afterAgain.Data.Strength>beforeAgain.Data.Strength,"Respawn can train again W"..world)
   control:InvokeServer("Stop")
  end
 end
end,debug.traceback)
report.Error=not ok and err or nil;report.Passed=ok
for _,c in report.Checks do if not c.Passed then report.Passed=false end end
input=Vector3.zero;Run:UnbindFromRenderStep("__BodyDumbbellInput");controls:Enable()
RS:WaitForChild("__BodyDumbbellResults"):FireServer(report)
