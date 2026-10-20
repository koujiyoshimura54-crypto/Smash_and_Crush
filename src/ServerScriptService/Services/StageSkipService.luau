local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(game.ReplicatedStorage.Config.StageSkipConfig)
local Enemy = require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local Data = require(game.ServerScriptService.Services.PlayerDataService)
local Training = require(game.ServerScriptService.Services.TrainingManager)
local Placement = require(game.ServerScriptService.Services.LobbySpawnService)
local M = {}
local busy, prompts, lastRequest = {}, {}, {}
local remote
local initialized=false
local function reply(player, ok, message, extra, requestId)
 if remote and player.Parent == Players then
  remote:FireClient(player, {Success=ok, Message=message, ProductId=extra, RequestId=requestId, Busy=prompts[player]~=nil or (busy[player]==true and not ok)})
 end
end
function M.GetStartCFrame(player, target)
 if not Config.IsSupportedWorld(player) or not Config.Get(target) or not Enemy.IsReady() then return nil end
 local ch = player.Character
 local hum = ch and ch:FindFirstChildOfClass("Humanoid")
 local root = ch and ch:FindFirstChild("HumanoidRootPart")
 if not root or not hum or hum.Health <= 0 then return nil end
 local map = workspace:FindFirstChild("GeneratedMap")
 local corridor = map and map:FindFirstChild("BattleCorridor")
 local stage = corridor and corridor:FindFirstChild(("Stage%02d"):format(target))
 local sub = stage and stage:FindFirstChild(("Stage%d.1"):format(target))
 local geometry = stage and stage:FindFirstChild("WalkableGeometry")
 local floor = geometry and geometry:FindFirstChild("Floor")
 local wall = sub and sub:FindFirstChild("Wall")
 if not floor or not floor:IsA("BasePart") or not floor.CanCollide or not floor.Anchored
  or not wall or not wall:IsA("BasePart") then return nil end
 local box,size=ch:GetBoundingBox()
 local relative=floor.CFrame:ToObjectSpace(box)
 local radiusX=(math.abs(relative.RightVector.X)*size.X+math.abs(relative.UpVector.X)*size.Y+math.abs(relative.LookVector.X)*size.Z)/2
 local radiusZ=(math.abs(relative.RightVector.Z)*size.X+math.abs(relative.UpVector.Z)*size.Y+math.abs(relative.LookVector.Z)*size.Z)/2
 local localWall = floor.CFrame:ToObjectSpace(wall.CFrame)
 local wallHalfZ = (math.abs(localWall.RightVector.Z)*wall.Size.X
  + math.abs(localWall.UpVector.Z)*wall.Size.Y+math.abs(localWall.LookVector.Z)*wall.Size.Z)/2
 local inset = radiusZ+0.25
 -- Stay before Wall1 and outside the existing forward wall-combat trigger.
 local minZ = -floor.Size.Z/2+inset
 local maxZ = localWall.Z-wallHalfZ-math.max(radiusZ,5)-0.25
 local maxX = floor.Size.X/2-radiusX-0.25
 if maxZ<minZ or maxX<0 then return nil end
 local height=Placement.GetRootClearance(player,ch)
 if not height then return nil end
 local position=floor.CFrame:PointToWorldSpace(Vector3.new(
  math.clamp(localWall.X,-maxX,maxX),floor.Size.Y/2,maxZ))
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={geometry}
 params.RespectCanCollide=true;params.CollisionGroup=root.CollisionGroup
 local hit=workspace:Raycast(position+Vector3.new(0,height+16,0),Vector3.new(0,-height-17,0),params)
 if not hit or hit.Normal.Y<0.9 then return nil end
 position=Vector3.new(position.X,hit.Position.Y+height+0.15,position.Z)
 local toward=Vector3.new(wall.Position.X,position.Y,wall.Position.Z)
 return CFrame.lookAt(position,toward),ch,hum
end
function M.TryLock(player)
 if busy[player] then return false end
 busy[player] = true
 return true
