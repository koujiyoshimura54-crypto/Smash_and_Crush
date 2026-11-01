-- Temporary native Play fixture. Requires memory-only DataStore and Badge adapters.
local RS=game.ReplicatedStorage
local memory=require(assert(RS:FindFirstChild("__UI2Memory"),"Install the isolated memory adapters before this fixture"))
local S=game.ServerScriptService.Services
local Data=require(S.PlayerDataService)
local Master=require(RS.Config.ItemMaster)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
repeat task.wait(.1) until Data.Get(p) and Data.Get(p).Loaded and p.Character
Data.SetAutoTapEnabled(p,false)
local s=Data.Get(p)
for id in pairs(Master.GetAll()) do s.Data.OwnedItems[id]=1500 end
s.Data.OwnedOres={ORE_001=999,ORE_002=1000,ORE_003=1500,ORE_004=1000000}
s.Data.OwnedDumbbells.NORMAL_01=1500
s.Dirty=true;assert(Data.Save(p))
-- Normal saves intentionally preserve transaction-owned inventory fields.
local store=memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
store:UpdateAsync("Player_"..p.UserId,function(raw)
 raw.OwnedItems=table.clone(s.Data.OwnedItems);raw.OwnedOres=table.clone(s.Data.OwnedOres)
 raw.OwnedDumbbells=table.clone(s.Data.OwnedDumbbells);return raw
end)
local probe=Instance.new("BindableFunction");probe.Name="__UI2Server"
local function snapshot()
 local d=Data.Get(p).Data
 return {Cleared=d.World1Cleared==true,EffectiveArrival=Data.HasReachedWorld2(p),SavedArrival=d.World2Visited,
  Highest=d.HighestUnlockedWorld,Items=d.OwnedItems,Ores=d.OwnedOres,
  Merge=require(S.ItemMergeService).GetState(p)}
end
probe.OnInvoke=function(action,value)
 if action=="Clear" then
  local Stage=require(game.ServerScriptService.World.StageManager)
  Stage.InitializePlayer(p,10);assert(Stage.ClearStage(p,10))
 elseif action=="Arrive" then
  Data.UnlockWorld(p,2);p:SetAttribute("CurrentWorld",2);Data.MarkWorld2Reached(p);p:SetAttribute("CurrentWorld",1)
 elseif action=="Reload" then
  Data.Get(p).Dirty=true;assert(Data.Save(p));Data.Release(p);assert(Data.Load(p))
 elseif action=="Count" then
  assert(Data.ChangeItemCount(p,value.Id,value.Count-(Data.Get(p).Data.OwnedItems[value.Id] or 0)))
 elseif action=="Legacy" then
  require(game.ServerScriptService.World.StageManager).ResetPlayer(p)
  local memory=require(RS.__UI2Memory)
  local store=memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
  local d=Data.Get(p).Data
  Data.Get(p).Dirty=true;assert(Data.Save(p))
  store:UpdateAsync("Player_"..p.UserId,function(raw)
   raw.World1Cleared=nil;raw.HighestUnlockedWorld=value.Highest;raw.World2Visited=value.Arrived
   return raw
  end)
  Data.Release(p);assert(Data.Load(p))
 elseif action=="Death" then
  p.Character.Humanoid.Health=0
 elseif action=="Snapshot" then
 else error("Unsupported test action") end
 return snapshot()
end
probe.Parent=RS
p:SetAttribute("__UI2Ready",true)
