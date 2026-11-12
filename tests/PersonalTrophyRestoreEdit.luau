assert(game.PlaceId==126576845524886)
local factory=assert(loadstring("return function(workspace)\n"..game.ReplicatedStorage.Modules.PersonalTrophyVisibility.Source.."\nend"))()
local results={}
local function settle()task.wait();task.wait()end
local function run(name,rootPart)
 local trash={};local function own(x)table.insert(trash,x);return x end
 local w=own(Instance.new("Folder"));local map=Instance.new("Model");map.Name="GeneratedMap";map.Parent=w
 local corridor=Instance.new("Model");corridor.Name="BattleCorridor";corridor.Parent=map
 local stage=Instance.new("Model");stage.Name="Stage02";stage.Parent=corridor
 local root=own(Instance.new(rootPart and "Part" or "Model"));root.Name=name
 local h=rootPart and root or own(Instance.new("Part"));if h~=root then h.Name="Handle";h.Parent=root end
 h.Transparency=.42;h.LocalTransparencyModifier=.25
 local g=own(Instance.new("BillboardGui"));g.Enabled=true;g.Parent=h
 local disabled=Instance.new("BillboardGui");disabled.Enabled=false;disabled.Parent=h
 local label=Instance.new("TextLabel");label.Visible=false;label.Parent=g
 local light=Instance.new("PointLight");light.Enabled=true;light.Parent=h
 local effect=Instance.new("ParticleEmitter");effect.Enabled=false;effect.Parent=h
 local sound=Instance.new("Sound");sound.Volume=.37;sound.Parent=h
 root.Parent=stage
 local death=own(Instance.new("BindableEvent"));local added=own(Instance.new("BindableEvent"));local removing=own(Instance.new("BindableEvent"));local world=own(Instance.new("BindableEvent"))
 local humanoid={Health=100,Died=death.Event}
 local character={FindFirstChildOfClass=function()return humanoid end,WaitForChild=function()return humanoid end}
 local p={Character=character,World=1,CharacterAdded=added.Event,CharacterRemoving=removing.Event,GetAttribute=function(self)return self.World end,GetAttributeChangedSignal=function()return world.Event end}
 local c=factory(w).Mount(p);settle();c.Handle({Type="Initialize",RunRevision=1})
 local count=0
 local function check(on,context)
  assert(h.LocalTransparencyModifier==(on and .25 or 1),context.." LTM")
  assert(math.abs(h.Transparency-.42)<.00001,context.." Transparency")
  assert(g.Enabled==on and light.Enabled==on,context.." authored enabled")
  assert(not disabled.Enabled and not effect.Enabled and not label.Visible,context.." authored disabled")
  assert(math.abs(sound.Volume-(on and .37 or 0))<.00001,context.." Volume")
  count+=5
 end
 local id=0
 local function grant()id+=1;c.Handle({Type="TrophySpawn",Stage=2,Id=id,StaticButtons=true});settle()end
 local function clear()c.Handle({Type="TrophyRemoved",Id=id});settle()end
 local ok,err=xpcall(function()
 check(false,"unqualified")
 for cycle=1,5 do
  -- Individually nil children plus root release; all retained identities are reused.
  if h~=root then h.Parent=nil end;g.Parent=nil;root.Parent=nil;settle()
  root.Parent=stage;if h~=root then h.Parent=root end;g.Parent=h;settle()
  check(false,"hidden reattachment "..cycle)
  grant();check(true,"grant after hidden reattachment "..cycle)
  root.Parent=nil;settle();root.Parent=stage;settle()
  check(true,"qualified root reattachment "..cycle)
  g.Parent=nil;if h~=root then h.Parent=nil end;settle()
  if h~=root then h.Parent=root end;g.Parent=h;settle()
  check(true,"qualified child reattachment "..cycle)
  clear();check(false,"removed "..cycle)
 end
 grant();humanoid.Health=0;death:Fire();settle();check(false,"death")
 humanoid.Health=100;added:Fire(character);settle();check(false,"respawn remains unqualified")
 grant();p.World=2;world:Fire();settle();check(false,"World2 exclusion")
 p.World=1;world:Fire();settle();check(false,"return remains unqualified")
 grant();c.Handle({Type="TrophyCollected",Id=id});settle();check(false,"collected")
 grant();c.Handle({Type="Initialize",RunRevision=2});settle();check(false,"new run")
 end,debug.traceback)
 c.Destroy()
 for _,x in trash do x:Destroy()end
 assert(ok,err)
 return {Button=name,RootClass=rootPart and "BasePart edge case" or "actual Model shape",Assertions=count,Cycles=5}
end
for _,name in ipairs({"TrophyNormalButton","TrophyDoubleButton"})do
 table.insert(results,run(name,false));table.insert(results,run(name,true))
end
return game:GetService("HttpService"):JSONEncode({Results=results,Mode="Native isolated instances and synthetic lifecycle signals, manual Parent changes; not natural streaming",Cleanup=true})
