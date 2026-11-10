-- Temporary isolated Play driver. Requires every external service redirected first.
local Services=game.ServerScriptService.Services
local D=require(Services.PlayerDataService)
local T=require(Services.TrainingManager)
local Strength=require(Services.StrengthManager)
local Pass=require(Services.GamePassService)
local C=require(game.ReplicatedStorage.Config.TreadmillConfig)
local Mem=require(game.ReplicatedStorage.__Phase110Memory)
local p=game.Players:GetPlayers()[1]
local deadline=os.clock()+15
while not D.IsLoaded(p) or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") do assert(os.clock()<deadline);task.wait(.1) end
D.SetAutoTapEnabled(p,false)
Mem.TreadmillOwned=true
Mem.MarketplaceService.UserOwnsGamePassAsync=function(_,_,id)
 return Mem.TreadmillOwned and (id==1982996954 or id==2044250678)
end
Pass.RefreshPremiumTreadmill(p,1);Pass.RefreshPremiumTreadmill(p,2)
local events={}
local original=Strength.AddStrength
Strength.AddStrength=function(player,amount,count,multiplier)
 local before=D.Get(player).Data.Strength
 local value,reason=original(player,amount,count,multiplier)
 if player==p and multiplier then events[#events+1]={time=os.clock(),multiplier=multiplier,delta=D.Get(p).Data.Strength-before,result=value,reason=reason} end
 return value,reason
end
local function model(world,name)
 return world==1 and workspace.Treadmills[name] or workspace.World2Map.TrainingArea.TreadmillDisplays[name]
end
local function place(world,name,rebirth)
 T.StopTraining(p)
 D.SetRebirthCount(p,rebirth or 9)
 p:SetAttribute("CurrentWorld",world)
 local ch=p.Character;local h=ch.Humanoid;local root=ch.HumanoidRootPart
 local m=model(world,name);local area=m.Area
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={m};params.RespectCanCollide=true
 local hit=assert(workspace:Raycast(area.Position+Vector3.new(0,30,0),Vector3.new(0,-60,0),params),"No deck")
 root.Anchored=false;root:SetNetworkOwner(nil)
 ch:PivotTo(CFrame.new(area.Position.X,hit.Position.Y+h.HipHeight+root.Size.Y/2+.02,area.Position.Z))
 root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 return m
end
local function observe(seconds)
 local start=#events;local strength=D.Get(p).Data.Strength;local at=os.clock()
 task.wait(seconds)
 local rows={} for i=start+1,#events do rows[#rows+1]=events[i] end
 return {delta=D.Get(p).Data.Strength-strength,ticks=#rows,seconds=os.clock()-at,rows=rows,active=p:GetAttribute("IsTraining"),sessions=T.GetActiveSessionCount()}
end
local b=Instance.new("BindableFunction");b.Name="__TreadmillQA";b.Parent=game.ServerStorage
b.OnInvoke=function(action,arg)
 if action=="Strength" then D.SetCurrentStrength(p,arg);task.wait(.5);return p.Character:GetAttribute("MuscleHeightScale") end
 if action=="Place" then local m=place(arg.World,arg.Name,arg.Rebirth);return {allowed=T.CanUseTreadmill(p,m),path=m:GetFullName()} end
 if action=="Sample" then return observe(arg or 2.1) end
 if action=="Station" then
  local m=place(arg.World,arg.Name);task.wait(.8)
  local allowed,cfg=T.CanUseTreadmill(p,m);assert(allowed)
  for _=1,4 do assert(T.StartTraining(p,m)) end
  local r=observe(2.1);assert(r.active and r.sessions==1 and r.ticks>=3 and r.ticks<=5,"Missing/duplicate ticks")
  for _,e in ipairs(r.rows) do assert(e.multiplier==cfg.Multiplier and math.abs(e.delta-cfg.Multiplier*5.5)<.001) end
  local root=p.Character.HumanoidRootPart
  root.CFrame+=Vector3.new(0,0,m.Area.Size.Z+30)
  task.wait(.7);local stopped=observe(.6)
  assert(not stopped.active and stopped.delta==0,"Exit kept granting")
  return {world=arg.World,name=arg.Name,multiplier=cfg.Multiplier,result=r,stopped=stopped}
 end
 if action=="Denied" then
  local m=place(arg.World,arg.Name,arg.Rebirth);task.wait(.7)
  local r=observe(.7);assert(not r.active and r.delta==0);return r
 end
 if action=="Premium" then
  Mem.TreadmillOwned=arg;Pass.RefreshPremiumTreadmill(p,1);Pass.RefreshPremiumTreadmill(p,2)
  return {enabled=Pass.AreEffectsEnabled(p),w1=Pass.HasPremiumTreadmill(p,1),w2=Pass.HasPremiumTreadmill(p,2)}
 end
 if action=="WorldSwitch" then
  place(2,"03",9);task.wait(.7);assert(p:GetAttribute("IsTraining"))
  p:SetAttribute("CurrentWorld",1);task.wait(.6)
  local r=observe(.6);assert(not r.active and r.delta==0);return r
 end
 if action=="Death" then
  place(2,"03",9);task.wait(.7);assert(p:GetAttribute("IsTraining"))
  local old=p.Character;old.Humanoid.Health=0;task.wait(.6)
  local r=observe(.6);assert(not r.active and r.delta==0)
  local limit=os.clock()+12
  while p.Character==old or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") or not p.Character:GetAttribute("MuscleScaleReady") do assert(os.clock()<limit);task.wait(.1) end
  place(2,"03",9);task.wait(.8);local after=observe(1.1);assert(after.active and after.delta>0)
  return {dead=r,respawn=after}
 end
 if action=="RestoreHook" then Strength.AddStrength=original;return true end
end
