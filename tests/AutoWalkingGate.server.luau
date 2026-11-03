-- Native isolated check of the restored ordinary-training movement gate.
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local request=Instance.new("RemoteEvent");request.Name="__WalkQARequest";request.Parent=RS
local reply=Instance.new("RemoteEvent");reply.Name="__WalkQAReply";reply.Parent=RS
local answers={}
reply.OnServerEvent:Connect(function(p,id,v)answers[id]={P=p,V=v}end)
local report={Checks={},Rows={}}
local function waitFor(fn,t)
 local untilTime=os.clock()+(t or 8)
 repeat local x=fn();if x then return x end task.wait(.01)until os.clock()>untilTime
 error("QA timeout")
end
local function ask(p,action)
 local id=game.HttpService:GenerateGUID(false);request:FireClient(p,id,action)
 local a=waitFor(function()return answers[id]end)
 assert(a.P==p and a.V.OK,tostring(a.V.Value))
end
local function check(ok,label)
 report.Checks[#report.Checks+1]={Label=label,Passed=not not ok};assert(ok,label)
end
local function root(p)return p.Character.HumanoidRootPart end
local function hum(p)return p.Character.Humanoid end
local function lobby(p,w)
 D.SetAutoTapEnabled(p,false)
 Enemy.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p)
 p:SetAttribute("CurrentWorld",w);Enemy.ForWorld(w).Activate(p)
 local f=workspace[w==1 and "GeneratedMap" or "World2Map"].TrainingArea.Floor
 root(p).Anchored=true;root(p).CFrame=CFrame.new(f.Position+Vector3.new(0,f.Size.Y/2+hum(p).HipHeight+root(p).Size.Y/2,0))
 root(p).AssemblyLinearVelocity=Vector3.zero
 task.wait(.25)
end
local function sample(p,w,label,action,expected)
 local before=p:GetAttribute("Strength")
 action()
 local delta=p:GetAttribute("Strength")-before
 report.Rows[#report.Rows+1]={World=w,Case=label,Delta=delta}
 check(expected(delta),label.." "..delta)
end
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==2 end,40)
 local ps=game.Players:GetPlayers()
 for _,p in ps do
  waitFor(function()return D.Get(p) and D.Get(p).Loaded and p.Character and p.Character:GetAttribute("SpawnEngineReady") and p.Character:GetAttribute("MuscleScaleReady")end,40)
  D.SetAutoTapEnabled(p,false)
  D.Get(p).Data.SelectedSizeTier=1;p:SetAttribute("SelectedSizeTier",1)
 end
 local p=ps[1]
 for _,w in {1,2} do
  lobby(p,w);D.SetAutoTapEnabled(p,true)
  sample(p,w,"Stationary Auto ON",function()task.wait(1.1)end,function(n)return n==0 end)
  sample(p,w,"Stationary manual with Auto ON",function()ask(p,"Tap")end,function(n)return n==1 end)
  sample(p,w,"Still stationary after manual",function()task.wait(.7)end,function(n)return n==0 end)
  local position=root(p).Position;root(p).Anchored=false;root(p):SetNetworkOwnershipAuto()
  sample(p,w,"Actual walking Auto ON",function()ask(p,"Walk")end,function(n)return n>=2 and n<=4 end)
  check((root(p).Position-position).Magnitude>2,"actual displacement")
  task.wait(.25)
  sample(p,w,"Stopped after walking",function()task.wait(.7)end,function(n)return n==0 end)
  D.SetAutoTapEnabled(p,false);task.wait(.2)
  sample(p,w,"Actual walking Auto OFF",function()ask(p,"Walk")end,function(n)return n==0 end)
  sample(p,w,"Stationary manual Auto OFF",function()ask(p,"Tap")end,function(n)return n==1 end)
  -- Stationary automatic combat must remain above the movement gate.
  lobby(p,w);D.SetCurrentStrength(p,1)
  local e=Enemy.ForWorld(w);local wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(w)
  e.StartRun(p,1);local target=wall.GetCurrentWallForStage(p,1)
  root(p).CFrame=CFrame.new(target.Wall.Position+Vector3.new(0,0,3));task.wait(.2)
  D.SetAutoTapEnabled(p,true)
  local hp=wall.GetGaugeForStage(p,1,1);task.wait(1.25)
  local damage=hp-wall.GetGaugeForStage(p,1,1)
  check(damage>=2 and damage<=3,"stationary automatic wall still works")
  report.Rows[#report.Rows+1]={World=w,Case="Stationary wall Auto ON",Damage=damage}
  D.SetAutoTapEnabled(p,false)
 end
end,debug.traceback)
report.Passed=ok;report.Error=not ok and err or nil
game:GetService("StudioTestService"):EndTest(report)
