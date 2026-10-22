-- Server owns only intro lifecycle/chase gating. Damage/attacks remain unchanged.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.World2BossAnimationConfig)
local Rig=require(game.ReplicatedStorage.Modules.World2BossRig)
local M={}
local records={}
function M.Register(enemy,stage)
 if not Config.Stages[stage] then return end
 records[enemy]={Stage=stage,Used=false}
 enemy:SetAttribute("BossIntroState","Ready")
end
function M.BeginIntro(enemy)
 local r=records[enemy]
 if not r or r.Stage~=5 or r.Used then return end
 r.Used=true
 local visual=enemy:FindFirstChild("SCP-049")
 local sequence=visual and Rig.Intro(visual,5)
 local duration=sequence and Rig.Duration(sequence) or 0
 if duration<=0 or duration>Config.MaxIntroDuration then
  warn("[World2BossAnimation] Invalid SCP-049 saved Idle; pursuit recovered")
  enemy:SetAttribute("BossIntroState","Failed");return
 end
 r.Start=workspace:GetServerTimeNow();r.Duration=duration
 local owner=Players:GetPlayerByUserId(enemy:GetAttribute("OwnerUserId"))
 r.Character=owner and owner.Character
 enemy:SetAttribute("BossIntroDuration",duration)
 enemy:SetAttribute("BossIntroStartedAt",r.Start)
 enemy:SetAttribute("BossIntroState","Playing")
end
function M.Ready(enemy)
 local r=records[enemy]
 if not r or not r.Start then return true end
 local owner=Players:GetPlayerByUserId(enemy:GetAttribute("OwnerUserId"))
 local hum=owner and owner.Character and owner.Character:FindFirstChildOfClass("Humanoid")
 if not enemy.Parent or not owner or owner.Character~=r.Character or not hum or hum.Health<=0
  or owner:GetAttribute("CurrentWorld")~=2 then
  r.Start=nil;enemy:SetAttribute("BossIntroState","Cancelled");return true
 end
 local elapsed=workspace:GetServerTimeNow()-r.Start
 -- Completion follows the actual stored clip timeline at 1x, not a guessed delay.
 if elapsed>=r.Duration then
  r.Start=nil;enemy:SetAttribute("BossIntroElapsed",elapsed)
  enemy:SetAttribute("BossIntroState","Completed");return true
 end
 return false
end
function M.Unregister(enemy)
 if records[enemy] then enemy:SetAttribute("BossIntroState","Cancelled");records[enemy]=nil end
end
return M
