assert(game.ReplicatedStorage:FindFirstChild("__FirstBattleMemory"))
local Q=game.ReplicatedStorage.__BodyQA
local p=game.Players:GetPlayers()[1]
local D=require(game.ServerScriptService.Services.PlayerDataService)
local C=require(game.ServerScriptService.Config.MuscleScaleConfig)
local R=require(game.ReplicatedStorage.Config.LevelRequirements)
local P=require(game.ServerScriptService.Services.LobbySpawnService)
local E=require(game.ServerScriptService.World.EnemyManager)
local T=require(game.ServerScriptService.Services.TrainingManager)
local Return=require(game.ServerScriptService.Services.RunReturnService)
local S=require(game.ServerScriptService.Services.StageSkipService)
local function waitFor(fn)
 local endAt=os.clock()+30
 repeat if fn() then return end;task.wait(.05) until os.clock()>endAt
 error("Behavior timeout")
end
local function fixture(a)return Q.Server:Invoke("Fixture",a)end
local function measure()return Q.Server:Invoke("Measure")end
local function states()
 local result={Checks=0,Cases={}}
 local function near(a,b,label)result.Checks+=1;assert(math.abs(a-b)<.00002,(label or "")..": "..a.." ~= "..b)end
 local function eq(a,b,label)result.Checks+=1;assert(a==b,(label or "")..": "..tostring(a).." ~= "..tostring(b))end
 local function run(name,fn)
  local ok,err=xpcall(fn,debug.traceback);result.Cases[#result.Cases+1]={Name=name,Passed=ok,Error=not ok and err or nil}
 end
 local base=fixture({Level=1,SelectedSizeTier=0,Strength=0,RebirthCount=0})
 run("all live level boundaries, cap and excluded parts",function()
  for _,lv in {1,2,3,3,4,5,7,8,9,15,16,17,31,32,33,49,50,51,69,70,71,89,90,91,114,115,116,139,140,141,200} do
   local m=fixture({Level=lv});local stage=C.GetMuscleStage(lv);near(m.Height,C.GetHeightScale(stage))
   for name,original in base.Parts do
    local scale=C.GetPartScale(name,stage)
    for i,value in {scale.X,scale.Y,scale.Z} do near(m.Parts[name][i],original[i]*value,name) end
   end
  end
 end)
 run("Strength alone and attribute mirrors cannot select stage",function()
  fixture({Level=1,Strength=0});fixture({Strength=1e12});near(measure().Height,1)
  p:SetAttribute("Level",140);task.wait(.1);near(measure().Height,1)
  p:SetAttribute("Level",1)
 end)
 run("real AddStrengthGain crosses several stages at once",function()
  fixture({Level=1,Strength=0});local d=D.Get(p).Data;d.LevelProgress=0
  local gain=0 for lv=1,31 do gain+=R.GetRequiredStrength(lv,d.LevelCurveVersion) end
  assert(D.AddStrengthGain(p,gain));task.wait(.1);eq(d.Level,32);near(measure().Height,1.8)
 end)
 run("repeated refreshes do not compound part sizes",function()
  local a=fixture({Level=140,SelectedSizeTier=0})
  for _=1,20 do fixture({SelectedSizeTier=1});fixture({SelectedSizeTier=0}) end
  local b=measure();for n,size in a.Parts do for i,v in size do near(v,b.Parts[n][i],n) end end
  near(a.HipHeight,b.HipHeight)
 end)
 run("unloaded profile waits without applying uncertain attributes",function()
  fixture({Level=1});local s=D.Get(p);s.Loaded=false;p:SetAttribute("Level",140);p:SetAttribute("SelectedSizeTier",10)
  task.wait(.1);near(p.Character:GetAttribute("MuscleHeightScale"),1)
  s.Loaded=true;p:SetAttribute("SelectedSizeTier",0);p:SetAttribute("Level",1)
 end)
 for _,tier in {0,10} do
  run("rebirth preserves selection "..tier,function()
   fixture({Level=140,SelectedSizeTier=tier,RebirthCount=0});D.Get(p).Data.LevelProgress=0
   eq(D.TryRebirth(p),true);task.wait(.15);eq(D.Get(p).Data.Level,1)
   near(measure().Height,tier==0 and 1 or 2);eq(D.Get(p).Data.SelectedSizeTier,tier)
  end)
  run("death respawn preserves selection "..tier,function()
   fixture({Level=32,SelectedSizeTier=tier});local old=p.Character;old.HumanoidRootPart.Anchored=false;old.Humanoid.Health=0
   waitFor(function()return p.Character~=old and p.Character and p.Character:GetAttribute("MuscleScaleReady")end)
   near(measure().Height,tier==0 and 1.8 or 2);eq(D.Get(p).Data.SelectedSizeTier,tier)
  end)
  run("world 1 to 2 to 1 with real activation and placement "..tier,function()
   fixture({Level=32,SelectedSizeTier=tier})
   for _,world in {2,1} do
    local old=p:GetAttribute("CurrentWorld") or 1;E.ForWorld(old).Deactivate(p)
    p:SetAttribute("CurrentWorld",world);E.ForWorld(world).Activate(p)
    eq(P.MoveToLobby(p,p.Character,world),true);task.wait(.3)
    near(measure().Height,tier==0 and 1.8 or 2)
   end
  end)
 end
 return result
end
local function treadmill(world)
 local old=p:GetAttribute("CurrentWorld") or 1
 if old~=world then E.ForWorld(old).Deactivate(p);p:SetAttribute("CurrentWorld",world);E.ForWorld(world).Activate(p) end
 local model=world==2 and workspace.World2Map.TrainingArea.TreadmillDisplays["01"] or workspace.Treadmills.Normal01
 local area=model.Area;local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={model};params.RespectCanCollide=true
 local hit=workspace:Raycast(area.Position+Vector3.new(0,30,0),Vector3.new(0,-80,0),params);assert(hit)
 local c=p.Character;local h=c.Humanoid;local root=c.HumanoidRootPart;root.Anchored=false
 root.CFrame=CFrame.new(area.Position.X,hit.Position.Y+h.HipHeight+root.Size.Y/2,area.Position.Z)
 root.AssemblyLinearVelocity=Vector3.zero;task.wait(1)
 local before=measure();local start=os.clock();task.wait(2.2);local after=measure()
 return {World=world,Before=before,After=after,Elapsed=os.clock()-start,Delta=after.Strength-before.Strength,Allowed=T.CanUseTreadmill(p,model),Inside=T.IsPlayerInsideZone(p,area)}
end
local fn=Instance.new("BindableFunction");fn.Name="Behavior";fn.Parent=Q
fn.OnInvoke=function(action,a)
 if action=="States" then return states()
 elseif action=="Treadmill" then return treadmill(a.World)
 elseif action=="Skip" then return {S.BuyWithWin(p,a.Stage)}
 elseif action=="Back" then return {Return.Request(p,p:GetAttribute("RunInventoryId"))}
 elseif action=="NormalAvatar" then return {P.LoadCharacter(p)}
 elseif action=="TravelPrep" then D.Get(p).Data.HighestUnlockedWorld=2;p:SetAttribute("HighestUnlockedWorld",2);return true
 elseif action=="SetWorld" then
  local old=p:GetAttribute("CurrentWorld") or 1;E.ForWorld(old).Deactivate(p);p:SetAttribute("CurrentWorld",a.World);E.ForWorld(a.World).Activate(p)
  return {P.MoveToLobby(p,p.Character,a.World)}
 elseif action=="Attack" then return {E.ForWorld(p:GetAttribute("CurrentWorld") or 1).TryManualAttack(p)}
 elseif action=="BattleState" then
  local e=E.ForWorld(p:GetAttribute("CurrentWorld") or 1);local ps=e.GetPlayerState(p)
  return {Stage=p:GetAttribute("CurrentStage"),Fighting=p:GetAttribute("IsFighting"),HP=p.Character.Humanoid.Health,Defeated=ps.Defeated,Wall=require(game.ServerScriptService.World.Stage1WallManager).GetSnapshot(p)}
 end
end
