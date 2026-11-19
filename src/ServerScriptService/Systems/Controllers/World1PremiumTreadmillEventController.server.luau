-- Replicate the validated schedule ONCE. No remote requests and no Strength loop.
local Run=game:GetService("RunService")
if not Run:IsServer() then return end
local H=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(game.ServerScriptService.Config.World1PremiumTreadmillEventConfig)
local Event=require(game.ServerScriptService.Services.World1PremiumTreadmillEvent)
local state=RS:FindFirstChild("World1PremiumTreadmillEventState")
if not state then state=Instance.new("StringValue");state.Name="World1PremiumTreadmillEventState";state.Parent=RS end
state.Value=H:JSONEncode(Event.GetDisplayPlan()) -- Single atomic snapshot, display-only.
if not Config.LogTransitions then return end
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
