-- Temporary isolated-Play driver; install only with the memory service adapter.
assert(game.ReplicatedStorage:FindFirstChild("__FirstBattleMemory"))
local RS=game.ReplicatedStorage
local Q=RS:WaitForChild("__BodyQA")
local D=require(game.ServerScriptService.Services.PlayerDataService)
local C=require(game.ServerScriptService.Config.MuscleScaleConfig)
local S=require(RS.Config.SizeChangeConfig)
local P=require(game.ServerScriptService.Services.LobbySpawnService)
local Mem=require(RS.__FirstBattleMemory)
local Store=Mem.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local player=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
repeat task.wait(.1) until D.IsLoaded(player) and player.Character and player.Character:GetAttribute("MuscleScaleReady")
local function waitFor(fn)
 local deadline=os.clock()+30
 repeat if fn() then return end;task.wait(.05) until os.clock()>deadline
 error("Body test timeout")
end
local function settled()
 waitFor(function() local s=D.Get(player);return s and s.Loaded and not s.Saving and not s.PendingItemMutation end)
end
local function vec(v)return {v.X,v.Y,v.Z}end
local function measure()
 local c=player.Character;local h=c:FindFirstChildOfClass("Humanoid");local r=c.HumanoidRootPart
 local parts={};local soles={}
 for _,v in c:GetChildren() do if v:IsA("BasePart") then parts[v.Name]=vec(v.Size) end end
 for _,name in {"LeftFoot","RightFoot"} do
  local v=c[name];local cf=v.CFrame;local e=v.Size*.5
  soles[name]=v.Position.Y-(math.abs(cf.RightVector.Y)*e.X+math.abs(cf.UpVector.Y)*e.Y+math.abs(cf.LookVector.Y)*e.Z)
 end
 local ray=RaycastParams.new();ray.FilterDescendantsInstances={c};ray.FilterType=Enum.RaycastFilterType.Exclude;ray.RespectCanCollide=true
 local hit=workspace:Raycast(r.Position,Vector3.new(0,-40,0),ray)
 local s=D.Get(player)
 return {Level=s.Data.Level,Tier=s.Data.SelectedSizeTier,Strength=s.Data.Strength,Win=s.Data.Win,Rebirth=s.Data.RebirthCount,
  Height=c:GetAttribute("MuscleHeightScale"),HipHeight=h.HipHeight,Root=vec(r.Position),Parts=parts,Soles=soles,
  Ground=hit and hit.Position.Y,GroundName=hit and hit.Instance:GetFullName(),State=h:GetState().Name,Floor=h.FloorMaterial.Name,
  World=player:GetAttribute("CurrentWorld"),Training=player:GetAttribute("IsTraining")}
end
local function fixture(a)
 settled();local d=D.Get(player).Data
 for _,k in {"Level","SelectedSizeTier","Strength","RebirthCount"} do if a[k]~=nil then d[k]=a[k] end end
 -- All saved values are changed before notification, like production load/gain.
 for _,k in {"Strength","SelectedSizeTier","RebirthCount","Level"} do player:SetAttribute(k,d[k]) end
 if a.Win then D.SetWin(player,a.Win) end
 task.wait(.15);return measure()
