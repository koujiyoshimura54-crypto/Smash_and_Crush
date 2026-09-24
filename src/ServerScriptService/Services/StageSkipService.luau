local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(game.ReplicatedStorage.Config.StageSkipConfig)
local Enemy = require(game.ServerScriptService.World.EnemyManager)
local Training = require(game.ServerScriptService.Services.TrainingManager)
local M = {}
local busy, prompts, lastRequest = {}, {}, {}
local remote
local function reply(player, ok, message, extra)
 if remote and player.Parent == Players then
  remote:FireClient(player, {Success=ok, Message=message, ProductId=extra})
 end
end
function M.GetStartCFrame(player, target)
 if not Config.Get(target) or not Enemy.IsReady() then return nil end
 local ch = player.Character
 local hum = ch and ch:FindFirstChildOfClass("Humanoid")
 local root = ch and ch:FindFirstChild("HumanoidRootPart")
 if not root or not hum or hum.Health <= 0 then return nil end
 local map = workspace:FindFirstChild("GeneratedMap")
 local corridor = map and map:FindFirstChild("BattleCorridor")
 local stage = corridor and corridor:FindFirstChild(("Stage%02d"):format(target))
 local sub = stage and stage:FindFirstChild(("Stage%d.1"):format(target))
 local floor = sub and sub:FindFirstChild("Floor")
 local wall = sub and sub:FindFirstChild("Wall")
 local zone = sub and sub:FindFirstChild("CombatZone")
 if not floor or not wall or not zone then return nil end
 local front = zone.Position-wall.Position
 front = Vector3.new(front.X,0,front.Z)
 if front.Magnitude < 0.01 then return nil end
 front = front.Unit
 local _, size = ch:GetBoundingBox()
 local radius = math.max(size.X,size.Z)/2
 local half = math.abs(front:Dot(zone.CFrame.RightVector))*zone.Size.X/2
  + math.abs(front:Dot(zone.CFrame.UpVector))*zone.Size.Y/2
  + math.abs(front:Dot(zone.CFrame.LookVector))*zone.Size.Z/2
 local position = zone.Position+front*(half+radius+3)
 -- Keep the arrival inside the requested stage, ahead of its first wall.
 local stageFloor = stage:FindFirstChild("Floor")
 if not stageFloor then return nil end
 local localPosition = stageFloor.CFrame:PointToObjectSpace(position)
 local localWall = stageFloor.CFrame:ToObjectSpace(wall.CFrame)
 local wallHalfZ = (math.abs(localWall.RightVector.Z)*wall.Size.X
  + math.abs(localWall.UpVector.Z)*wall.Size.Y
  + math.abs(localWall.LookVector.Z)*wall.Size.Z)/2
 local inset = math.max(root.Size.X,root.Size.Z)/2+0.25
 local minZ = -stageFloor.Size.Z/2+inset
 local maxZ = localWall.Z-wallHalfZ-inset
 local maxX = stageFloor.Size.X/2-inset
 if maxZ < minZ or maxX < 0 then return nil end
 position = stageFloor.CFrame:PointToWorldSpace(Vector3.new(
  math.clamp(localPosition.X,-maxX,maxX),
  localPosition.Y,
  math.clamp(localPosition.Z,minZ,maxZ)
 ))
 local floorTop = floor.Position.Y+floor.Size.Y/2
 position = Vector3.new(position.X,floorTop+math.max(size.Y/2,hum.HipHeight+root.Size.Y/2)+1,position.Z)
 return CFrame.lookAt(position,position-front), ch, hum
end
function M.TryLock(player)
 if busy[player] then return false end
 busy[player] = true
 return true
end
function M.Unlock(player) busy[player] = nil end
-- Server-only entry used by both Win purchases and validated receipts.
function M.ApplyLocked(player, target)
 local cf, ch, hum = M.GetStartCFrame(player,target)
 if not cf then return false,"Character or Stage not ready" end
 Training.StopTraining(player)
 Enemy.StartRun(player,target)
 hum.Health = hum.MaxHealth
 hum.Sit = false
 ch:PivotTo(cf)
 for _, part in ch:GetDescendants() do
  if part:IsA("BasePart") then
   part.AssemblyLinearVelocity = Vector3.zero
   part.AssemblyAngularVelocity = Vector3.zero
  end
 end
 return true,"Stage "..target..".1 started"
end
function M.BuyWithWin(player,target)
 local entry = Config.Get(target)
 if not entry then return false,"Invalid Stage" end
 if not Config.IsInLobby(player.Character) or player:GetAttribute("IsFighting") then return false,"Return to Training Lobby" end
 if prompts[player] then return false,"Finish the purchase prompt first" end
 if not M.TryLock(player) then return false,"Purchase in progress" end
 local ok, success, message = pcall(function()
  local win = player:GetAttribute("Win")
  if typeof(win) ~= "number" or win ~= win or win == math.huge or win < entry.RequiredWin then
   return false,"Not enough Win"
  end
  if not M.GetStartCFrame(player,target) then return false,"Character or Stage not ready" end
  local applied, result = M.ApplyLocked(player,target)
  if not applied then return false,result end
  -- ApplyLocked does not yield. Only a successful start consumes Win.
  player:SetAttribute("Win",win-entry.RequiredWin)
  return true,result
 end)
 M.Unlock(player)
 if not ok then warn("Stage Skip failed: "..tostring(success)) return false,"Unable to start Stage" end
 return success,message
end
function M.Prompt(player,target)
 local entry = Config.Get(target)
 if not entry then return false,"Invalid Stage" end
 if not Config.IsInLobby(player.Character) or player:GetAttribute("IsFighting") then return false,"Return to Training Lobby" end
 if busy[player] or prompts[player] then return false,"Purchase in progress" end
 if not M.GetStartCFrame(player,target) then return false,"Character or Stage not ready" end
 prompts[player] = entry.ProductId
 local ok, err = pcall(MarketplaceService.PromptProductPurchase,MarketplaceService,player,entry.ProductId)
 if not ok then prompts[player]=nil return false,"Purchase prompt unavailable" end
 return true,"Complete the Roblox purchase prompt",entry.ProductId
end
function M.NotifyReceipt(player,target)
 prompts[player]=nil
 reply(player,true,"Stage "..target..".1 started")
end
function M.Initialize(event)
 remote=event
 remote.OnServerEvent:Connect(function(player,action,target)
  local now=os.clock()
  if lastRequest[player] and now-lastRequest[player]<0.4 then reply(player,false,"Please wait") return end
  lastRequest[player]=now
  local ok,message,product
  if action=="Win" then ok,message=M.BuyWithWin(player,target)
  elseif action=="Robux" then ok,message,product=M.Prompt(player,target)
  else ok,message=false,"Invalid request" end
  reply(player,ok,message,product)
 end)
end
-- Closing the prompt only releases the UI lock; it never starts a Run.
function M.OnPromptClosed(userId,productId,purchased)
 local player=Players:GetPlayerByUserId(userId)
 if player and prompts[player]==productId then
  prompts[player]=nil
  reply(player,false,purchased and "Purchase pending receipt" or "Purchase cancelled")
 end
end
MarketplaceService.PromptProductPurchaseFinished:Connect(M.OnPromptClosed)
Players.PlayerRemoving:Connect(function(player)
 busy[player]=nil prompts[player]=nil lastRequest[player]=nil
end)
return M