end
function M.Unlock(player) busy[player] = nil end
-- Server-only entry used by both Win purchases and validated receipts.
function M.ApplyLocked(player, target, debit)
 local cf,ch,hum=M.GetStartCFrame(player,target)
 if not cf then return false,"Character or Stage not ready" end
 local request=Placement.StreamAt(player,ch,cf.Position)
 if not request or not Placement.IsCurrent(player,request) then return false,"Travel cancelled" end
 local latest,current=M.GetStartCFrame(player,target)
 if not latest or current~=ch then return false,"Character or Stage not ready" end
 local origin=ch.HumanoidRootPart.CFrame
 local rollback
 if debit then
  local accepted,reason,undo=debit()
  if not accepted then return false,reason end
  rollback=undo
 end
 -- No yields after the debit. Failed placement restores the same balance.
 local called,moved,why=pcall(Placement.MoveToCFrame,player,ch,latest)
 if not called or not moved then if rollback then rollback() end;return false,called and why or "Travel failed" end
 local initialized,err=pcall(function()
  Training.StopTraining(player)
  Enemy.StartRun(player,target)
  hum.Health=hum.MaxHealth;hum.Sit=false
 end)
 if not initialized then
  if rollback then rollback() end
  Placement.CancelPending(player)
  if player.Character==ch and hum.Health>0 then Placement.MoveToCFrame(player,ch,origin) end
  warn("[StageSkip] Initialization failed: "..tostring(err))
  return false,"Unable to start Stage"
 end
 return true,"Stage "..target..".1 started"
end
function M.BuyWithWin(player,target)
 if not Config.IsSupportedWorld(player) then return false,"Stage Skip is available in World 1 only" end
 local entry=Config.Get(target)
 if not entry then return false,"Invalid Stage" end
 if not Config.IsInLobby(player.Character) or player:GetAttribute("IsFighting") then return false,"Return to Training Lobby" end
 if prompts[player] then return false,"Finish the purchase prompt first" end
 if not M.TryLock(player) then return false,"Purchase in progress" end
 local function debit()
  if not Config.IsSupportedWorld(player) or not Config.IsInLobby(player.Character) or player:GetAttribute("IsFighting") then return false,"Return to Training Lobby" end
  local session=Data.Get(player)
  if not session or not session.Loaded or session.Saving or session.PendingItemMutation or session.OwnershipLost then return false,"Data not ready" end
  local win=session.Data.Win
  if typeof(win)~="number" or win~=win or win==math.huge or win%1~=0 or win<entry.RequiredWin then return false,"Not enough Win" end
  if not Data.SetWin(player,win-entry.RequiredWin) then return false,"Data not ready" end
  return true,nil,function() Data.SetWin(player,win) end
 end
 local called,success,message=pcall(M.ApplyLocked,player,target,debit)
 M.Unlock(player)
 if not called then warn("Stage Skip failed: "..tostring(success));return false,"Unable to start Stage" end
 return success,message
end
function M.Prompt(player,target)
 if not Config.IsSupportedWorld(player) then return false,"Stage Skip is available in World 1 only" end
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
 if initialized then
  assert(remote==event,"Stage Skip already initialized with another RemoteEvent")
  return
 end
 initialized=true
 remote=event
 remote.OnServerEvent:Connect(function(player,action,target,requestId)
  local now=os.clock()
  if lastRequest[player] and now-lastRequest[player]<0.4 then reply(player,false,"Please wait",nil,requestId) return end
  lastRequest[player]=now
  local called,ok,message,product=pcall(function()
   if action=="Win" then return M.BuyWithWin(player,target)
   elseif action=="Robux" then return M.Prompt(player,target)
   else return false,"Invalid request" end
  end)
  if not called then warn("[StageSkip] "..tostring(ok));ok,message,product=false,"Unable to start Stage",nil end
  reply(player,ok,message,product,requestId)
 end)
end
-- Cancellation releases the lock; purchase confirmation waits for ProcessReceipt.
-- PromptProductPurchaseFinished never starts a Run.
function M.OnPromptClosed(userId,productId,purchased)
 local player=Players:GetPlayerByUserId(userId)
 if player and prompts[player]==productId then
  if not purchased then prompts[player]=nil end
  reply(player,false,purchased and "Purchase pending receipt" or "Purchase cancelled")
 end
end
MarketplaceService.PromptProductPurchaseFinished:Connect(M.OnPromptClosed)
Players.PlayerRemoving:Connect(function(player)
 busy[player]=nil prompts[player]=nil lastRequest[player]=nil
end)
return M
