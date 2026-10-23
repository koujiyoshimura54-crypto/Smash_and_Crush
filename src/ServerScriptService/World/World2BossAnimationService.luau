-- Server owns only intro lifecycle/chase gating. Damage/attacks remain unchanged.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.World2BossAnimationConfig)
local Rig=require(game.ReplicatedStorage.Modules.World2BossRig)
local BodyConfig=require(game.ReplicatedStorage.Config.World2SCP096Config)
local BodyState=require(game.ReplicatedStorage.Modules.World2SCP096State)
local M={}
local records={}
local function publish096(enemy,r)
 local timeline=r.Timeline
 if r.PublishedAttackEligible~=timeline.AttackEligible then
  r.PublishedAttackEligible=timeline.AttackEligible
  enemy:SetAttribute("SCP096AttackEligible",timeline.AttackEligible)
 end
 if r.PublishedRevision==timeline.Revision then return end
 r.PublishedRevision=timeline.Revision
 enemy:SetAttribute("SCP096PhaseStartedAt",timeline.StartedAt)
 enemy:SetAttribute("SCP096PhaseRevision",timeline.Revision)
 enemy:SetAttribute("SCP096Phase",timeline.Phase)
 local intro=timeline.Phase=="GetUp_Panic" or timeline.Phase=="Panic"
 enemy:SetAttribute("BossIntroState",intro and "Playing" or timeline.Phase=="Waiting" and "Ready"
  or timeline.Phase=="Cancelled" and "Cancelled" or "Completed")
end
local function update096(enemy,r,now)
 local owner=Players:GetPlayerByUserId(enemy:GetAttribute("OwnerUserId"))
 local hum=owner and owner.Character and owner.Character:FindFirstChildOfClass("Humanoid")
 if not enemy.Parent or not owner or owner.Character~=r.Character or not hum or hum.Health<=0
  or owner:GetAttribute("CurrentWorld")~=2 then BodyState.Cancel(r.Timeline)
 else BodyState.Update(r.Timeline,now) end
 publish096(enemy,r)
end
function M.Register(enemy,stage)
 if not Config.Stages[stage] then return end
 records[enemy]={Stage=stage,Used=false}
 enemy:SetAttribute("BossIntroState","Ready")
 if stage==1 and Config.Stages[stage].Rig=="SCP096Skin" then
  local r=records[enemy]
  local owner=Players:GetPlayerByUserId(enemy:GetAttribute("OwnerUserId"))
  r.Character=owner and owner.Character
  local ok,result=pcall(function()
   local visual=assert(enemy:FindFirstChild("SCP-096"))
   local folder=assert(visual:FindFirstChild(BodyConfig.Folder))
   local durations={}
   for name,entry in BodyConfig.Clips do
    local sequence=assert(folder:FindFirstChild(entry.Name));assert(sequence:IsA("KeyframeSequence"))
    durations[name]=Rig.Duration(sequence)
   end
   local timeline=BodyState.Create(durations)
   assert(timeline.Intervals.GetUp_Panic+timeline.Intervals.Panic<=Config.MaxIntroDuration,"096 intro exceeds bound")
   return timeline
  end)
  if ok then r.Timeline=result;publish096(enemy,r)
  else r.Failed=true;enemy:SetAttribute("SCP096Phase","Failed")
   enemy:SetAttribute("BossIntroState","Failed");warn("[World2BossAnimation] Invalid096 body clips: "..tostring(result)) end
 end
end
function M.BeginIntro(enemy)
 local r=records[enemy]
 if r and r.Timeline then
  if BodyState.Begin(r.Timeline,workspace:GetServerTimeNow()) then
   enemy:SetAttribute("BossIntroDuration",r.Timeline.Intervals.GetUp_Panic+r.Timeline.Intervals.Panic)
   enemy:SetAttribute("BossIntroStartedAt",r.Timeline.StartedAt)
   publish096(enemy,r)
  end
  return
 end
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
 if r and r.Timeline then
  local now=workspace:GetServerTimeNow();update096(enemy,r,now)
  return BodyState.Ready(r.Timeline,now)
 end
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
function M.SetAttackEligible(enemy,eligible,now)
 local r=records[enemy]
 if not r or not r.Timeline then return end
 now=now or workspace:GetServerTimeNow()
 update096(enemy,r,now)
 BodyState.SetAttack(r.Timeline,eligible,now);publish096(enemy,r)
end
function M.Unregister(enemy)
 local r=records[enemy]
 if r and r.Timeline then BodyState.Cancel(r.Timeline);publish096(enemy,r) end
 if records[enemy] then enemy:SetAttribute("BossIntroState","Cancelled");records[enemy]=nil end
end
return M
