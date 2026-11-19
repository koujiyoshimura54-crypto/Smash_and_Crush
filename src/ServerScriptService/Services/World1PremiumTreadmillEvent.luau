-- Server-owned plan. The replicated display snapshot is never read for authorization.
local Run=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local Config=require(game.ServerScriptService.Config.World1PremiumTreadmillEventConfig)
local Schedule=require(script.Parent.World1PremiumTreadmillEventSchedule)
local Plan=table.freeze(Schedule.Compile(Config))
local M={}
function M.GetDisplayPlan() return table.clone(Plan) end
function M.GetStatus()
 if not Run:IsServer() or not Run:IsRunning() then return Schedule.At(nil,0) end
 -- Same absolute time domain in every server and in synchronized client rendering.
 return Schedule.At(Plan,Workspace:GetServerTimeNow())
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
 return ("[PremiumTreadmillEvent] %s; remaining=%s; nextStart=%s; reason=%s")
  :format(s.State,tostring(s.RemainingSeconds),tostring(s.NextStartAt),s.Reason or "-")
end
return table.freeze(M)
