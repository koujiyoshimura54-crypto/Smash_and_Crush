-- Native Edit geometry + exact route-client lifecycle, NOT physics/Play testing.
return function(loadModule)
 assert(not game:GetService("RunService"):IsRunning())
 local RS=game.ReplicatedStorage
 local geometry=loadModule(RS.Modules.World1WalkwayGeometry)
 local config=loadModule(RS.Config.World1WalkwayConfig)
 local rendererModule=loadModule(RS.Modules.FloorGuideRenderer)
 local result={Kind="Native Edit geometry and isolated client lifecycle (not Play)",Assertions=0}
 local function check(v,message)result.Assertions+=1;assert(v,message)end
 local route=assert(geometry.new()())
 local first,last,half=geometry.Bounds(route)
 result.Bounds={Start=first,End=last,Width=half*2,WallDistance=route.WallDistance,Origin=tostring(route.Origin)}
 check(first==5,"entrance remains 5 studs")
 check(config.Transparency==.5 and config.ArrowSpeed==4 and config.WidthMultiplier==3,"visual constants")
 check(geometry.TransportVelocity(24,0,20,1/60)==12,"passive speed 12")
 check(geometry.TransportVelocity(24,1,20,1/60)==36,"forward speed 36")
 check(geometry.TransportVelocity(24,-1,20,1/60)==-12,"reverse movement retained")
 check(not geometry.Contains(route,first-.01,0),"before entrance excluded")
 check(not geometry.Contains(route,last+.01,0),"after exit excluded")
 check(not geometry.Contains(route,20,half+.01),"outside right excluded")
 check(not geometry.Contains(route,20,-half-.01),"outside left excluded")
 local character=Instance.new("Model");character.Name="_RightWalkwayGroundProbe"
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1);root.Parent=character
 local state=Enum.HumanoidStateType.Running
 local h={Health=100,HipHeight=2,RigType=Enum.HumanoidRigType.R15,Sit=false,PlatformStand=false,Jump=false,GetState=function()return state end}
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={character};params.RespectCanCollide=true
 local floors={};local probes=0
 for along=first,last-.01,.5 do
  for _,side in {-half,0,half}do
   local point=route.Origin+route.Direction*along+route.Side*side
   local hit=workspace:Raycast(point+Vector3.yAxis*20,-Vector3.yAxis*40,params)
   check(hit and geometry.IsFloor(hit.Instance,route),"authored floor at edge/seam")
   root.Position=Vector3.new(point.X,hit.Position.Y+3,point.Z)
   check(geometry.Contains(route,along,side),"continuous membership")
   check(geometry.Grounded(character,h,root,route,params),"ground contact at edge/seam")
   floors[hit.Instance:GetFullName()]=true;probes+=1
  end
  if probes%60==0 then task.wait()end
 end
 h.Jump=true;check(not geometry.Grounded(character,h,root,route,params),"jump releases");h.Jump=false
 h.Health=0;check(not geometry.Grounded(character,h,root,route,params),"death releases");h.Health=100
 state=Enum.HumanoidStateType.Freefall;check(not geometry.Grounded(character,h,root,route,params),"air releases");state=Enum.HumanoidStateType.Running
 result.FloorProbes=probes;result.Floors=floors
 local world=1;local callbacks={};local owners={}
 local player={Character=nil,GetAttribute=function(_,key)return key=="CurrentWorld" and world or nil end}
 function player:GetAttributeChangedSignal()
  return {Connect=function(_,f)local c={live=true};function c:Disconnect()self.live=false end;table.insert(callbacks,{c,f});return c end}
 end
 local function setWorld(value)
  world=value;for _,v in callbacks do if v[1].live then v[2]()end end
 end
 local name="_RightWalkwayReview"
 check(not workspace:FindFirstChild(name),"no existing fixture")
 local function launch()
  local owner=Instance.new("LocalScript");owner.Name="_RightWalkwayReviewOwner";owner.Parent=game.ServerStorage;table.insert(owners,owner)
  local proxy={GetService=function(_,service)
   if service=="Players"then return {LocalPlayer=player}end
   if service=="ReplicatedStorage"then return RS end
   error("Unexpected fixture service: "..service)
  end}
  local f=assert(loadstring(game.StarterPlayer.StarterPlayerScripts.Tutorial.World1FloorRouteClient.Source,"=RouteClientFixture"))
  setfenv(f,setmetatable({script=owner,game=proxy,require=function(m)
   if m==RS.Modules.FloorGuideRenderer then return {new=function(options)options.Name=name;return rendererModule.new(options)end}end
   return loadModule(m)
  end},{__index=getfenv()}));f()
 end
 launch();task.wait(.5)
 local folder=assert(workspace:FindFirstChild(name));local identities={};local moved={}
 local beforeCount=#folder:GetChildren()
 for _,part in folder:GetChildren()do identities[part]=part.CFrame end
 local maximum,minimum=-math.huge,math.huge
 for sample=1,12 do
  task.wait(.1)
  for _,part in folder:GetChildren()do
   check(identities[part]~=nil,"pooled instances retained")
   if part.CFrame~=identities[part]then moved[part]=true end
   check(not part.CanCollide and not part.CanTouch and not part.CanQuery,"visual does not affect physics/rays")
   if part.Transparency<1 then
    check(part.Transparency==.5,"visible opacity")
    local size=part.Size/2
    for _,x in {-1,1}do for _,z in {-1,1}do
     local point=part.CFrame:PointToWorldSpace(Vector3.new(size.X*x,0,size.Z*z))
     local along,side=geometry.Coordinates(route,point)
     check(along>=first-1e-4 and along<=last+1e-4 and math.abs(side)<=half+1e-4,"actual arrow outer corner within transport")
     maximum=math.max(maximum,along);minimum=math.min(minimum,along)
    end end
   end
  end
 end
 local movedCount=0;for _ in moved do movedCount+=1 end
 check(movedCount==beforeCount and beforeCount>0,"all arrows move")
 result.PooledParts=beforeCount;result.MovingParts=movedCount;result.VisibleRange={minimum,maximum}
 setWorld(2);task.wait(.25)
 for _,part in folder:GetChildren()do check(part.Transparency==1,"World2 hidden")end
 setWorld(1);task.wait(.3)
 check(folder.Parent==workspace and #folder:GetChildren()==beforeCount,"World1 restores pool")
 local torso=Instance.new("Part");torso.Name="UpperTorso";torso.Size=Vector3.new(20,20,20);torso.CFrame=root.CFrame;torso.Parent=character
 player.Character=character;task.wait(.3)
 local _,largeEnd=geometry.Bounds(route,character)
 check(largeEnd<last,"large-body safety shared by renderer")
 for _,part in folder:GetChildren()do if part.Transparency<1 then
  local along=geometry.Coordinates(route,part.Position)
  check(along<=largeEnd,"no visible arrow past large-body endpoint")
 end end
 player.Character=nil;task.wait(.3)
 launch();task.wait(.4)
 check(folder.Parent==nil,"reinitialization destroys previous pool")
 local count=0;for _,x in workspace:GetChildren()do if x.Name==name then count+=1 end end
 check(count==1,"one guide owner after reinitialization")
 for _,owner in owners do owner:Destroy()end
 character:Destroy();task.wait(.3)
 check(workspace:FindFirstChild(name)==nil,"fixture guide removed")
 local live=0;for _,v in callbacks do if v[1].live then live+=1 end end
 check(live==0,"fixture subscriptions disconnected")
 result.Cleanup=true
 return result
end
