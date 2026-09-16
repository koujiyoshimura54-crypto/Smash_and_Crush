-- World1 Boss-config encounters. Each boss decision survives leaving its zone.
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local ItemService=require(game.ServerScriptService.Services.ItemService)
local BossConfig=require(game:GetService("ReplicatedStorage").Config:WaitForChild("World1LateStageConfig"))
local M={}
local CombatConfig=require(game.ReplicatedStorage.Config:WaitForChild("CombatConfig"))
M.MaxAttackCount=CombatConfig.MaxAttackCount
M.AttackInterval=CombatConfig.AttackInterval
M.AttackDuration=0.6
M.StageConfig={}
for stage=1,BossConfig.StageCount do
	local level=BossConfig.GetRecommendedLevel(stage)
	local required=assert(BossConfig.GetRequiredStrength(stage),"Missing World1 Boss strength")

	M.StageConfig[stage]=table.freeze({
		RecommendedLevel=level,
		RequiredStrength=required,
		MaxHP=BossConfig.GetMaxHP(stage)
	})
end
table.freeze(M.StageConfig)
local active=setmetatable({}, {__mode="k"})
local encounters=setmetatable({}, {__mode="k"})
local pending=setmetatable({}, {__mode="k"})
local rng=Random.new()
function M.GetStageConfig(stage) return M.StageConfig[stage] end
-- Legacy helper retained for archived LevelCombatTests only; not used by encounters.
function M.GetWinChance(level,recommended)
 return math.clamp(1-(recommended-level)*0.2,0,1)
end
-- Ratio is based on raw BattleStartStrength, before Glove and wall carryover.
function M.GetStrengthRatioWinChance(ratio)
 return BossConfig.GetLotteryWinChance(ratio)
end
function M.Begin(player,boss,stage)
 local config=assert(M.StageConfig[stage],"Invalid combat stage")
 local saved=encounters[player]
 if not saved then saved={};encounters[player]=saved end
 local s=saved[boss]
 if s then active[player]=s;return s end
 local damage=math.max(0,tonumber(player:GetAttribute("Strength")) or 0)
 local gloveBonus=ItemService.GetGloveBossDamageBonus(player)
 local battleDamage=damage*(1+gloveBonus)
 local level=Strength.GetLevel(player)
 local ratio=damage/config.RequiredStrength
 local chance=M.GetStrengthRatioWinChance(ratio)
 local roll
 local route
 if ratio>=1 then
  route="LEVEL_DAMAGE" -- A: no lottery, ordinary damage, no five-hit clamp.
 else
  route="LOTTERY_MISS" -- C: ordinary damage with a five-attack limit.
  if chance>0 then
   roll=rng:NextNumber()
   if roll<chance then route="LOTTERY_WIN" end -- B only: fixed five attacks.
  end
 end
 s={Boss=boss,Stage=stage,MaxHP=config.MaxHP,HP=config.MaxHP,Strength=damage,
  BattleStartStrength=damage,GloveBonus=gloveBonus,BattleDamage=battleDamage,
  PlayerLevel=level,RecommendedLevel=config.RecommendedLevel,RequiredStrength=config.RequiredStrength,
  StrengthRatio=ratio,Chance=chance,Roll=roll,Route=route,Attacks=0,Completed=false}
 local carry=pending[player]
 if carry and carry.Boss==boss then
  s.HP=math.max(route=="LOTTERY_WIN" and 1 or 0,s.HP-carry.Damage)
  pending[player]=nil
 end
 s.LossPlanned=s.Route=="LOTTERY_MISS" and s.HP-s.BattleDamage*M.MaxAttackCount>0
 saved[boss]=s;active[player]=s
 return s
end
function M.Get(player) return active[player] end
function M.Attack(player)
 local s=active[player]
 if not s then return "Inactive",nil end
 if s.Completed then return "Complete",s end
 s.Attacks+=1
 if s.Route=="LOTTERY_WIN" then
  s.HP=s.Attacks>=M.MaxAttackCount and 0 or math.max(1,s.HP-s.Strength)
 else
  s.HP=math.max(0,s.HP-s.BattleDamage)
 end
 if s.HP<=0 then s.Completed=true;return "Win",s end
 if s.Route=="LOTTERY_MISS" and s.Attacks>=M.MaxAttackCount then
  s.Completed=true;return "Lose",s
 end
 return "Active",s
end
function M.QueueDamage(player,boss,stage,maxHP,damage)
 pending[player]={Boss=boss,Stage=stage,Damage=math.max(0,tonumber(damage) or 0)}
end
function M.Cancel(player) active[player]=nil end
function M.End(player) active[player]=nil;pending[player]=nil end
function M.Reset(player) active[player]=nil;pending[player]=nil;encounters[player]=nil end
return M
