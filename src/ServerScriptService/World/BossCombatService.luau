local contexts={}
local function forWorld(worldId)
 assert(worldId==1 or worldId==2,"Unsupported world")
 if contexts[worldId] then return contexts[worldId] end
-- Both Worlds use real Strength damage with independent balance tables.
-- Ordinary Cancel retains snapshots; Stop(heal=true) retires unfinished encounters.
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local ItemService=require(game.ServerScriptService.Services.ItemService)
local BossConfig=require(game:GetService("ReplicatedStorage").Config:WaitForChild("World1BossConfig"))
local WorldBalance=worldId==2 and require(game.ReplicatedStorage.Config.World2BossConfig) or BossConfig
local M={}
local CombatConfig=require(game.ReplicatedStorage.Config:WaitForChild("CombatConfig"))
M.MaxAttackCount=nil -- Same unlimited attack count as current World1.
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
function M.GetStageConfig(stage) return M.StageConfig[stage] end
-- Legacy helper retained for archived LevelCombatTests only; not used by encounters.
function M.GetWinChance(level,recommended)
 return math.clamp(1-(recommended-level)*0.2,0,1)
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
 local route="STRENGTH_DAMAGE"
 s={Boss=boss,Stage=stage,MaxHP=config.MaxHP,HP=config.MaxHP,Strength=damage,
  BattleStartStrength=damage,GloveBonus=gloveBonus,BattleDamage=battleDamage,
  PlayerLevel=level,RecommendedLevel=config.RecommendedLevel,RequiredStrength=config.RequiredStrength,
  StrengthRatio=ratio,Route=route,Attacks=0,Completed=false}
 local carry=pending[player]
 if carry and carry.Stage==stage then
  s.HP=math.max(0,s.HP-carry.Damage)
  pending[player]=nil
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
 s.HP=math.max(0,s.HP-s.BattleDamage)
 if s.HP<=0 then s.Completed=true;return "Win",s end
 return "Active",s
end
function M.QueueDamage(player,boss,stage,maxHP,damage)
 pending[player]={Boss=boss,Stage=stage,Damage=math.max(0,tonumber(damage) or 0)}
 -- Expose the carry result without taking an early combat/Glove snapshot.
 return math.max(0,M.StageConfig[stage].MaxHP-pending[player].Damage)
end
-- Called by the shared Player/Boss heal path; completed encounters must not revive.
function M.ResetEncounterForHeal(player,stage)
 local saved=encounters[player]
 local s=saved and saved[stage]
 if not s or s.Completed or s.HP<=0 then return nil end
 if active[player]==s then active[player]=nil end
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
