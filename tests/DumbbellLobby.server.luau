-- Native two-client isolated Play. Install only with memory persistence/payment stubs.
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local Dumb=require(S.DumbbellService)
local Strength=require(S.StrengthManager)
local Tap=require(S.AutoTapService)
local Training=require(S.TrainingManager)
local Area=require(S.TrainingLobbyAreaService)
local Reference=require(S.StrengthReference)
local Master=require(RS.Config.DumbbellItemMaster)
local Tread=require(RS.Config.TreadmillConfig)
local Placement=require(S.LobbySpawnService)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local report={Cases={},Rows={},Checks={},Kind="Native two clients; memory-only persistence; real training calls"}
local request=Instance.new("RemoteEvent");request.Name="__DumbQARequest";request.Parent=RS
local reply=Instance.new("RemoteEvent");reply.Name="__DumbQAReply";reply.Parent=RS
local answers,records={},{}
reply.OnServerEvent:Connect(function(p,id,r)answers[id]={P=p,R=r}end)
local function waitFor(fn,t)
 local deadline=os.clock()+(t or 8)
 repeat local v=fn();if v then return v end task.wait(.025) until os.clock()>deadline
 error("QA timeout")
end
local function ask(p,action,value)
 local id=game.HttpService:GenerateGUID(false);request:FireClient(p,id,action,value)
 local a=waitFor(function()return answers[id]end,15)
 assert(a.P==p and a.R.OK,tostring(a.R.Value));return a.R.Value
