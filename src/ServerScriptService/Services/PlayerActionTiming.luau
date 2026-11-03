-- One server-owned success clock and at most one cancellable automatic reservation per player.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.AutoTapConfig)
local M={}
local states={}
local function cancel(s)
 local pending=s.Pending
 if not pending then return end
 s.Pending=nil
 if pending.Thread then task.cancel(pending.Thread);pending.Thread=nil end
 if pending.Finish then pending.Finish() end
end
local function reset(s)
 cancel(s)
 s.NextAuto=os.clock()+Config.AutoInterval
end
local state
state=function(p)
 local s=states[p]
 if not s then
  s={Last=-math.huge,NextAuto=os.clock()+Config.AutoInterval,Connections={}}
  states[p]=s
  for _,name in {"CurrentWorld","AutoTapEnabled"} do
   table.insert(s.Connections,p:GetAttributeChangedSignal(name):Connect(function()state(p)end))
  end
  table.insert(s.Connections,p.CharacterRemoving:Connect(function(ch)s.Removing=ch;state(p)end))
  table.insert(s.Connections,p.CharacterAdded:Connect(function()s.Removing=nil;state(p)end))
 end
 local ch=p.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 local world=p:GetAttribute("CurrentWorld")
 local enabled=p:GetAttribute("AutoTapEnabled")~=false
 local living=ch~=nil and ch~=s.Removing and ch.Parent~=nil and hum~=nil and hum.Health>0
 -- Attribute signals may be deferred: synchronize here too, and reset only once.
 if s.Character~=ch or s.World~=world or s.Enabled~=enabled or s.Living~=living then
  s.Character,s.World,s.Enabled,s.Living=ch,world,enabled,living
  reset(s)
 end
 if hum~=s.Humanoid then
  if s.Death then s.Death:Disconnect() end
  s.Humanoid=hum
  s.Death=hum and hum.Died:Connect(function()state(p)end) or nil
 end
 return s
end
local function alive(p,s)
 return p.Parent==Players and s.Living
end
function M.CanAct(p,manual)
 local s=state(p);local now=os.clock()
 return alive(p,s) and now-s.Last>=Config.MinimumInterval
  and (manual or (p:GetAttribute("AutoTapEnabled")~=false and now>=s.NextAuto))
end
-- Call only after a real, non-yielding gain/hit commits. Failed attempts never call this.
function M.RecordSuccess(p,manual)
 local s=state(p);local now=os.clock()
 cancel(s)
 s.Last=now
 s.NextAuto=now+(manual and Config.AfterManualDelay or Config.AutoInterval)
end
function M.CancelAutomatic(p)
 local s=states[p];if s then cancel(s) end
end
-- Windup leads into the shared due time; it does not add another delay after it.
function M.ScheduleAutomatic(p,lead,perform,finish)
 local s=state(p)
 if not alive(p,s) or p:GetAttribute("AutoTapEnabled")==false or s.Pending then return false end
 local delay=math.max(0,s.NextAuto-os.clock())
 if delay>lead then return false end
 local ticket={Finish=finish};s.Pending=ticket
 ticket.Thread=task.delay(delay,function()
  ticket.Thread=nil
  state(p)
  if s.Pending~=ticket then return end
  s.Pending=nil
  if ticket.Finish then ticket.Finish() end
  if M.CanAct(p,false) then perform() end
 end)
 return true,delay
end
Players.PlayerRemoving:Connect(function(p)
 local s=states[p];if not s then return end
 cancel(s)
 for _,c in s.Connections do c:Disconnect() end
 if s.Death then s.Death:Disconnect() end
 states[p]=nil
end)
return M
