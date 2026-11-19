-- Server-only temporary access. Never changes ownership, cached passes or saved data.
local Run=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local Config=require(game.ServerScriptService.Config.World1PremiumTreadmillEventConfig)
local Schedule=require(script.Parent.World1PremiumTreadmillEventSchedule)
local M={}
function M.GetStatus()
 -- time() is the current game session's elapsed time. Do not subtract require/join time.
 -- Always evaluate here: cached diagnostics/client attributes never authorize a tick.
 return Schedule.At(Config,Run:IsServer() and Run:IsStudio() and Run:IsRunning(),time())
end
function M.IsOpenForWorld(world)
 return world==1 and M.GetStatus().Open==true
end
function M.IsOpenForTreadmill(treadmill)
 local folder=Workspace:FindFirstChild("Treadmills")
 return folder~=nil and treadmill~=nil and treadmill==folder:FindFirstChild("Diamond01")
  and treadmill.Parent==folder and M.IsOpenForWorld(1)
end
function M.Describe()
 local s=M.GetStatus()
 return ("[StudioPremiumTreadmillEvent] %s; remaining=%.1fs; elapsed=%.1fs; nextStart=%s; reason=%s")
  :format(s.State,s.RemainingSeconds,s.ElapsedSeconds or 0,tostring(s.NextStartAt),s.Reason or "-")
end
return table.freeze(M)
