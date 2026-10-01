local contexts={}
local function forWorld(worldId)
 assert(worldId==1 or worldId==2,"Unsupported world")
 if contexts[worldId] then return contexts[worldId] end
-- World1 uses real Strength damage. World2 retains its existing encounter rules.
-- Ordinary Cancel retains snapshots; World1 arena exit explicitly retires its encounter.
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local ItemService=require(game.ServerScriptService.Services.ItemService)
local BossConfig=require(game:GetService("ReplicatedStorage").Config:WaitForChild("World1BossConfig"))
local WorldBalance=worldId==2 and require(game.ReplicatedStorage.Config.World2BossConfig) or BossConfig
local M={}
local CombatConfig=require(game.ReplicatedStorage.Config:WaitForChild("CombatConfig"))
-- The legacy attack limit belongs to World2 only.
M.MaxAttackCount=worldId==2 and CombatConfig.MaxAttackCount or nil
M.AttackInterval=CombatConfig.AttackInterval
M.AttackDuration=0.6
M.StageConfig={}
for stage=1,BossConfig.StageCount do
	local level=WorldBalance.GetRecommendedLevel(stage)
	local required=assert(WorldBalance.GetRequiredStrength(stage),"Missing World1 Boss strength")

	M.StageConfig[stage]=table.freeze({
		RecommendedLevel=level,
		RequiredStrength=required,
		MaxHP=WorldBalance.GetMaxHP(stage)
	})
end
table.freeze(M.StageConfig)
local active=setmetatable({}, {__mode="k"})
local encounters=setmetatable({}, {__mode="k"})
local pending=setmetatable({}, {__mode="k"})
local rng=worldId==2 and Random.new() or nil
function M.GetStageConfig(stage) return M.StageConfig[stage] end
-- Legacy helper retained for archived LevelCombatTests only; not used by encounters.
function M.GetWinChance(level,recommended)
 return math.clamp(1-(recommended-level)*0.2,0,1)
end
-- Compatibility for World2 only; World1 never draws or plans a result.
if worldId==2 then
 function M.GetStrengthRatioWinChance(ratio)
  return BossConfig.GetLotteryWinChance(ratio)
 end
end
function M.Begin(player,boss,stage)
 local config=assert(M.StageConfig[stage],"Invalid combat stage")
 local saved=encounters[player]
 if not saved then saved={};encounters[player]=saved end
 local s=saved[stage]
 if s then s.Boss=boss;active[player]=s;return s end
 local damage=math.max(0,tonumber(player:GetAttribute("Strength")) or 0)
 local gloveBonus=ItemService.GetGloveBossDamageBonus(player)
 local battleDamage=damage*(1+gloveBonus)
 local level=Strength.GetLevel(player)
 local ratio=damage/config.RequiredStrength
 local chance,roll
 local route=worldId==1 and "STRENGTH_DAMAGE" or "LEVEL_DAMAGE"
 if worldId==2 then
  chance=M.GetStrengthRatioWinChance(ratio)
  if ratio<1 then
   route="LOTTERY_MISS"
   if chance>0 then
    roll=rng:NextNumber()
    if roll<chance then route="LOTTERY_WIN" end
   end
  end
 end
 s={Boss=boss,Stage=stage,MaxHP=config.MaxHP,HP=config.MaxHP,Strength=damage,
  BattleStartStrength=damage,GloveBonus=gloveBonus,BattleDamage=battleDamage,
  PlayerLevel=level,RecommendedLevel=config.RecommendedLevel,RequiredStrength=config.RequiredStrength,
  StrengthRatio=ratio,Chance=chance,Roll=roll,Route=route,Attacks=0,Completed=false}
 local carry=pending[player]
 if carry and carry.Stage==stage then
  s.HP=math.max(route=="LOTTERY_WIN" and 1 or 0,s.HP-carry.Damage)
  pending[player]=nil
 end
 if worldId==2 then
  s.LossPlanned=s.Route=="LOTTERY_MISS" and s.HP-s.BattleDamage*M.MaxAttackCount>0
 end
 saved[stage]=s;active[player]=s
 return s
end
function M.Rebind(player,boss,stage)
 local saved=encounters[player]
 local s=saved and saved[stage]
 if not s or s.Completed then return nil end
 s.Boss=boss
 active[player]=s
 return s
end
function M.Get(player) return active[player] end
function M.Attack(player)
 local s=active[player]
 if not s then return "Inactive",nil end
 if s.Completed then return "Complete",s end
 s.Attacks+=1
 if worldId==2 and s.Route=="LOTTERY_WIN" then
  s.HP=s.Attacks>=M.MaxAttackCount and 0 or math.max(1,s.HP-s.Strength)
 else
  s.HP=math.max(0,s.HP-s.BattleDamage)
 end
 if s.HP<=0 then s.Completed=true;return "Win",s end
 if worldId==2 and s.Route=="LOTTERY_MISS" and s.Attacks>=M.MaxAttackCount then
  s.Completed=true;return "Lose",s
 end
 return "Active",s
end
function M.QueueDamage(player,boss,stage,maxHP,damage)
 pending[player]={Boss=boss,Stage=stage,Damage=math.max(0,tonumber(damage) or 0)}
 if worldId==1 then
  -- Expose the carry result immediately without taking an early combat/Glove snapshot.
  return math.max(0,M.StageConfig[stage].MaxHP-pending[player].Damage)
 end
end
-- Only the World1 arena-exit caller may retire a living, unfinished encounter.
function M.ResetEncounterOnArenaExit(player,stage)
 if worldId~=1 then return nil end
 local saved=encounters[player]
 local s=saved and saved[stage]
 if not s or active[player]~=s or s.Completed or s.HP<=0 then return nil end
 active[player]=nil
 saved[stage]=nil -- Begin must take a fresh Strength/Glove snapshot next time.
 return s.MaxHP
end
function M.Cancel(player) active[player]=nil end
function M.End(player) active[player]=nil;pending[player]=nil end
function M.Reset(player) active[player]=nil;pending[player]=nil;encounters[player]=nil end

 contexts[worldId]=M
 M.ForWorld=forWorld
 return M
end
return forWorld(1)
