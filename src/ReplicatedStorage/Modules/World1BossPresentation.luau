-- Client presentation binding. CombatClient owns the accepted snapshot/visibility.
-- Lookup is restricted to this player's direct Owner folder; never search other rigs.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local M={}
local revision
local generations={}
local shown=setmetatable({}, {__mode="k"})
local listeners={}
local heartbeat
local elapsed=0
local function candidate(stage)
 local folder=workspace:FindFirstChild("Enemies")
 local owned=folder and folder:FindFirstChild("Owner_"..player.UserId)
 local enemy=owned and owned:FindFirstChild(("Stage%02d_Enemy"):format(stage))
 if not enemy or enemy:GetAttribute("OwnerUserId")~=player.UserId or enemy:GetAttribute("WorldId")~=1
  or enemy:GetAttribute("RunRevision")~=revision then return nil end
 return enemy
end
function M.AcceptGeneration(stage,generation)
 local enemy=candidate(stage)
 local current=enemy and enemy:GetAttribute("SpawnGeneration")
 local latest=math.max(generations[stage] or 0,typeof(current)=="number" and current or 0)
 if typeof(generation)~="number" then return true end
 if generation<latest then return false end
 generations[stage]=generation
 return true
end
function M.Get(stage)
 if revision==nil or (player:GetAttribute("CurrentWorld") or 1)~=1 then return nil end
 local character=player.Character
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 then return nil end
 local enemy=candidate(stage)
 local generation=enemy and enemy:GetAttribute("SpawnGeneration")
 if not enemy or not shown[enemy] or typeof(generation)~="number"
  or generation<(generations[stage] or 0) then return nil end
 return enemy
end
local function update(force)
 for record in listeners do
  local enemy=M.Get(record.Stage)
  if force or enemy or record.Last then
   record.Last=enemy
   record.Callback()
  end
 end
end
function M.SetRevision(value)
 if value==revision then return end
 revision=value;table.clear(generations);table.clear(shown)
 update(true)
end
function M.SetVisible(enemy,value)
 if shown[enemy]==value then return end
 shown[enemy]=value
 update(true)
end
function M.Watch(stage,callback)
 local record={Stage=stage,Callback=callback};listeners[record]=true
 if not heartbeat then
  -- Retry only the current direct owner actor. Handles partial replication,
  -- delayed Animator/assets/ObjectValue references and later attribute assignment.
  heartbeat=RunService.Heartbeat:Connect(function(dt)
   elapsed+=dt;if elapsed<.25 then return end;elapsed=0;update(false)
  end)
 end
 callback()
 return function()
  listeners[record]=nil
  if not next(listeners) and heartbeat then heartbeat:Disconnect();heartbeat=nil end
 end
end
return M
