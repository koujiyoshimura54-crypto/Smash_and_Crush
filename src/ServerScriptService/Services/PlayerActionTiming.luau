-- One server-owned success clock. Only the Heartbeat action router executes automatic actions.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.AutoTapConfig)
local M={}
local states={}
local function reset(s)
 -- Re-enabling Auto or resetting a run must never shorten a committed deadline.
 s.NextAuto=math.max(s.NextAuto or 0,os.clock()+Config.AutoInterval)
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
 if s.Character~=ch or s.World~=world or s.Living~=living then
  s.Character,s.World,s.Living=ch,world,living
  reset(s)
 end
 -- Auto toggles change permission, never the deadline committed by a success.
 s.Enabled=enabled
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
function M.RecordSuccess(p,manual,combat)
 local s=state(p);local now=os.clock()
 s.Last=now
 s.NextAuto=now+(manual and Config.AfterManualDelay or (combat and Config.CombatAutoInterval or Config.AutoInterval))
end
-- Reset a run/context deadline without resetting the shared minimum-success clock.
function M.ResetAutomatic(p)
 reset(state(p))
end
Players.PlayerRemoving:Connect(function(p)
 local s=states[p];if not s then return end
 for _,c in s.Connections do c:Disconnect() end
 if s.Death then s.Death:Disconnect() end
 states[p]=nil
end)
return M