end
local function check(ok,label)
 report.Checks[#report.Checks+1]={Passed=not not ok,Label=label};assert(ok,label)
end
local function run(label,fn)
 if script:GetAttribute("OnlyRemaining") and label~="World2 treadmill boarding/leaving" and not label:find("real walking/Auto",1,true) then return end
 local ok,e=xpcall(fn,debug.traceback);report.Cases[#report.Cases+1]={Label=label,Passed=ok,Error=not ok and e or nil}
 print("__DumbQA",label,ok,not ok and e or "")
end
local rawAdd=Strength.AddStrength
Strength.AddStrength=function(p,amount,ticks,mult)
 local before=p:GetAttribute("Strength")
 local result,reason=rawAdd(p,amount,ticks,mult)
 local rows=records[p] or {};records[p]=rows
 rows[#rows+1]={Delta=(p:GetAttribute("Strength") or before)-before,Amount=amount,Ticks=ticks or 1,Multiplier=mult or 1,
  Lobby=Area.IsInTrainingLobby(p),Equipment=Dumb.GetEquippedDumbbell(p) or "",Result=result,Reason=reason}
 return result,reason
end
local function root(p)return p.Character.HumanoidRootPart end
local function hum(p)return p.Character.Humanoid end
local function area(w)return workspace[w==1 and "GeneratedMap" or "World2Map"].TrainingArea end
local function put(p,position)
 local r=root(p);r.Anchored=true;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;r.CFrame=CFrame.new(position)
 task.wait(.15)
end
local function above(p,part)
 put(p,part.Position+Vector3.new(0,part.Size.Y/2+hum(p).HipHeight+root(p).Size.Y/2,0))
end
local function lobby(p,w)
 D.SetAutoTapEnabled(p,false)
 Enemy.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p)
 p:SetAttribute("CurrentWorld",w);Enemy.ForWorld(w).Activate(p)
 above(p,area(w).Floor)
 check(Area.IsInTrainingLobby(p),"W"..w.." Lobby bounds")
 waitFor(function()return not p:GetAttribute("IsTraining")end)
end
local function equip(p,id)
 waitFor(function()return not D.Get(p).Saving end)
 local ok,why
 if id=="" then ok,why=Dumb.UnequipDumbbell(p) else ok,why=Dumb.EquipDumbbell(p,id) end
 assert(ok,tostring(why))
end
local function sample(p,label,id,mode)
 equip(p,id);task.wait(.3)
 local count=#(records[p] or {});local before=p:GetAttribute("Strength")
 if mode=="Treadmill" then task.wait(1.1)
 elseif mode=="WalkingAuto" then
  D.SetAutoTapEnabled(p,true);root(p).Anchored=false
  local start=root(p).Position;ask(p,"Walk",Vector3.new(0,0,1))
  report.Checks[#report.Checks+1]={Label=label.." moved",Passed=(root(p).Position-start).Magnitude>.1,Distance=(root(p).Position-start).Magnitude}
  D.SetAutoTapEnabled(p,false);root(p).Anchored=true;task.wait(.2)
 else ask(p,"Tap");task.wait(.1) end
 local gained=p:GetAttribute("Strength")-before
 local rows=records[p] or {};check(#rows>count,label.." reached normal server gain")
 local expected,sum,ticks=0,0,0
 for n=count+1,#rows do
  local r=rows[n]
  local bonus=r.Lobby and id~="" and Master.Get(id).StrengthBonus or 0
  local value=(r.Amount+bonus*r.Ticks)*r.Multiplier
  check(math.abs(r.Delta-value)<1e-6,label.." per-call gain")
  expected+=value;sum+=r.Delta;ticks+=r.Ticks
 end
 check(math.abs(gained-expected)<1e-6,label.." actual delta")
 report.Rows[#report.Rows+1]={World=p:GetAttribute("CurrentWorld"),Case=label,Mode=mode or "ManualRemote",Item=id,
  Expected=expected,Measured=gained,Ticks=ticks,PerTick=expected/ticks,Calls=#rows-count,Equipped=Dumb.GetEquippedDumbbell(p)}
 return gained
end
local ended=false
local function finish()
 if ended then return end;ended=true;Strength.AddStrength=rawAdd
 report.Passed=true;for _,c in report.Cases do if not c.Passed then report.Passed=false end end
 for _,c in report.Checks do if not c.Passed then report.Passed=false end end
 game:GetService("StudioTestService"):EndTest(report)
end
task.delay(220,function()report.Cases[#report.Cases+1]={Label="watchdog",Passed=false};finish()end)
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==2 end,40)
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local p,peer=players[1],players[2]
 for _,x in players do
  waitFor(function()return D.Get(x) and D.Get(x).Loaded and x.Character and x.Character:FindFirstChild("HumanoidRootPart") and x.Character:GetAttribute("MuscleScaleReady") and x.Character:GetAttribute("SpawnEngineReady")end,40)
  D.SetAutoTapEnabled(x,false);ask(x,"Ready")
  local d=D.Get(x).Data
  d.SelectedSizeTier=1;x:SetAttribute("SelectedSizeTier",1)
  for _,id in {"NORMAL_01","NORMAL_02","W2_NORMAL_01","W2_NORMAL_02"} do d.OwnedDumbbells[id]=1 end
  D.UnlockWorld(x,2);D.MarkWorld2Reached(x)
  check(require(S.ItemService).GetProteinBonus(x)==0 and require(S.AuraService).GetStrengthBonus(x)==0
   and require(S.PetServer).GetStrengthMultiplier(x)==1 and Strength.GetStrengthGainMultiplier(x)==1
   and require(S.GamePassService).GetVIPStrengthMultiplier(x)==1 and require(S.PotionService).GetStrengthMultiplier(x)==1,"other boosts fixed")
 end
 lobby(peer,1);equip(peer,"NORMAL_01")
 for _,w in {1,2} do
  local ids=w==1 and {"","NORMAL_01","NORMAL_02"} or {"","W2_NORMAL_01","W2_NORMAL_02"}
  local reference
  run("World"..w.." Lobby/manual/carpet",function()
   lobby(p,w)
   for _,id in ids do sample(p,"Lobby center",id) end
   reference=Reference.Get(p)
   local path=area(w).PathToTreadmills.Upper
   above(p,path);sample(p,"Red carpet",ids[3])
   check(Reference.Get(p)==reference,"reference unchanged on carpet")
  end)
  run("World"..w.." treadmill boarding/leaving",function()
   lobby(p,w);equip(p,ids[3]);reference=Reference.Get(p)
   local m=w==1 and workspace.Treadmills.Normal01 or area(w).TreadmillDisplays["01"]
   local zone=m.Area
   local foot=p.Character:FindFirstChild("LeftFoot")
   local offset=foot and root(p).Position.Y-(foot.Position.Y-foot.Size.Y/2) or hum(p).HipHeight+root(p).Size.Y/2
   put(p,zone.Position+Vector3.new(0,offset,0))
   waitFor(function()return Training.IsPlayerInsideZone(p,zone) and p:GetAttribute("IsTraining")==true end)
   for _,id in ids do sample(p,"Treadmill "..m.Name,id,"Treadmill") end
   check(Reference.Get(p)==reference,"reference unchanged while on treadmill")
   above(p,area(w).PathToTreadmills.Upper)
   waitFor(function()return not p:GetAttribute("IsTraining")end)
   sample(p,"After leaving treadmill",ids[3])
  end)
  run("World"..w.." Battle and return",function()
   lobby(p,w)
   local f=workspace[w==1 and "GeneratedMap" or "World2Map"].BattleCorridor.Stage01.Floor
   put(p,f.CFrame:PointToWorldSpace(Vector3.new(f.Size.X*.35,hum(p).HipHeight+root(p).Size.Y/2+f.Size.Y/2,-f.Size.Z*.35)))
   check(not Area.IsInTrainingLobby(p),"Battle excludes Dumbbell")
   for _,id in ids do sample(p,"Battle",id) end
   check(Reference.Get(p)==reference,"reward reference stays equipment-based in Battle")
   assert(Placement.MoveToLobby(p,p.Character,w));task.wait(.35);root(p).Anchored=true
   check(Area.IsInTrainingLobby(p),"return to Lobby")
   sample(p,"Returned Lobby",ids[3])
  end)
  run("World"..w.." real walking/Auto",function()
   for _,id in ids do lobby(p,w);sample(p,"Walking Auto",id,"WalkingAuto") end
  end)
  run("World"..w.." death/respawn",function()
   lobby(p,w);equip(p,ids[3])
   local old=p.Character;hum(p).Health=0
   waitFor(function()return p.Character and p.Character~=old and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:GetAttribute("MuscleScaleReady") and p.Character:GetAttribute("SpawnEngineReady")end,20)
   task.wait(.6);root(p).Anchored=true
   check(Dumb.GetEquippedDumbbell(p)==ids[3],"equipment retained after death")
   check(Area.IsInTrainingLobby(p),"respawn Lobby recognized")
   sample(p,"Death respawn",ids[3])
  end)
 end
 run("independent real peer",function()
  local before=peer:GetAttribute("Strength");local eq=Dumb.GetEquippedDumbbell(peer)
  lobby(p,2);sample(p,"Player one W2", "W2_NORMAL_02")
  check(peer:GetAttribute("Strength")==before and Dumb.GetEquippedDumbbell(peer)==eq,"peer unchanged")
  sample(peer,"Player two W1","NORMAL_01")
 end)
 run("actual World travel Remote",function()
  lobby(p,1);equip(p,"NORMAL_02")
  local gate=workspace:FindFirstChild(require(RS.Config.WorldGateConfig).GateName)
  put(p,gate.WorldGateTrigger.Position);ask(p,"Travel",2)
  waitFor(function()return p:GetAttribute("CurrentWorld")==2 end,15);task.wait(.6)
  root(p).Anchored=true;sample(p,"Travel to W2","NORMAL_02")
  task.wait(1.1)
  put(p,area(2).World1ReturnGate.WorldGateTrigger.Position);ask(p,"Travel",1)
  waitFor(function()return p:GetAttribute("CurrentWorld")==1 end,15);task.wait(.6)
  root(p).Anchored=true;sample(p,"Travel to W1","NORMAL_02")
 end)
 report.Clients={ask(p,"Gains"),ask(peer,"Gains")}
end,debug.traceback)
if not ok then report.Cases[#report.Cases+1]={Label="setup",Passed=false,Error=err}end
finish()

