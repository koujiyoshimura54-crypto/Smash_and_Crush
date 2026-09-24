local T={}
function T.Run()
 local sandbox=Instance.new("Folder");sandbox.Name="Trophy762Sandbox";sandbox.Parent=game.ServerStorage
 local results={}
 local ok,err=pcall(function()
  local function signal() local s={};function s:Connect(fn) self.Callback=fn;return {Disconnect=function() end} end;return s end
  local players={PlayerRemoving=signal()}
  local heartbeat=signal()
  local events={}
  local remote={FireClient=function(_,p,d) table.insert(events,{Player=p,Data=d}) end}
  local touching=false
  local character=Instance.new("Model");character.Parent=sandbox
  local part=Instance.new("Part");part.Anchored=true;part.Parent=character
  local hum=Instance.new("Humanoid");hum.Parent=character
  local function player()
   local p={UserId=123,Parent=players,Character=character,Values={Win=10}}
   function p:GetAttribute(k) return self.Values[k] end
   function p:SetAttribute(k,v) self.Values[k]=v end
   return p
  end
  local world={GetPartsInPart=function() return touching and {part} or {} end}
  -- Real instances, isolated parenting; no player, live Trophy or DataStore is touched.
  local instance={new=function(class)
   local v=Instance.new(class)
   return v
  end}
  local source=game.ServerScriptService.Services.TrophyRewardService.Source
  local function replace(a,b) local i,j=assert(source:find(a,1,true));source=source:sub(1,i-1)..b..source:sub(j+1) end
  replace('game:GetService("Players")','players')
  replace('game:GetService("RunService")','{Heartbeat=heartbeat}')
  replace('require(game.ServerScriptService.Services:WaitForChild("GamePassService"))','{GetWinReward=function(_,stage) return stage*2 end}')
  replace('hitboxes.Parent = workspace','hitboxes.Parent = sandbox')
  source="return function(players,heartbeat,sandbox,world) local workspace=world\n"..source.."\nend"
  local service=assert(loadstring(source))()(players,heartbeat,sandbox,world)
  local spawn=game.Workspace.GeneratedMap.TrainingArea:FindFirstChildWhichIsA("SpawnLocation",true)
  local reset=0
  service.Initialize(game.Workspace.GeneratedMap,remote,function(p) reset+=1;service.Clear(p) end,function(p,n) return p.Defeated and p.Defeated[n]==true end)
  local function check(name,fn) fn();table.insert(results,"PASS "..name) end
  local p=player();p.Defeated={}
  check("Stage1 unclaimed: Stage2 through Stage10 independently spawn; same-stage duplicates rejected",function()
   for n=1,10 do p.Defeated[n]=true;assert(service.Spawn(p,n));assert(not service.Spawn(p,n)) end
   assert(#sandbox.PersonalTrophyHitboxes:GetChildren()==10 and #events==10)
   for n=1,10 do assert(events[n].Data.Stage==n and events[n].Data.Type=="TrophySpawn") end
  end)
  check("State replay includes all outstanding trophies; another player is independent; skipped stages rejected",function()
   local before=#events;service.SendState(p);assert(#events==before+10)
   local q=player();q.UserId=456;q.Defeated={}
   assert(not service.Spawn(q,3))
   q.Defeated[3]=true;assert(service.Spawn(q,3));service.Clear(q)
   assert(#sandbox.PersonalTrophyHitboxes:GetChildren()==10)
  end)
  check("Collect Stage3: +6 with existing reward multiplier, lobby return, all old run trophies cleaned, no double award",function()
   -- Narrow overlap mock to Stage3 only.
   world.GetPartsInPart=function(_,box) return box:GetAttribute("MajorStage")==3 and {part} or {} end
   heartbeat.Callback(.1)
   assert(p:GetAttribute("Win")==16 and reset==1)
   assert((character:GetPivot().Position-spawn.Position).Magnitude<20)
   assert(#sandbox.PersonalTrophyHitboxes:GetChildren()==0)
   heartbeat.Callback(.1);assert(p:GetAttribute("Win")==16 and reset==1)
  end)
  check("Client shows multiple trophies, dedupes replay and removes only matching ID",function()
   local c=game.StarterPlayer.StarterPlayerScripts.Combat.CombatClient.Source
   local first=assert(c:find("local trophyVisuals={}",1,true))
   local last=assert(c:find("local function wallModel",first,true))
   local funcs=c:sub(first,last-1)
   local ui=assert(loadstring("return function(RS,workspace) "..funcs.." return {Show=showTrophy,Clear=clearTrophy} end"))()(game.ReplicatedStorage,sandbox)
   for n=1,10 do ui.Show({Id=n,Stage=n,CFrame=CFrame.new(n,0,0)}) end
   local function count() local n=0;for _,v in sandbox:GetChildren() do if v.Name=="PersonalTrophy" then n+=1 end end;return n end
   assert(count()==10)
   ui.Show({Id=2,Stage=2,CFrame=CFrame.new()});assert(count()==10)
   ui.Clear(2);assert(count()==9)
   ui.Clear();assert(count()==0)
  end)
 end)
 sandbox:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T