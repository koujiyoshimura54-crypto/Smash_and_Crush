-- One character-independent renderer; survives respawn and tolerates partial streaming.
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local H=game:GetService("HttpService")
local Schedule=require(RS.Modules.World1PremiumTreadmillEventSchedule)
local View=require(RS.Modules.World1PremiumTreadmillEventPresentation)
local Style=require(RS.Config.World1PremiumTreadmillEventStyle)
local stopActive
local M={}
function M.Start(owner)
 if stopActive then stopActive() end
local board,overhead,plan,raw=nil,nil,nil,nil
local elapsed=Style.RefreshSeconds
local hidden=Schedule.Presentation(Schedule.At(nil,0))
local function update()
 local state=RS:FindFirstChild("World1PremiumTreadmillEventState")
 local value=state and state:IsA("StringValue") and state.Value or ""
 if value~=raw then
  raw=value
  local ok,decoded=pcall(H.JSONDecode,H,value)
  plan=ok and Schedule.Validate(decoded) and decoded or nil
 end
 -- Fixed direct paths only, no Workspace GetDescendants or per-Player listeners.
 local model=Workspace:FindFirstChild("EventBoard")
 local panel=model and model:FindFirstChild("Board")
 local gui=panel and panel:FindFirstChild("SurfaceGui")
 if not board or board.Model~=model or board.Gui~=gui
  or board.Frame~=model:FindFirstChild("Part")
  or board.TimeStroke~=board.Time:FindFirstChildOfClass("UIStroke")
  or board.Time.Parent~=gui or board.Title.Parent~=gui or board.Free.Parent~=gui then
  if board and board.Model.Parent then View.DrawBoard(board,hidden) end
  board=View.BindBoard(model,false)
 end
 local folder=Workspace:FindFirstChild("Treadmills")
 local machine=folder and folder:FindFirstChild("Diamond01")
 local area=machine and machine:FindFirstChild("Area")
 if not overhead or overhead.Model~=machine or overhead.Area~=area
  or overhead.Gui.Parent~=area or overhead.Time.Parent~=overhead.Gui then
  if overhead and overhead.Gui.Parent then View.DrawOverhead(overhead,hidden) end
  overhead=View.BindOverhead(machine,false)
 end
 local p=Schedule.Presentation(Schedule.At(plan,Workspace:GetServerTimeNow()))
 View.DrawBoard(board,p);View.DrawOverhead(overhead,p)
end
update()
 local connection,destruction
 local stopped=false
 local function stop()
  if stopped then return end
  stopped=true
  if connection then connection:Disconnect() end
  if destruction then destruction:Disconnect() end
  if board and board.Gui.Parent then View.DrawBoard(board,hidden) end
  if overhead and overhead.Gui.Parent then View.DrawOverhead(overhead,hidden) end
  if stopActive==stop then stopActive=nil end
 end
 stopActive=stop
 connection=Run.Heartbeat:Connect(function(dt)
  elapsed+=dt
  if elapsed>=Style.RefreshSeconds then elapsed%=Style.RefreshSeconds;update() end
 end)
 destruction=owner.Destroying:Connect(stop)
 return stop
end
return M
