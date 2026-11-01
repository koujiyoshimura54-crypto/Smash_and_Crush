-- Temporary native Script, only with __UI2Memory installed.
local RS=game.ReplicatedStorage
local Memory=require(assert(RS:FindFirstChild("__UI2Memory"),"Install the isolated memory adapters before this fixture"))
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Stage=require(game.ServerScriptService.World.StageManager)
local p=game.Players:GetPlayers()[1]
local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local checks={}
local function check(ok,label) assert(ok,label);checks[#checks+1]=label end
local function reload()
 Data.Get(p).Dirty=true;assert(Data.Save(p));Data.Release(p);assert(Data.Load(p))
end
local function legacy(highest,arrived)
 Stage.ResetPlayer(p);p:SetAttribute("CurrentWorld",1)
 Data.Get(p).Dirty=true;assert(Data.Save(p))
 store:UpdateAsync("Player_"..p.UserId,function(raw)
  raw.World1Cleared=nil;raw.HighestUnlockedWorld=highest;raw.World2Visited=arrived;return raw
 end)
 Data.Release(p);assert(Data.Load(p))
end
local probe=Instance.new("BindableFunction");probe.Name="__UI2Persistence"
probe.OnInvoke=function(action)
 if action=="Uncleared" then
  legacy(1,false)
  check(not Data.Get(p).Data.World1Cleared,"No progression proof stays hidden")
 elseif action=="ClearReload" then
  Stage.InitializePlayer(p,10);check(Stage.ClearStage(p,10),"Authoritative Stage10 completion")
  local d=Data.Get(p).Data
  check(d.World1Cleared and d.HighestUnlockedWorld==1 and not d.World2Visited,"Clear unlocks before trophy and arrival")
  reload();d=Data.Get(p).Data
  check(d.World1Cleared and d.HighestUnlockedWorld==1 and not d.World2Visited,"Clear-only save/reload retains unlock")
  Stage.ResetPlayer(p);p:SetAttribute("CurrentWorld",2);p:SetAttribute("CurrentWorld",1)
  check(p:GetAttribute("World1Cleared"),"Run reset and World return retain unlock")
 elseif action=="Legacy" then
  legacy(2,false);check(Data.Get(p).Data.World1Cleared,"Saved gate unlock migration")
  legacy(1,true);check(Data.Get(p).Data.World1Cleared,"Saved arrival migration")
  check(not Data.HasReachedWorld2(p),"Studio arrival preview still separate")
  local badge=require(RS.Config.BadgeConfig).GetBadgeId("World1Complete")
  Memory.BadgeService.UserHasBadgeAsync=function(_,_,id)return id==badge end
  legacy(1,false);task.wait(.2)
  check(Data.Get(p).Data.World1Cleared,"Historical completion badge migration")
  Memory.BadgeService.UserHasBadgeAsync=function()return false end
  reload();check(Data.Get(p).Data.World1Cleared,"Recovered badge proof persisted")
 elseif action=="Death" then
  local old=p.Character;old.Humanoid.Health=0
  local deadline=os.clock()+12
  repeat task.wait(.1) until p.Character~=old or os.clock()>deadline
  check(p.Character~=old and Data.Get(p).Data.World1Cleared,"Death/respawn retains clear flag")
 end
 return {Checks=checks,Cleared=Data.Get(p).Data.World1Cleared,Highest=Data.Get(p).Data.HighestUnlockedWorld,Arrival=Data.HasReachedWorld2(p)}
end
probe.Parent=RS
