-- Phase 7.5.1: server-only personal Boss drops; no pickup or receipt path.
local Players=game:GetService("Players")
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local WorldDrops=require(game.ServerStorage.Legacy.Modules.BossWorldDropService)
local M={}
local rng=Random.new()
local processed=setmetatable({}, {__mode="k"})
local pool={}
for _,kind in ipairs({"Protein","Glove","TrainingBelt"}) do
 for _,element in ipairs({"Fire","Ice","Electric"}) do
  local id=kind:upper().."_COMMON_"..element:upper()
  local item=Master.Get(id)
  assert(item and item.ItemType==kind and item.Element==element and item.Rarity=="Common","Invalid Boss drop definition: "..id)
  table.insert(pool,id)
 end
end
-- A run is the private EnemyManager state table; mark before any yield.
function M.OnBossDefeated(player,major,substage,run)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if typeof(major)~="number" or major%1~=0 or major<1 or major>10 or substage~=5 then return false,"NotBoss" end
 if typeof(run)~="table" or not run.Defeated or run.Defeated[major]~=true then return false,"NotDefeated" end
 local record=processed[run]
 if not record then record={Player=player,Stages={}};processed[run]=record end
 if record.Player~=player then return false,"InvalidOwner" end
 if record.Stages[major] then return false,"AlreadyProcessed" end
 record.Stages[major]=true
 -- Temporary live-play debug: log the same roll used by the production check.
 local roll=rng:NextNumber()
 if roll>=0.30 then
  print(("[BossItemDrop] Stage = %d.5 | Roll = %.17g | Drop = false"):format(major,roll))
  return true,"NoDrop"
 end
 local itemId=pool[rng:NextInteger(1,#pool)]
 print(("[BossItemDrop] Stage = %d.5 | Roll = %.17g | Drop = true | ItemId = %s"):format(major,roll,itemId))
 -- Only spawn a world object here; ownership changes exclusively on pickup.
 local enemies=workspace:FindFirstChild("Enemies")
 local boss=enemies and enemies:FindFirstChild(("Stage%02d_Enemy"):format(major))
 local root=boss and boss:FindFirstChild("HumanoidRootPart")
 if not root then return false,"BossPositionUnavailable" end
 -- Opposite side from Trophy (+7), outside the combat contact point.
 local position=root.Position-root.CFrame.RightVector*7
 local map=workspace:FindFirstChild("GeneratedMap")
 local corridor=map and map:FindFirstChild("BattleCorridor")
 local stage=corridor and corridor:FindFirstChild(("Stage%02d"):format(major))
 local sub=stage and stage:FindFirstChild(("Stage%d.5"):format(major))
 local floor=sub and sub:FindFirstChild("Floor")
 if floor then position=Vector3.new(position.X,floor.Position.Y+floor.Size.Y/2+2,position.Z) end
 local part,reason=WorldDrops.Spawn(player,itemId,CFrame.new(position))
 if not part then return false,reason end
 return true,"WorldDropSpawned",itemId
end
return M