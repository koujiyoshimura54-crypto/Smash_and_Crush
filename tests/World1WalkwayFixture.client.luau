-- Actual Studio physics/animation with synthetic Humanoid input and positioning.
-- Integration with production saves/combat/Body prototype is NOT simulated here.
local P=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local Run=game:GetService("RunService")
local function waitFor(fn,seconds)
 local deadline=os.clock()+(seconds or 25)
 repeat local result=fn();if result then return result end;task.wait(.02) until os.clock()>deadline
 error("Fixture wait timeout")
end
waitFor(function() return P:GetAttribute("FixtureReady") and P:GetAttribute("FixtureIndex") end)
if P:GetAttribute("FixtureIndex")~=1 then
 task.wait(.5)
 local c=P.Character;local h=c.Humanoid;local r=c.HumanoidRootPart
 r.CFrame=CFrame.new(310,4+h.HipHeight+r.Size.Y/2,13);r.AssemblyLinearVelocity=Vector3.zero
 return
end
local control=RS:WaitForChild("__WalkwayControl")
local report={Rows={},Checks={},Kind="Actual isolated Studio Play; synthetic input/placement; fresh local fixture"}
local controls=require(P.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local G=require(RS.Modules.World1WalkwayGeometry)
local C=require(RS.Config.World1WalkwayConfig)
local route=G.new()()
local input=Vector3.zero
controls:Disable()
Run:BindToRenderStep("__WalkwayFixtureInput",Enum.RenderPriority.Character.Value+1,function()
 local h=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
 if h then h:Move(input,false) end
end)
local function check(ok,name,detail)
 report.Checks[#report.Checks+1]={Name=name,Passed=not not ok,Detail=detail}
 if not ok then warn("WALKWAY_CHECK_FAILED "..name) end
end
local observedHumanoid,runningConnection,lastRunningSpeed
local function rig()
 local h=P.Character.Humanoid
 if observedHumanoid~=h then
  if runningConnection then runningConnection:Disconnect() end
  observedHumanoid=h;lastRunningSpeed=0
  runningConnection=h.Running:Connect(function(speed)lastRunningSpeed=speed end)
 end
 return P.Character,h,P.Character.HumanoidRootPart
end
local function place(along,side,height)
 input=Vector3.zero
 local c,h,r=rig()
 local point=route.Origin+route.Direction*along+route.Side*(side or 0)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={c};params.RespectCanCollide=true
 local hit=assert(workspace:Raycast(Vector3.new(point.X,80,point.Z),Vector3.new(0,-100,0),params))
 local pos=Vector3.new(point.X,hit.Position.Y+h.HipHeight+r.Size.Y/2+(height or .02),point.Z)
 r.CFrame=CFrame.lookAt(pos,pos+route.Direction)
 r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
end
local function tracks()
 local _,h=rig();local animator=h:FindFirstChildOfClass("Animator");local out={}
 if animator then for _,t in animator:GetPlayingAnimationTracks() do
  out[#out+1]={Name=t.Name,Id=t.Animation and t.Animation.AnimationId,Priority=t.Priority.Name,Speed=t.Speed,Weight=t.WeightCurrent}
 end end
 return out
end
local function measure(name,side,move,along,span)
 place(along or 18,side);task.wait(.3);input=move
 task.wait(.25)
 local _,h,r=rig();local before=r.Position;local time=os.clock()
 local startTracks=tracks()
 task.wait(span or .6)
 local dt=os.clock()-time;local delta=r.Position-before
 local row={Name=name,Distance=delta:Dot(route.Direction),Seconds=dt,Speed=delta:Dot(route.Direction)/dt,
  SideSpeed=delta:Dot(route.Side)/dt,WalkSpeed=h.WalkSpeed,MoveMagnitude=h:GetMoveVelocity().Magnitude/h.WalkSpeed,
  Riding=P:GetAttribute("World1WalkwayRiding")==true,Tracks=startTracks,EndTracks=tracks(),
  HipHeight=h.HipHeight,RootSize=tostring(r.Size),Root=tostring(r.Position),State=h:GetState().Name,LastRunningSpeed=lastRunningSpeed}
 report.Rows[#report.Rows+1]=row;input=Vector3.zero
 return row
end
local ok,err=xpcall(function()
 local folder=waitFor(function()return workspace:FindFirstChild("World1PermanentFloorGuide")end)
 task.wait(2)
 place(0,0);task.wait(.5)
 check(P:GetAttribute("World1WalkwayRiding")~=true,"Spawn center does not ride")
 local base=measure("Normal24",12,route.Direction)
 local idle=measure("Idle12",0,Vector3.zero)
 local forward=measure("Forward36",0,route.Direction)
 report.ConcurrentPlayers=control:InvokeServer("Status")
 local half=measure("HalfForward24",0,route.Direction*.5)
 check(math.abs(half.Speed-24)<1 and math.abs(half.MoveMagnitude-.5)<.01,"Analog half input is preserved",half.Speed)
 local function runRate(row)
  for _,track in row.EndTracks do if track.Name=="RunAnim" and track.Priority=="Core" then return track.Speed end end
 end
 local baseRate,forwardRate=runRate(base),runRate(forward)
 check(baseRate and forwardRate and math.abs(forwardRate/baseRate-1)<.01,"Walking playback matches normal floor within 1%",{Normal=baseRate,Walkway=forwardRate})
 check(runRate(idle)==0,"Passive carry does not speed up locomotion")
 local reverse=measure("ReverseMinus12",0,-route.Direction,45,.5)
 local afterExit=measure("Normal24AfterExit",12,route.Direction)
 -- Native Animate uses the last Running event, whose threshold may retain a
 -- slightly lower startup speed even after physics reaches the steady 24.
 -- Verify its native event-to-rate relation, not an identical historical event.
 local nativeRate=baseRate*afterExit.LastRunningSpeed/base.LastRunningSpeed
 check(math.abs(afterExit.Speed-24)<1 and not afterExit.Riding and math.abs(runRate(afterExit)/nativeRate-1)<.01,
  "Native movement and animation event control restored after exit",{Speed=afterExit.Speed,Playback=runRate(afterExit),NativeExpected=nativeRate,RunningEvent=afterExit.LastRunningSpeed})
 place(20,0);task.wait(.3)
 local animator=P.Character.Humanoid:FindFirstChildOfClass("Animator")
 local animation=Instance.new("Animation");animation.AnimationId="rbxassetid://913376220"
 local action=animator:LoadAnimation(animation);action.Priority=Enum.AnimationPriority.Action;action:Play(0,1,1.37)
 task.wait(.2)
 check(math.abs(action.Speed-1.37)<.001,"Action track playback is untouched",action.Speed)
 action:Stop();action:Destroy();animation:Destroy()
 control:InvokeServer("Training",true);task.wait(.35)
 local treadmill
 for _,track in animator:GetPlayingAnimationTracks() do if track.Name=="TreadmillRunTrack" then treadmill=track end end
 check(treadmill and math.abs(treadmill.Speed-1)<.001 and P:GetAttribute("World1WalkwayRiding")~=true,"Existing Treadmill track retains rate and excludes carry",treadmill and treadmill.Speed)
 control:InvokeServer("Training",false)
 local diagonal=measure("Diagonal",-3,(route.Direction+route.Side).Unit,18,.08)
 check(math.abs(diagonal.Speed-(12+24/math.sqrt(2)))<2 and math.abs(diagonal.SideSpeed-24/math.sqrt(2))<2,"Diagonal preserves both components",{Forward=diagonal.Speed,Side=diagonal.SideSpeed})
 -- Sideways naturally leaves the narrow band, so sample only while inside it.
 place(20,0);task.wait(.25);input=route.Side
 local _,_,root=rig();local start=root.Position;local started=os.clock();task.wait(.08)
 local delta=root.Position-start
 report.Rows[#report.Rows+1]={Name="SideInputEarly",Seconds=os.clock()-started,Forward=delta:Dot(route.Direction),Side=delta:Dot(route.Side)}
 local sideSamples={}
 for i=1,8 do
  task.wait(.1)
  local a,s=G.Coordinates(route,root.Position)
  local mover=root:FindFirstChild("World1WalkwayVelocity")
  sideSamples[i]={Along=a,Side=s,Velocity=tostring(root.AssemblyLinearVelocity),Input=tostring(P.Character.Humanoid:GetMoveVelocity()),Riding=P:GetAttribute("World1WalkwayRiding")==true,MoverEnabled=mover and mover.Enabled or false}
  if math.abs(s)>C.TransportWidth/2 then check(not mover or not mover.Enabled,"Side boundary disables local mover "..i) end
 end
 check(P:GetAttribute("World1WalkwayRiding")~=true,"Side input leaves walkway",sideSamples)
 check(math.abs(base.Speed-24)<1,"Normal walk near 24",base.Speed)
 check(math.abs(idle.Speed-12)<1,"Idle carry near 12",idle.Speed)
 check(math.abs(forward.Speed-36)<1,"Forward adds 12",forward.Speed)
 check(math.abs(reverse.Speed+12)<1,"Reverse keeps signed input",reverse.Speed)
 control:InvokeServer("Speed",4)
 local upgradedBase=measure("UpgradedNormal40",12,route.Direction,10,.55)
 local upgraded=measure("UpgradedForward52",0,route.Direction,10,.55)
 local upgradedIdle=measure("UpgradedIdle12",0,Vector3.zero)
 check(math.abs(upgraded.Speed-52)<1 and upgraded.WalkSpeed==40,"Upgrade40 adds 12",upgraded.Speed)
 check(math.abs(upgradedIdle.Speed-12)<1,"Upgrade does not change passive carry",upgradedIdle.Speed)
 check(math.abs(runRate(upgraded)/runRate(upgradedBase)-1)<.01,"Upgraded walking playback matches normal floor",{Normal=runRate(upgradedBase),Walkway=runRate(upgraded)})
 control:InvokeServer("Speed",0)
 place(4.7,0);task.wait(.4)
 check(P:GetAttribute("World1WalkwayRiding")~=true,"Before fixed start boundary")
 place(5.1,0)
 local enteredAt=os.clock()
 waitFor(function() local _,_,r=rig();local mover=r:FindFirstChild("World1WalkwayVelocity");return mover and mover.Enabled end,2)
 local entryDelay=os.clock()-enteredAt
 check(entryDelay<.4,"After fixed start boundary without input",{ObservedSeconds=entryDelay})
 place(20,0);task.wait(.3)
 local c,h,r=rig();h.Jump=true;task.wait(.12)
 check(not r:FindFirstChild("World1WalkwayVelocity") or not r.World1WalkwayVelocity.Enabled,"Jump releases carry")
 task.wait(.8);place(20,0);task.wait(.25)
 check(P:GetAttribute("World1WalkwayRiding")==true,"Reboard after jump")
 place(20,0,12);task.wait(.1)
 local _,airHum,airRoot=rig();local airMover=airRoot:FindFirstChild("World1WalkwayVelocity")
 check(not airMover or not airMover.Enabled,"Airborne mover disabled immediately")
 task.wait(.25)
 check(P:GetAttribute("World1WalkwayRiding")~=true,"Airborne server ride clears")
 for _,scale in {.7,1,2} do
  control:InvokeServer("Scale",scale)
  local row=measure("ScaledR15_"..scale,0,Vector3.zero)
  check(math.abs(row.Speed-12)<1,"Grounded scaled R15 "..scale,row.Speed)
 end
 control:InvokeServer("Scale",1)
 place(73,0);task.wait(1.5)
 local _,_,r=rig();local along=G.Coordinates(route,r.Position)
 local ended=G.EndDistance(route,P.Character)
 check(P:GetAttribute("World1WalkwayRiding")~=true and along<=ended+.5,"Stops before first wall",{Along=along,End=ended})
 check(route.WallDistance-along<5 and route.WallDistance-along>3.5,"Stops inside current forward attack reach")
 local wall=workspace.GeneratedMap.BattleCorridor.Stage01["Stage1.1"].Wall
 wall.Transparency=1;wall.CanCollide=false
 place(73,0);task.wait(1.5)
 local after=G.Coordinates(route,r.Position)
 check(math.abs(after-along)<.5,"Personal wall disappearance keeps endpoint")
 wall.Transparency=0;wall.CanCollide=true
 control:InvokeServer("World",2);task.wait(.35)
 local visible=0;for _,p in folder:GetChildren() do if p.Transparency<1 then visible+=1 end end
 check(P:GetAttribute("World1WalkwayRiding")~=true and visible==0,"World2 attribute clears visuals and ride")
 control:InvokeServer("World",1);place(20,0);task.wait(.35)
 check(P:GetAttribute("World1WalkwayRiding")==true,"World1 attribute restores ride")
 local count=folder:GetAttribute("ChevronCount");local span=folder:GetAttribute("FlowSpan")
 local initial={};local created=0
 local added=folder.ChildAdded:Connect(function()created+=1 end)
 for i=1,count do initial[i]={L=folder["Chevron"..i.."_Left"].Position,R=folder["Chevron"..i.."_Right"].Position} end
 place(0,0);task.wait(.2)
 local moving,paired=0,0
 for i=1,count do
  local a,b=folder["Chevron"..i.."_Left"],folder["Chevron"..i.."_Right"]
  local dl,dr=a.Position-initial[i].L,b.Position-initial[i].R
  if dl.Magnitude>.3 then moving+=1 end
  if (dl-dr).Magnitude<.003 then paired+=1 end
  check(a.Transparency==.5 and b.Transparency==.5,"Visible pair opacity "..i)
 end
 check(moving==count and paired==count,"All arrows move as pairs while player idle",{Count=count,Moving=moving,Paired=paired})
 local last={};local wraps={}
 for i=1,count do last[i]=folder["Chevron"..i.."_Left"].Position end
 local untilTime=os.clock()+span/4+.5
 repeat
  task.wait(.1)
  for i=1,count do local p=folder["Chevron"..i.."_Left"].Position
   if (p-last[i]):Dot(route.Direction)<-span*.5 then wraps[i]=true end;last[i]=p
  end
 until os.clock()>untilTime
 added:Disconnect()
 local wrapped=0;for _ in wraps do wrapped+=1 end
 local folders=0;for _,x in workspace:GetChildren() do if x.Name==folder.Name then folders+=1 end end
 check(wrapped==count and created==0 and folders==1 and #folder:GetChildren()==count*2,"All pairs cycle without duplication/allocation",{Wrapped=wrapped,Created=created,Folders=folders})
 report.OtherPlayers=control:InvokeServer("Status")
 local old=P.Character;control:InvokeServer("Death")
 waitFor(function()
  local c=P.Character
  local h=c and c:FindFirstChildOfClass("Humanoid")
  return c~=old and c and c:FindFirstChild("HumanoidRootPart") and h and h.Health>0
 end)
 task.wait(.5);controls:Disable();place(0,0);task.wait(.3)
 check(P:GetAttribute("World1WalkwayRiding")~=true,"Respawn at origin has no carry")
 place(20,0);task.wait(.3)
 check(P:GetAttribute("World1WalkwayRiding")==true,"Respawn can reboard")
end,debug.traceback)
report.Error=not ok and err or nil
report.Passed=ok
for _,row in report.Checks do if not row.Passed then report.Passed=false end end
input=Vector3.zero;Run:UnbindFromRenderStep("__WalkwayFixtureInput");controls:Enable()
RS:WaitForChild("__WalkwayResults"):FireServer(report)
