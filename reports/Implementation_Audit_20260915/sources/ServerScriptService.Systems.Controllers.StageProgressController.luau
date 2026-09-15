local Players=game:GetService("Players")
local W=game:GetService("Workspace")
local E=require(game.ServerScriptService.World.EnemyManager)
local current
local initializing=false

local function tryInit(m)
 if initializing or current==m or m~=W:FindFirstChild("GeneratedMap") then return false end
 local bc=m:FindFirstChild("BattleCorridor")
 local stage10=bc and bc:FindFirstChild("Stage10")
 if not stage10 then return false end
 initializing=true
 local ok,err=pcall(function() E.Initialize(m) end)
 initializing=false
 if ok then
  current=m
  return true
 end
 warn("StageProgressController initialization failed: "..tostring(err))
 return false
end

Players.PlayerAdded:Connect(function(p)
 task.defer(function()
  if current then E.InitializePlayer(p) end
 end)
end)

task.spawn(function()
 while not current do
  local m=W:FindFirstChild("GeneratedMap")
  if m then tryInit(m) end
  task.wait(0.25)
 end
end)

W.ChildAdded:Connect(function(c)
 if c.Name=="GeneratedMap" then
  task.spawn(function()
   while c.Parent and not current do
    if tryInit(c) then break end
    task.wait(0.25)
   end
  end)
 end
end)

