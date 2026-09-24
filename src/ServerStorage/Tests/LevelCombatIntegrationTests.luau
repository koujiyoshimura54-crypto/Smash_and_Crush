local T={}
function T.Run()
 local results={}
 local function check(name,fn) fn();table.insert(results,"PASS "..name) end
 local enemySource=game.ServerScriptService.World.EnemyManager.Source
 local first=assert(enemySource:find("local function defeat(p,n)",1,true))
 local last=assert(enemySource:find("function M.Initialize(newMap)",first,true))
 local body=enemySource:sub(first,last-1)
 local bossSource=game.ServerScriptService.World.BossCombatService.Source
 bossSource=bossSource:gsub("require%(script.Parent.StrengthManager%)","{CalculateLevel=require(game.ReplicatedStorage.Config.LevelRequirements).CalculateLevel}")
 bossSource=bossSource:gsub("local rng=Random.new%(%)","local rng={NextNumber=function() Sim.Draws+=1;return Sim.Roll end}")
 local bossFactory=assert(loadstring("return function(Sim) "..bossSource.." end"))()
 local prefix=[==[
local stateData={Gauges={},Defeated={}}
local Players=Sim.Players
local sessions={}
local Boss=Sim.Boss
local Strength={GetStrength=function(p) return p:GetAttribute("Strength") end}
local W={GetServerTimeNow=function() return Sim.Time end}
local token=0
local remote
local M={InitializePlayer=function(p) Sim.Resets=(Sim.Resets or 0)+1;Sim.Boss.Reset(p) end}
local function returnToLobbyAfterLoss(p) M.InitializePlayer(p);Sim.Loads+=1;Sim.Inside=false end
local enemies=Sim.Enemies
local Wall={Config={[1]={}},GetCurrentWallForStage=function() return nil end,IsBossUnlockedForStage=function() return true end}
local Stage={
 GetCurrentStageNumber=function() return Sim.Stage end,
 GetState=function() return {CurrentStage=Sim.Stage,WorldComplete=false} end,
 ClearStage=function() Sim.Clears+=1;Sim.Stage+=1;return true end
}
local Trophy={Spawn=function() Sim.Trophies+=1 end}
local ItemDrops={OnBossDefeated=function() Sim.Drops+=1 end}
local task={}
function task.spawn(fn) Sim.Thread=coroutine.create(fn);assert(coroutine.resume(Sim.Thread)) end
function task.wait() coroutine.yield() end
function task.delay(dt,fn) table.insert(Sim.Delayed,{At=Sim.Time+dt,Fn=fn}) end
local function state() return stateData end
local function send(_,event) table.insert(Sim.Events,{At=Sim.Time,Data=event}) end
local function inside(root,zone) return Sim.Inside end
]==]
 local monitorFactory=assert(loadstring("return function(Sim) "..prefix..body.." monitor();return stateData end"))()
 local function simulation(strength,roll)
  local s={Time=0,Roll=roll,Draws=0,Stage=1,Clears=0,Trophies=0,Drops=0,Loads=0,Events={},Delayed={},Inside=true}
  s.Players={}
  local hum={Health=100}
  local root={Position=Vector3.zero}
  local ch={FindFirstChildOfClass=function() return hum end,FindFirstChild=function() return root end}
  local p={Character=ch,Parent=s.Players,Attributes={Strength=strength}}
  function p:GetAttribute(k) return self.Attributes[k] end
  function p:SetAttribute(k,v) self.Attributes[k]=v end
  function s.Players:GetPlayers() return {p} end
  s.Enemies={[1]={GetAttribute=function() return 800 end,CombatZone={}}}
  s.Boss=bossFactory(s);s.State=monitorFactory(s);s.Player=p;s.Hum=hum
  function s:Step()
   self.Time+=.1
   local pending=self.Delayed;self.Delayed={}
   for _,job in ipairs(pending) do if job.At<=self.Time+1e-9 then job.Fn() else table.insert(self.Delayed,job) end end
   assert(coroutine.resume(self.Thread))
  end
  return s
 end
 check("Actual monitor A: Strength95/120/238/475 produce 5/4/2/1 punches then one defeat; no RNG",function()
  for _,case in ipairs({{95,5},{120,4},{238,2},{475,1}}) do
   local s=simulation(case[1],.99)
   for _=1,70 do s:Step() end
   local attacks,death={},nil
   for _,event in ipairs(s.Events) do
    if event.Data.Type=="CombatAttack" then attacks[#attacks+1]=event end
    if event.Data.Type=="EnemyDefeated" then assert(not death);death=event end
   end
   assert(#attacks==case[2] and death and death.At-attacks[#attacks].At>=.599)
   assert(s.Clears==1 and s.Trophies==1 and s.Drops==1 and s.Draws==0 and s.Hum.Health==100)
  end
 end)
 check("Actual monitor B: Lv4 lottery success produces exactly five punches before victory",function()
  local s=simulation(90,0)
  for _=1,70 do s:Step() end
  local count=0
  for _,event in ipairs(s.Events) do if event.Data.Type=="CombatAttack" then count+=1 end end
  assert(count==5 and s.Clears==1 and s.Trophies==1 and s.Drops==1 and s.Draws==1 and s.Hum.Health==100)
 end)
 check("Actual monitor: failed draw preserves encounter on re-entry then loses after punch5 and resets",function()
  local s=simulation(90,.99)
  for _=1,20 do s:Step() end
  local before=s.Boss.Get(s.Player);assert(before and before.Route=="LOTTERY_MISS")
  s.Inside=false;s:Step()
  for _=1,8 do s:Step() end
  s.Inside=true;s:Step()
  assert(s.Boss.Get(s.Player)==before and s.Draws==1)
  for _=1,100 do s:Step() end
  local count=0
  for _,event in ipairs(s.Events) do if event.Data.Type=="CombatAttack" then count+=1 end end
  assert(count==5 and s.Clears==0 and s.Trophies==0 and s.Drops==0 and s.Hum.Health==100 and s.Draws==1 and s.Resets==1 and s.Loads==1)
  local lastPunch,loss
  for _,event in ipairs(s.Events) do
   if event.Data.Type=="CombatAttack" then lastPunch=event end
   if event.Data.Type=="BossResult" and event.Data.Result=="LOSE" then loss=event end
  end
  assert(loss and lastPunch and loss.At-lastPunch.At>=.599)
 end)
 check("LOSE recovery directly reloads character without requiring Humanoid death",function()
  local loseStart=assert(enemySource:find('elseif status=="Lose" then',1,true))
  local loseEnd=assert(enemySource:find("\n       end)",loseStart,true))
  local loseBranch=enemySource:sub(loseStart,loseEnd)
  assert(loseBranch:find("returnToLobbyAfterLoss(p)",1,true) and not loseBranch:find("p:LoadCharacter()",1,true))
  assert(enemySource:find("humanoid.Health=0",1,true))
  assert(enemySource:find("LOSS_DEATH_DISPLAY_DURATION=0.8",1,true))
  assert(enemySource:find("task.delay(LOSS_DEATH_DISPLAY_DURATION",1,true))
  assert(enemySource:find("p:LoadCharacter()",1,true))
 end)
 check("Actual client punch function: one animation/sound per server ID, duplicate ignored, no independent loop",function()
  local c=game.StarterPlayer.StarterPlayerScripts.Combat.CombatClient.Source
  local start=assert(c:find("local rightTrack,leftTrack",1,true))
  local finish=assert(c:find("local function playDefeatSound()",start,true))
  local punch=c:sub(start,finish-1)
  assert(not punch:find("while",1,true))
  local sim={Animations=0,Sounds=0}
  local animator={}
  function animator:LoadAnimation()
   return {Length=.9,Stop=function() end,Destroy=function() end,Play=function(_,fade,weight,speed) assert(math.abs(speed-1.5)<1e-9);sim.Animations+=1 end}
  end
  local hum={FindFirstChildOfClass=function() return animator end}
  local ch={FindFirstChildOfClass=function() return hum end,FindFirstChild=function() return {} end}
  local fakeInstance={new=function(kind)
   if kind=="Animation" then return {Destroy=function() end} end
   return {Stop=function() end,Destroy=function() end,Play=function() sim.Sounds+=1 end}
  end}
  local source="return function(P,Instance) local sound;local RIGHT_PUNCH_ANIMATION_ID='a';local LEFT_PUNCH_ANIMATION_ID='b';local PUNCH_SOUND_ID='c';"..punch.." return playCombatAttack end"
  local play=assert(loadstring(source))()({Character=ch},fakeInstance)
  for i=1,5 do play({Id=i,Duration=.6});play({Id=i,Duration=.6}) end
  assert(sim.Animations==5 and sim.Sounds==5)
  assert(c:find('l.Text="推奨 Lv."',1,true) and not c:find('l.Text="推奨Strength',1,true))
 end)
 return table.concat(results,"\n")
end
return T