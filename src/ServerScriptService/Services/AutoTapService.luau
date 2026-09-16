-- Input policy only. Strength and combat calculations stay in their existing services.
local Players=game:GetService("Players")
local Services=game.ServerScriptService.Services
local Data=require(Services.PlayerDataService)
local Strength=require(Services.StrengthManager)
local Training=require(Services.TrainingManager)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Config=require(game.ReplicatedStorage.Config.AutoTapConfig)
local TrainingConfig=require(game.ReplicatedStorage.Config.TrainingConfig)
local M={}
local requests=setmetatable({}, {__mode="k"})
local toggles=setmetatable({}, {__mode="k"})
local trainingHits=setmetatable({}, {__mode="k"})
local function ready(p)
 local s=Data.Get(p)
 local c=p.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 return p.Parent==Players and s and s.Loaded and h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")~=nil
end
local function treadmill(p)
 return p:GetAttribute("IsTraining")==true or Training.GetOccupiedTreadmill(p)~=nil
end
function M.CanAutoTrain(p)
 return ready(p) and Data.IsAutoTapEnabled(p) and not p:GetAttribute("IsFighting") and not treadmill(p)
end
function M.AwardNormalTraining(p,ticks)
 return Strength.AddStrength(p,TrainingConfig.BaseGain*ticks,ticks)
end
function M.HandleTap(p)
 if not ready(p) or Data.IsAutoTapEnabled(p) then return false,"NotManual" end
 local now=os.clock()
 -- Reject spam before contact queries. One input cannot invoke both training and combat.
 local interval=math.min(Config.ManualTapCooldown,Config.ManualAttackCooldown)
 if now-(requests[p] or -math.huge)<interval then return false,"RateLimit" end
 requests[p]=now
 if treadmill(p) then return false,"Treadmill" end
 local accepted,reason=Enemy.TryManualAttack(p)
 if reason~="NoCombat" then return accepted,reason end
 if p:GetAttribute("IsFighting") then return false,"CombatPending" end
 local last=trainingHits[p]
 if last and now-last<Config.ManualTapCooldown then return false,"TrainingCooldown" end
 -- Server-only timestamps are retained across toggle/respawn.
 local value,err=M.AwardNormalTraining(p,1)
 if value==nil then return false,err end
 trainingHits[p]=now
 return true,"Training"
end
function M.Toggle(p)
 local s=Data.Get(p)
 if p.Parent~=Players or not s or not s.Loaded then return false end
 local now=os.clock()
 if now-(toggles[p] or -math.huge)<0.15 then return false end
 toggles[p]=now
 return Data.SetAutoTapEnabled(p,not Data.IsAutoTapEnabled(p))
end
return M
