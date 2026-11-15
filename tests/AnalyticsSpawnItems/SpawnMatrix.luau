-- Exact spawn service with a deterministic scheduler, fake Players/engine and geometry adapters.
-- These departure boundaries are simulations, not actual network disconnects.
return function(source)
 local checks=0;local cases={}
 local function check(ok,label)checks+=1;assert(ok,label)end
 local function fixture(options)
  options=options or {}
  local F={Now=0,Jobs={},Warnings={},Moves={},PlayersList={}}
  local tasks={}
  local function schedule(fn,delay,...)
   local co=type(fn)=="thread" and fn or coroutine.create(fn)
   local job={Co=co,At=F.Now+delay,Args=table.pack(...)};table.insert(F.Jobs,job);return job
  end
  function tasks.spawn(fn,...)return schedule(fn,0,...)end
  tasks.defer=tasks.spawn
  function tasks.delay(dt,fn,...)return schedule(fn,dt,...)end
  function tasks.wait(dt)return coroutine.yield(dt or .01)end
  function tasks.cancel(job)job.Cancelled=true end
  local function signal()
   local s={Connections={},Waiting={}}
   function s:Connect(fn)
    local c={Connected=true,Fn=fn};function c:Disconnect()self.Connected=false end
    table.insert(self.Connections,c);return c
   end
   function s:Once(fn)local c;c=self:Connect(function(...)c:Disconnect();fn(...)end);return c end
   function s:Fire(...)
    for _,c in self.Connections do if c.Connected then tasks.spawn(c.Fn,...)end end
    for _,co in self.Waiting do schedule(co,0,...)end;table.clear(self.Waiting)
   end
   function s:Wait()table.insert(self.Waiting,coroutine.running());return coroutine.yield("signal")end
   return s
  end
  function F.Advance(dt)
   local finish=F.Now+dt;local guard=0
   while true do
    table.sort(F.Jobs,function(a,b)return a.At<b.At end)
    local j=F.Jobs[1];if not j or j.At>finish then break end
    table.remove(F.Jobs,1);F.Now=j.At
    if not j.Cancelled then
     local ok,wait=coroutine.resume(j.Co,table.unpack(j.Args,1,j.Args.n));assert(ok,wait)
     if coroutine.status(j.Co)~="dead"and wait~="signal"then
      j.At=F.Now+(tonumber(wait)or .01);j.Args=table.pack();table.insert(F.Jobs,j)
     end
    end
    guard+=1;assert(guard<2000,"Scheduler did not settle")
   end
   F.Now=finish
  end
  local players={PlayerAdded=signal(),PlayerRemoving=signal(),RespawnTime=2,GetPlayers=function()return F.PlayersList end}
  local readyRemote={OnServerEvent=signal()}
  local remotes={WaitForChild=function()return readyRemote end,FindFirstChild=function()return readyRemote end}
  local rs={WaitForChild=function()return remotes end}
  local workspace={}
  local fakeGame={ServerScriptService={Services={FirstPlayAnalyticsService=true}},GetService=function(_,name)
   return ({Players=players,Workspace=workspace,ReplicatedStorage=rs,RunService={Heartbeat=signal()}})[name]
  end}
  local env=setmetatable({game=fakeGame,workspace=workspace,os={clock=function()return F.Now end},task=tasks,
   require=function()return {Placed=function()end}end,warn=function(x)table.insert(F.Warnings,x)end,
   Instance={new=function(class)
    assert(class=="BindableEvent");local event=signal()
    return {Event=event,Fire=function(_,...)event:Fire(...)end,Destroy=function()table.clear(event.Waiting)end}
   end}
  },{__index=getfenv()})
  local fn=assert(loadstring(source));setfenv(fn,env);local M=fn();F.M=M
  local marker={Position=Vector3.zero,IsA=function(_,c)return c=="SpawnLocation"end}
  M.GetLobby=function()return marker,{},{}end
  -- Keep real ConfigureRespawn, CancelPending, StreamLobby and LoadCharacter.
  M.MoveToLobby=function(p,c,w)
   check(c:GetAttribute("SpawnEngineReady")and c:GetAttribute("MuscleScaleReady"),"Body readiness precedes placement")
   local r=M.CancelPending(p);assert(r);table.insert(F.Moves,{Player=p,Character=c,World=w})
   return true
  end
  function F.Character()
   local root={Anchored=false,Parent=true};local hum={Health=100,Died=signal()}
   local c={HumanoidRootPart=root,Humanoid=hum,Attrs={MuscleScaleReady=options.ScaleReady~=false},Signals={}}
   function c:FindFirstChild(k)return self[k]end
   function c:FindFirstChildOfClass()return hum end
   function c:IsDescendantOf()return true end
   function c:GetAttribute(k)return self.Attrs[k]end
   function c:SetAttribute(k,v)self.Attrs[k]=v;if self.Signals[k]then self.Signals[k]:Fire()end end
   function c:GetAttributeChangedSignal(k)self.Signals[k]=self.Signals[k]or signal();return self.Signals[k]end
   return c
  end
  function F.Player(id)
   local p={UserId=id or -1,Parent=players,CharacterAdded=signal(),CharacterRemoving=signal(),Attrs={CurrentWorld=options.World or 1},Signals={},Loads=0,Streams=0}
   function p:GetAttribute(k)return self.Attrs[k]end
   function p:SetAttribute(k,v)self.Attrs[k]=v;if self.Signals[k]then self.Signals[k]:Fire()end end
   function p:GetAttributeChangedSignal(k)self.Signals[k]=self.Signals[k]or signal();return self.Signals[k]end
   function p:LoadCharacterAsync()
    self.Loads+=1;tasks.wait(.2)
    if self.Removing or self.Fail then error(self.Fail and "Injected connected failure"or"player not in world")end
    if self.Character then self.CharacterRemoving:Fire(self.Character)end
    self.Character=F.Character();self.CharacterAdded:Fire(self.Character);tasks.wait(.1)
   end
   function p:RequestStreamAroundAsync()self.Streams+=1;tasks.wait(options.StreamDelay or .2);if self.Removing then error("Stream cancelled")end end
   table.insert(F.PlayersList,p);return p
  end
  function F.Remove(p)p.Removing=true;players.PlayerRemoving:Fire(p)end
  function F.Add(p)players.PlayerAdded:Fire(p)end
  F.Players=players
  F.Spawn=tasks.spawn
  return F
 end
 do
  local f=fixture();f.M.Start();local p=f.Player();f.Remove(p);f.Advance(.01);f.Add(p);f.Advance(1)
  check(p.Parent==f.Players and p.Loads==0 and not f.M.ConfigureRespawn(p,1),"Removal before load, Parent still Players")
  table.insert(cases,"before load")
 end
 for _,phase in {"load","scale","stream","respawn"}do
  local f=fixture({ScaleReady=phase~="scale",StreamDelay=phase=="stream"and 3 or .2})
  local p=f.Player();f.M.Start()
  if phase=="load"then f.Advance(.1)
  elseif phase=="scale"then f.Advance(.5)
  elseif phase=="stream"then f.Advance(.6)
  else f.Advance(1);p.Character.Humanoid.Health=0;p.Character.Humanoid.Died:Fire();f.Advance(.1)end
  local moves=#f.Moves;local c=p.Character
  f.Remove(p);f.Advance(5)
  check(p.Loads==1 and #f.Moves==moves,"No continuation/respawn on exit "..phase)
  check(#f.Warnings==0,"Departure not reported as connected load failure "..phase)
  if c then check(not c.HumanoidRootPart.Anchored,"Exit restores owned anchor "..phase)end
  check(not f.M.LoadCharacter(p),"Departed Player rejected after all waits "..phase)
  table.insert(cases,phase)
 end
 for _,world in {1,2}do
  local f=fixture({World=world});local p=f.Player();f.M.Start();f.Advance(.35)
  check(not f.M.LoadCharacter(p)and p.Loads==1,"No duplicate load while streaming")
  f.Advance(1);check(#f.Moves==1 and f.Moves[1].World==world,"Normal join World"..world)
  p.Character.Humanoid.Health=0;p.Character.Humanoid.Died:Fire();f.Advance(4)
  check(p.Loads==2 and #f.Moves==2 and f.Moves[2].World==world,"Normal death respawn World"..world)
 end
 do
  local f=fixture({StreamDelay=2});local old=f.Player(-9);f.M.Start();f.Advance(.1);f.Remove(old)
  local rejoin=f.Player(-9);local other=f.Player(-10);f.Add(rejoin);f.Add(other);f.Advance(4)
  check(old.Loads==1 and rejoin.Loads==1 and other.Loads==1 and #f.Moves==2,"Old Player cleanup independent of same UserId/new Player and other player")
 end
 do
  local f=fixture();local p=f.Player();p.Fail=true;f.M.Start();f.Advance(1)
  check(#f.Warnings==1 and f.Warnings[1]:find("Injected connected failure",1,true),"Connected generation failure visible")
  p.Fail=false
  -- The caller may explicitly try again; service does not retry automatically.
  check(p.Loads==1,"No automatic retries after genuine failure")
 end
 do
  local f=fixture({ScaleReady=false});local p=f.Player();f.M.Start();f.Advance(.5)
  local old=p.Character;p.CharacterRemoving:Fire(old);p.Character=f.Character();p.CharacterAdded:Fire(p.Character);f.Advance(1)
  old:SetAttribute("MuscleScaleReady",true);f.Advance(.2)
  check(#f.Moves==0 and p.Loads==1,"Old Character readiness cannot place replacement")
 end
 do
  local f=fixture({StreamDelay=15});local p=f.Player();p.Character=f.Character()
  f.Spawn(f.M.PrefetchLobby,p,p.Character,1);f.Advance(1)
  local completed=false
  f.Spawn(function()completed=f.M.StreamLobby(p,p.Character,1)~=nil end)
  f.Advance(10.1);f.Spawn(f.M.PrefetchLobby,p,p.Character,1);f.Advance(30)
  check(completed and not p.Character.HumanoidRootPart.Anchored,"Superseded prefetch cannot strand streaming wait")
 end
 return {Passed=true,Assertions=checks,Cases=cases,Kind="Simulated lifecycle/engine/stream boundaries; actual service control flow"}
end