end
local function saveChecks()
 settled();player.Character.HumanoidRootPart.Anchored=true
 D.Get(player).Dirty=true;assert(D.Save(player))
 local key="Player_"..player.UserId;local original=Store:GetAsync(key)
 local results={Checks=0,Cases={}}
 local function eq(a,b,label)results.Checks+=1;assert(a==b,(label or "")..": "..tostring(a).." ~= "..tostring(b))end
 local function clear()Mem.FailBefore=0;Mem.FailAfter=0;Mem.FailRead=0;Mem.HoldWrites=false end
 local function seed(tier)
  settled();D.Release(player)
  local raw=table.clone(original);raw.SelectedSizeTier=tier;raw.Win=2000;raw.RebirthCount=5
  Store:SetAsync(key,raw);assert(D.Load(player));return D.Get(player).Data
 end
 local function save()settled();D.Get(player).Dirty=true;assert(D.Save(player));return Store:GetAsync(key)end
 local function run(name,fn)
  clear();local ok,err=xpcall(fn,debug.traceback);results.Cases[#results.Cases+1]={Name=name,Passed=ok,Error=not ok and err or nil};clear()
 end
 Mem.TargetKey=key
 for _,old in {0,1,10,11,12,13} do run("load/save/reload legacy "..old,function()
  local d=seed(old);local target=math.min(old,10);eq(d.SelectedSizeTier,target);eq(d.Win,2000)
  local ok,code=D.ChangeSelectedSize(player,target,S);eq(ok,true);eq(code,"SameSize");eq(d.Win,2000)
  local saved=save();eq(saved.SelectedSizeTier,target);eq(saved.Win,2000)
  D.Release(player);assert(D.Load(player));eq(D.Get(player).Data.SelectedSizeTier,target);eq(D.Get(player).Data.Win,2000)
  eq(save().SelectedSizeTier,target)
 end)end
 run("legacy raw 13 inside transaction before normal save",function()
  seed(13);eq(Store:GetAsync(key).SelectedSizeTier,13)
  eq(D.ChangeSelectedSize(player,9,S),true);eq(D.Get(player).Data.Win,1500);eq(Store:GetAsync(key).SelectedSizeTier,9)
  eq(D.ChangeSelectedSize(player,0,S),true);eq(D.Get(player).Data.Win,1500)
 end)
 run("new requests 11 to 13 and invalid values",function()
  seed(10)
  for _,v in {11,12,13,-1,1.5,math.huge,0/0,"10"} do eq(D.ChangeSelectedSize(player,v,S),false) end
  eq(D.Get(player).Data.Win,2000);eq(D.Get(player).Data.SelectedSizeTier,10)
 end)
 run("rebirth unlock and same/manual/auto price",function()
  seed(0);D.Get(player).Data.RebirthCount=4;eq(D.ChangeSelectedSize(player,10,S),false)
  D.Get(player).Data.RebirthCount=5
  eq(D.ChangeSelectedSize(player,10,S),true);eq(D.Get(player).Data.Win,1500)
  eq(D.ChangeSelectedSize(player,10,S),true);eq(D.Get(player).Data.Win,1500)
  eq(D.ChangeSelectedSize(player,1,S),true);eq(D.Get(player).Data.Win,1000)
  eq(D.ChangeSelectedSize(player,0,S),true);eq(D.Get(player).Data.Win,1000)
 end)
 run("migration ordinary save failure and retry",function()
  seed(12);Mem.FailBefore=1;D.Get(player).Dirty=true;eq(D.Save(player),false)
  eq(D.Get(player).Data.SelectedSizeTier,10);eq(D.Get(player).Data.Win,2000)
  eq(save().SelectedSizeTier,10);D.Release(player);assert(D.Load(player));eq(D.Get(player).Data.Win,2000)
 end)
 for _,fault in {"FailBefore","FailAfter"} do run("size mutation "..fault.." retry and ordinary save",function()
  seed(13);Mem[fault]=1;eq(D.ChangeSelectedSize(player,9,S),false)
  eq(D.Get(player).Data.SelectedSizeTier,10);eq(D.Get(player).Data.Win,2000)
  eq(D.ChangeSelectedSize(player,8,S),false);eq(D.SetWin(player,1900),false)
  eq(D.SetWin(player,2007),true)
  local saved=save();eq(saved.SelectedSizeTier,9);eq(saved.Win,1507)
  eq(D.ChangeSelectedSize(player,9,S),true);eq(D.Get(player).Data.Win,1507)
  D.Release(player);assert(D.Load(player));eq(D.Get(player).Data.SelectedSizeTier,9);eq(D.Get(player).Data.Win,1507)
 end)end
 run("acknowledgement loss followed by session departure",function()
  seed(11);Mem.FailAfter=1;eq(D.ChangeSelectedSize(player,8,S),false)
  D.Release(player);assert(D.Load(player));eq(D.Get(player).Data.SelectedSizeTier,8);eq(D.Get(player).Data.Win,1500)
  eq(D.ChangeSelectedSize(player,8,S),true);eq(D.Get(player).Data.Win,1500)
 end)
 run("invalid saved data never converted to new profile",function()
  for _,v in {-1,14,1.5,"10"} do
   D.Release(player);local raw=table.clone(original);raw.SelectedSizeTier=v;Store:SetAsync(key,raw)
   eq(D.Load(player),false);eq(D.IsLoaded(player),false);eq(Store:GetAsync(key).SelectedSizeTier,v)
  end
 end)
 run("new profile defaults",function()
  D.Release(player);Store:RemoveAsync(key);eq(D.Load(player),true);eq(D.Get(player).Data.SelectedSizeTier,0);eq(D.Get(player).Data.Level,1)
 end)
 clear();D.Release(player);Store:SetAsync(key,original);assert(D.Load(player));Mem.TargetKey=nil
 player.Character.HumanoidRootPart.Anchored=false
 return results
end
Q.Server.OnInvoke=function(action,a)
 a=a or {}
 if action=="Measure" then return measure()
 elseif action=="Fixture" then return fixture(a)
 elseif action=="SaveChecks" then return saveChecks()
 elseif action=="ChangeSize" then return {D.ChangeSelectedSize(player,a.Tier,S)}
 elseif action=="Gain" then return {D.AddStrengthGain(player,a.Amount)}
 elseif action=="Rebirth" then return {D.TryRebirth(player)}
 elseif action=="Lobby" then return {P.MoveToLobby(player,player.Character,a.World or 1)}
 elseif action=="Move" then
  local c=player.Character;local root=c.HumanoidRootPart;root.Anchored=false
  root.CFrame=CFrame.new(a.X,a.Y,a.Z);root.AssemblyLinearVelocity=Vector3.zero;return true
 elseif action=="Avatar" then
  local desc=Instance.new("HumanoidDescription")
  if a.Kind=="TallNarrow" then desc.HeightScale=1.05;desc.WidthScale=.7;desc.DepthScale=.7;desc.BodyTypeScale=1;desc.ProportionScale=1
  elseif a.Kind=="Broad" then desc.HeightScale=.9;desc.WidthScale=1;desc.DepthScale=1 end
  player:LoadCharacterWithHumanoidDescriptionAsync(desc);player.Character:SetAttribute("SpawnEngineReady",true)
  waitFor(function()return player.Character:GetAttribute("MuscleScaleReady")end)
  P.MoveToLobby(player,player.Character,1);task.wait(1);return measure()
 elseif action=="Die" then player.Character.Humanoid.Health=0;return true
 elseif action=="Anchor" then player.Character.HumanoidRootPart.Anchored=a.Value;return true
 end
 error("Unknown Body QA action "..action)
end
Q:SetAttribute("Ready",true)
