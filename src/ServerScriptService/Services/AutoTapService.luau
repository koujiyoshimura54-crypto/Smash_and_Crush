-- Input routing only. One shared server clock covers successful training and combat.
local Players=game:GetService("Players")
local Services=game.ServerScriptService.Services
local Data=require(Services.PlayerDataService)
local Strength=require(Services.StrengthManager)
local Training=require(Services.TrainingManager)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Timing=require(Services.PlayerActionTiming)
local TrainingConfig=require(game.ReplicatedStorage.Config.TrainingConfig)
local M={}
local toggles=setmetatable({}, {__mode="k"})
local function ready(p)
 local s=Data.Get(p)
 local c=p.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 return p.Parent==Players and s and s.Loaded and h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")~=nil
end
local function treadmill(p)
 return p:GetAttribute("IsTraining")==true or Training.GetOccupiedTreadmill(p)~=nil
end
local function isGroundedWalking(p)
 local h=p.Character:FindFirstChildOfClass("Humanoid")
 local r=p.Character:FindFirstChild("HumanoidRootPart")
 local st=h:GetState()
 if st~=Enum.HumanoidStateType.Running and st~=Enum.HumanoidStateType.RunningNoPhysics then return false end
 return h.MoveDirection.Magnitude>0.05 or Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude>0.5
end
local function act(p,manual)
 if not ready(p) then return false,"NotReady" end
 if not manual and not Data.IsAutoTapEnabled(p) then return false,"AutoDisabled" end
 if not Timing.CanAct(p,manual) then return false,"Cooldown" end
 if treadmill(p) then return false,"Treadmill" end
 local accepted,reason
 if manual then accepted,reason=Enemy.TryManualAttack(p)
 else accepted,reason=Enemy.TryAutomaticAttack(p) end
 if reason~="NoCombat" then return accepted,reason end
 if p:GetAttribute("IsFighting") then return false,"CombatPending" end
 -- Restore the original movement predicate only for automatic ordinary training.
 -- Manual taps and already-routed wall/Boss attacks do not require walking.
 if not manual and not isGroundedWalking(p) then return false,"NotWalking" end
 local before=Strength.GetStrength(p)
 local value,err=Strength.AddStrength(p,TrainingConfig.BaseGain,1)
 if value==nil then return false,err end
 if value<=before then return false,"NoGain" end
 Timing.RecordSuccess(p,manual)
 return true,"Training"
end
function M.HandleTap(p)
 return act(p,true)
end
function M.TryAutomatic(p)
 return act(p,false)
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
