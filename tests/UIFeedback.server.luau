-- QA only: install with tests/World1Ore/Memory.luau replacing all DataStore/Badge consumers.
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
repeat task.wait(.1) until D.Get(p) and D.Get(p).Loaded
D.SetAutoTapEnabled(p,false)
local q=Instance.new("BindableFunction");q.Name="__SEQA";q.Parent=game.ServerStorage
q.OnInvoke=function(action)
 local s=D.Get(p);local d=s.Data
 if action=="Prepare" then
  D.SetWin(p,10000000);d.Level=100;d.LevelProgress=0;p:SetAttribute("Level",100);p:SetAttribute("LevelProgress",0)
  d.RebirthCount=0;p:SetAttribute("RebirthCount",0);d.TimeRewards.ElapsedSeconds=10000
  d.OwnedOres={ORE_001=20}
  d.OwnedItems={PROTEIN_COMMON_FIRE=5,GLOVE_COMMON_FIRE=2}
  if d.OreMergeTutorial then d.OreMergeTutorial.Completed=true end
  local dumbbell=require(game.ReplicatedStorage.Config.DumbbellItemMaster).GetSorted(1)[2].ItemId
  local aura for _,id in ipairs(require(game.ReplicatedStorage.Config.AuraConfig).Order) do
   local c=require(game.ReplicatedStorage.Config.AuraConfig).Get(id)
   if c.PurchaseType=="Win" and c.PurchaseEnabled~=false and not c.LegacyOwnedOnly then aura=id;break end
  end
  return {Dumbbell=dumbbell,Aura=aura,TimeRewards=require(game.ReplicatedStorage.Config.TimeRewardConfig).Rewards}
 elseif action=="Level" then
  local before=d.Level;require(S.StrengthManager).AddRewardStrength(p,100000000)
  return {Before=before,After=d.Level}
 elseif action=="Offline" then
  local State=require(S.StrengthRewardState)
  d.StrengthRewards=State.Checkpoint(d.StrengthRewards,d.StrengthRewards.Owner,100,1000,true)
  d.StrengthRewards=State.Acquire(d.StrengthRewards,"qa-offline",3700)
  p:SetAttribute("StrengthRewardRevision",(p:GetAttribute("StrengthRewardRevision") or 0)+1)
  return d.StrengthRewards.Owner
 elseif action=="Death" then p.Character.Humanoid.Health=0;return true
 elseif action=="State" then return {Win=d.Win,Ores=d.OwnedOres,Items=d.OwnedItems,Level=d.Level,Rebirth=d.RebirthCount,Capacity=d.InventoryCapacity} end
end

