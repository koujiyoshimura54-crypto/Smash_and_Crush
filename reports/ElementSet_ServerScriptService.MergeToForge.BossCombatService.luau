-- Old World1 STRENGTH_DAMAGE encounter route, limited to Stage01.
local C=require(game.ReplicatedStorage.MergeToForge.Stage01BossConfig)
local Inputs=require(script.Parent.BossCombatInputs)
local states={}
local M={}
function M.Begin(p,boss)
 if states[p] then return states[p] end
 local strength=Inputs.GetStrength(p);local bonus=Inputs.GetGloveBonus(p)
 local hp=C.RequiredStrength*C.HPPerStrength
 local s={Boss=boss,Stage=1,MaxHP=hp,HP=hp,Strength=strength,BattleStartStrength=strength,
 GloveBonus=bonus,BattleDamage=strength*(1+bonus),Route="STRENGTH_DAMAGE",Attacks=0,Completed=false}
 states[p]=s;return s
end
function M.Get(p)
 local s=states[p]
 if s and not s.Completed then
  s.GloveBonus=Inputs.GetGloveBonus(p)
  s.BattleDamage=s.BattleStartStrength*(1+s.GloveBonus)
 end
 return s
end
function M.Attack(p)
 local s=M.Get(p);if not s or s.Completed then return nil end
 local before=s.HP;s.HP=math.max(0,s.HP-s.BattleDamage);s.Attacks+=1
 if s.HP<=0 then s.Completed=true end
 return s,s.HP==0 and "Win" or "Active",before-s.HP
end
function M.ResetEncounterForHeal(p)
 local s=states[p];if s and not s.Completed then states[p]=nil end
end
function M.Reset(p) states[p]=nil end
game.Players.PlayerRemoving:Connect(M.Reset)
return M