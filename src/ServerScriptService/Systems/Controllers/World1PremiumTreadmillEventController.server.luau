-- Output diagnostics only. TrainingManager is the sole existing Strength loop.
local Run=game:GetService("RunService")
if not Run:IsStudio() or not Run:IsServer() then return end
local Config=require(game.ServerScriptService.Config.World1PremiumTreadmillEventConfig)
if not Config.LogTransitions then return end
local Event=require(game.ServerScriptService.Services.World1PremiumTreadmillEvent)
local last,elapsed=nil,0
local function report()
 local s=Event.GetStatus()
 local key=s.State..":"..tostring(s.Cycle)
 if key~=last then last=key;print(Event.Describe()) end
end
report()
local connection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed>=1 then elapsed%=1;report() end
end)
script.Destroying:Once(function()connection:Disconnect()end)
