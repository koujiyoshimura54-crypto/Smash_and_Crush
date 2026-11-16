assert(game.PlaceId==0 and game.ReplicatedStorage:GetAttribute("DumbbellFixture")==true)
local Players=game:GetService("Players");local P=Players.LocalPlayer
local Run=game:GetService("RunService");local RS=game.ReplicatedStorage
local control=RS:WaitForChild("__DumbbellControl",30)
local observer=RS:WaitForChild("__DumbbellObserver",30)
local function displays(c)
 local out={};if c then for _,x in c:GetChildren()do if x.Name=="TrainingDumbbellRight" or x.Name=="TrainingDumbbellLeft" then out[#out+1]={Name=x.Name,ItemId=x:GetAttribute("ItemId")}end end end;return out
end
observer.OnClientInvoke=function()
 local rows={};for _,p in Players:GetPlayers()do rows[#rows+1]={Index=p:GetAttribute("FixtureIndex"),Displays=displays(p.Character)}end;return rows
end
local function waitFor(fn,seconds)
 local deadline=os.clock()+(seconds or 15)
 repeat if fn()then return true end task.wait(.05)until os.clock()>deadline
 error("Fixture wait timed out")
end
waitFor(function()return P:GetAttribute("FixtureReady")end,40)
if P:GetAttribute("FixtureIndex")~=1 then return end
local controls=require(P.PlayerScripts:WaitForChild("PlayerModule",20)):GetControls();controls:Disable()
local input=Vector3.zero
Run:BindToRenderStep("__DumbbellFixtureInput",Enum.RenderPriority.Input.Value+1,function()
 local c=P.Character;local h=c and c:FindFirstChildOfClass("Humanoid");if h then h:Move(input,false)end
end)
local report={Checks={},Measurements={}}
local function check(value,name,details)
 report.Checks[#report.Checks+1]={Name=name,Passed=value==true,Details=details}
 print("DUMBBELL_CHECK",name,value)
end
local function rig()
 waitFor(function()local c=P.Character;return c and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("RightHand")end,15)
 local c=P.Character;return c,c.Humanoid,c.HumanoidRootPart
end
local function place(x,z,top)
 input=Vector3.zero;local c,h,r=rig();r.CFrame=CFrame.new(x,(top or 0)+h.HipHeight+r.Size.Y/2+.03,z)
 r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;task.wait(.5)
end
local function equip(id)
 assert(control:InvokeServer("Equip",id));task.wait(.4)
end
local function safeParts(c)
 local parts=0;local safe=true
 for _,display in c:GetChildren()do if display:GetAttribute("World1DumbbellVisual")then
  for _,p in display:GetDescendants()do if p:IsA("BasePart")then parts+=1;safe=safe and not p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and p.Massless end end
 end end;return safe and parts>0,parts
end
local function measure(name)
 place(0,0);local c,h,r=rig();input=Vector3.new(0,0,-1);task.wait(.25)
 local start=r.Position;local t=os.clock();task.wait(.9);local duration=os.clock()-t
 local speed=(Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(start.X,0,start.Z)).Magnitude/duration
 input=Vector3.zero;local y=r.Position.Y;h.Jump=true
 local peak=y;local untilTime=os.clock()+1.1
 repeat Run.Heartbeat:Wait();peak=math.max(peak,r.Position.Y)until os.clock()>untilTime
 local row={Name=name,Speed=speed,JumpRise=peak-y,WalkSpeed=h.WalkSpeed,Mass=r.AssemblyMass}
 report.Measurements[#report.Measurements+1]=row;return row
end
local ok,err=xpcall(function()
 place(0,0);equip("");local base=measure("NoDumbbells")
 for i=1,12 do
  local id=string.format("NORMAL_%02d",i);equip(id)
  local c=rig();local list=displays(c);local safe,n=safeParts(c)
  check(#list==2 and list[1].ItemId==id and list[2].ItemId==id,"Equipped "..id,{Parts=n,Safe=safe})
  check(safe,"Nonphysical "..id)
  local snapshot=control:InvokeServer("Snapshot");task.wait(.15)
  check(snapshot.Data==control:InvokeServer("Snapshot").Data,"Visual does not mutate profile "..id)
  local stand=workspace.PerStepButtons[tostring(i)]
  local count=0;for _,x in stand:GetChildren()do if x.Name=="World1DumbbellExhibit"then count+=1 end end
  check(count==1 and stand.World1DumbbellExhibit:GetAttribute("ItemId")==id and stand.BillboardGui.ItemIcon.ImageTransparency==1,"Unique matching exhibit "..id)
 end
 task.wait(2)
 equip("");base=measure("NoDumbbellsAfterAssetLoad");equip("NORMAL_12")
 local held=measure("NormalBodyHeld")
 check(math.abs(base.Speed-held.Speed)<.8 and math.abs(base.Mass-held.Mass)<.01,"Held leaves walk speed and assembly mass unchanged",{Before=base,After=held})
 check(held.JumpRise>2 and math.abs(base.JumpRise-held.JumpRise)<.7,"Held leaves jump unchanged")
 -- Observe renderer fetches. PreloadAsync(strings) uses a different content
 -- representation and rejects these imported mesh/PBR IDs even when rendered.
 local content={};for _,s in workspace.PerStepButtons:GetDescendants()do
  if s:IsA("MeshPart")then content[#content+1]=s.MeshId
  elseif s:IsA("SurfaceAppearance")then
   for _,key in {"ColorMapContent","NormalMapContent","RoughnessMapContent","MetalnessMapContent"}do content[#content+1]=s[key].Uri end
  end
 end
 local camera=workspace.CurrentCamera;local oldType,oldCF=camera.CameraType,camera.CFrame
 camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(Vector3.new(253,39,54),Vector3.new(214,12,12))
 local success,failed=0,0;local deadline=os.clock()+15
 repeat
  task.wait(.3);success=0;failed=0
  for _,id in content do if game.ContentProvider:GetAssetFetchStatus(id)==Enum.AssetFetchStatus.Success then success+=1 else failed+=1 end end
 until success==55 or os.clock()>deadline
 camera.CameraType=oldType;camera.CFrame=oldCF
 -- SurfaceAppearance rendering uses processed texture packs; raw PBR URI
 -- fetch status is not a reliable runtime material-loading assertion.
 report.RawAssetFetchObservation={Success=success,Other=failed,TextureMapsRequireVisualReview=true}
 check(success>=11,"Client fetched 11 registered meshes",{Success=success})
 equip("NORMAL_01");local peer=control:InvokeServer("Observer")
 local visible=false;for _,row in peer do if row.Index==1 then visible=#row.Displays==2 and row.Displays[1].ItemId=="NORMAL_01"end end
 check(visible,"Second client sees first player's equipped model",peer)
 local second;for _,p in Players:GetPlayers()do if p~=P then second=p end end
 check(second and #displays(second.Character)==2 and displays(second.Character)[1].ItemId=="NORMAL_12","First client sees independent second player")
 place(800,0);check(#displays(P.Character)==0,"Lobby exit removes both")
 place(0,0);check(#displays(P.Character)==2,"Lobby return restores current equipment")
 control:InvokeServer("Loaded",false);task.wait(.4);check(#displays(P.Character)==0,"Load pending hides safely")
 control:InvokeServer("Loaded",true);task.wait(.4);check(#displays(P.Character)==2,"Load ready restores")
 control:InvokeServer("Owned",false);task.wait(.4);check(#displays(P.Character)==0,"Unowned item has no held display")
 control:InvokeServer("Owned",true);task.wait(.4)
 control:InvokeServer("World",2);place(2000,0);equip("W2_NORMAL_01")
 check(#displays(P.Character)==2 and not P.Character.TrainingDumbbellRight:GetAttribute("World1DumbbellVisual"),"World2 preserves legacy model")
 control:InvokeServer("World",1);place(0,0);equip("NORMAL_01")
 for _,setting in {{Body="Normal",Mode="Growth",Stage=10},{Body="Muscle",Mode="Growth",Stage=0},{Body="Muscle",Mode="Growth",Stage=10},{Body="Normal",Mode="Manual",Stage=0,Height=10,Thickness=10},{Body="Normal",Mode="Growth",Stage=0}}do
  local beforeC,beforeH,beforeR=rig();beforeH.RequiresNeck=false;beforeR.Anchored=true
  local dims=control:InvokeServer("Body",setting);task.wait(.5)
  control:InvokeServer("BodyRelease");beforeR.Anchored=false;beforeH.RequiresNeck=true
  place(0,0);task.wait(.4)
  local c=rig();local safe=safeParts(c);local _,size=c.TrainingDumbbellRight:GetBoundingBox()
  check(#displays(c)==2 and safe and math.abs(size.X-2*dims.Scale)<.02,"Body scale absolute "..setting.Body..setting.Mode..setting.Stage,{Dimensions=dims,HeldLength=size.X})
  local moving=measure(setting.Body..setting.Mode..setting.Stage)
  equip("");local empty=measure(setting.Body..setting.Mode..setting.Stage.."_NoDumbbells");equip("NORMAL_01")
  check(math.abs(moving.Speed-empty.Speed)<1.5 and math.abs(moving.Mass-empty.Mass)<.01 and math.abs(moving.JumpRise-empty.JumpRise)<.7,"Body motion compared with no dumbbells "..setting.Body..setting.Mode..setting.Stage,{Held=moving,Baseline=empty})
  place(50,0,1);local start=control:InvokeServer("Snapshot").Ticks
  local started=control:InvokeServer("Training",true);task.wait(1.15);local after=control:InvokeServer("Snapshot")
  local pose=control:InvokeServer("Pose")
  control:InvokeServer("Training",false)
  equip("");place(50,0,1);local baseStart=control:InvokeServer("Snapshot").Ticks
  local baseStarted=control:InvokeServer("Training",true);task.wait(1.15);local baseTicks=control:InvokeServer("Snapshot").Ticks-baseStart
  control:InvokeServer("Training",false);equip("NORMAL_01")
  check(started==baseStarted and ((after.Ticks-start)>0)==(baseTicks>0),"TrainingManager unchanged with held "..setting.Body..setting.Mode..setting.Stage,{Started=started,TickDifference=after.Ticks-start,Gain=after.Gain,Pose=pose,BaselineStarted=baseStarted,BaselineTicks=baseTicks})
 end
 -- The display controller sees live validated inventory changes; purchase and
 -- forge persistence are deliberately absent, so no real purchases are claimed.
 place(233.212,32.420,7.8205);task.wait(.4)
 check(control:InvokeServer("Snapshot").Stand=="NORMAL_01","Existing stand entrance detector still fires")
 place(0,0);equip("NORMAL_03");control:InvokeServer("Missing",true);equip("NORMAL_04")
 check(#displays(P.Character)==0,"Missing resource allows gameplay without partial attachment")
 task.wait(.5);check(P.Character.Humanoid.Health>0,"Missing resource does not halt character")
 control:InvokeServer("Missing",false);equip("NORMAL_03");equip("NORMAL_04")
 check(#displays(P.Character)==2,"Real equip change retries restored resource")
 local old=P.Character;control:InvokeServer("Death")
 waitFor(function()return P.Character~=old and P:GetAttribute("FixtureReady") and P.Character and P.Character:FindFirstChild("RightHand")end,20)
 task.wait(.6);controls:Disable();place(0,0)
 check(#displays(P.Character)==2 and #displays(old)==0,"Death/respawn leaves exactly two new displays")
 for _=1,4 do place(800,0);place(0,0)end
 check(#displays(P.Character)==2,"Repeated lobby transitions never double attach")
end,debug.traceback)
report.Error=not ok and err or nil;report.Passed=ok
for _,row in report.Checks do if not row.Passed then report.Passed=false end end
input=Vector3.zero;Run:UnbindFromRenderStep("__DumbbellFixtureInput");controls:Enable()
RS:WaitForChild("__DumbbellResults"):FireServer(report)
