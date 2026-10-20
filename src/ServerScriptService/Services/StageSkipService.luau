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
local BODY_NAMES = {"HumanoidRootPart","Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm",
 "LeftLowerArm","RightLowerArm","LeftHand","RightHand","LeftUpperLeg","RightUpperLeg",
 "LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
local function halfSize(cf,size)
 return Vector3.new(math.abs(cf.RightVector.X)*size.X+math.abs(cf.UpVector.X)*size.Y+math.abs(cf.LookVector.X)*size.Z,
  math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z,
  math.abs(cf.RightVector.Z)*size.X+math.abs(cf.UpVector.Z)*size.Y+math.abs(cf.LookVector.Z)*size.Z)/2
end
-- Measure the applied rig in the DESTINATION orientation, excluding ornaments/tools.
local function bodyAt(character,root,hum,rotation)
 local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 local parts={}
 local height=hum.HipHeight+root.Size.Y/2
 if hum.RigType==Enum.HumanoidRigType.R6 then
  local leg=character:FindFirstChild("Left Leg");height+=leg and leg.Size.Y or 2
 end
 for _,name in BODY_NAMES do
  local part=character:FindFirstChild(name)
  if part and part:IsA("BasePart") then
   local relative=root.CFrame:ToObjectSpace(part.CFrame)
   local cf=rotation*relative
   local half=halfSize(cf,part.Size)
   low=low:Min(cf.Position-half);high=high:Max(cf.Position+half)
   table.insert(parts,{Part=part,Relative=relative,Size=part.Size,Collide=part.CanCollide,Group=part.CollisionGroup})
   if name:find("Foot") or name:find("Leg") then height=math.max(height,-relative.Y+halfSize(relative,part.Size).Y) end
  end
 end
 local hip,scale=hum.HipHeight,character:GetAttribute("MuscleHeightScale")
 local function unchanged()
  if hum.Health<=0 or hum.HipHeight~=hip or character:GetAttribute("MuscleHeightScale")~=scale then return false end
  for _,entry in parts do
   if entry.Part.Parent~=character or entry.Part.Size~=entry.Size or entry.Part.CanCollide~=entry.Collide
    or entry.Part.CollisionGroup~=entry.Group then return false end
  end
  return true
 end
 return low,high,height,parts,unchanged
end
function M.GetStartCFrame(player, target)
 if not Config.IsSupportedWorld(player) or not Config.Get(target) or not Enemy.IsReady() then return nil,"StageNotReady" end
 local ch = player.Character
 local hum = ch and ch:FindFirstChildOfClass("Humanoid")
 local root = ch and ch:FindFirstChild("HumanoidRootPart")
 if not root or not hum or hum.Health <= 0 or not ch:IsDescendantOf(workspace)
  or not ch:GetAttribute("SpawnEngineReady") or not ch:GetAttribute("MuscleScaleReady") then return nil,"CharacterNotReady" end
 local map = workspace:FindFirstChild("GeneratedMap")
 local corridor = map and map:FindFirstChild("BattleCorridor")
 local stage = corridor and corridor:FindFirstChild(("Stage%02d"):format(target))
 local sub = stage and stage:FindFirstChild(("Stage%d.1"):format(target))
 local geometry = stage and stage:FindFirstChild("WalkableGeometry")
 local floor = geometry and geometry:FindFirstChild("Floor")
 local wall = sub and sub:FindFirstChild("Wall")
 if not floor or not floor:IsA("BasePart") or not floor.CanCollide or not floor.Anchored
  or not wall or not wall:IsA("BasePart") then return nil,"StageGeometryUnavailable" end
 local forward=floor.CFrame:VectorToWorldSpace(Vector3.zAxis)
 local rotation=CFrame.lookAt(Vector3.zero,Vector3.new(forward.X,0,forward.Z))
 local low,high,height,parts,unchanged=bodyAt(ch,root,hum,floor.CFrame.Rotation:Inverse()*rotation)
 local localWall = floor.CFrame:ToObjectSpace(wall.CFrame)
 local wallHalfZ = (math.abs(localWall.RightVector.Z)*wall.Size.X
  + math.abs(localWall.UpVector.Z)*wall.Size.Y+math.abs(localWall.LookVector.Z)*wall.Size.Z)/2
 -- Stay before Wall1 and outside the existing forward wall-combat trigger.
 local minZ=-floor.Size.Z/2-low.Z+0.25
 local maxZ=localWall.Z-wallHalfZ-math.max(high.Z,5)-0.25
 local minX=-floor.Size.X/2-low.X+0.25
 local maxX=floor.Size.X/2-high.X-0.25
 if maxZ<minZ or maxX<minX then return nil,"BodyDoesNotFitEntry" end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={geometry}
 params.RespectCanCollide=true;params.CollisionGroup=root.CollisionGroup
 local overlap=OverlapParams.new()
 overlap.FilterType=Enum.RaycastFilterType.Exclude;overlap.FilterDescendantsInstances={ch}
 overlap.RespectCanCollide=true;overlap.MaxParts=1
 local reason="StageFloorUnavailable"
 -- Bounded request-time search, nearest Wall1 first, always within this entry.
 local xs={math.clamp(localWall.X,minX,maxX),(minX+maxX)/2,minX,maxX}
 local zs={maxZ,(minZ+maxZ)/2,minZ}
 for _,z in zs do for _,x in xs do
  local surface=floor.CFrame:PointToWorldSpace(Vector3.new(x,floor.Size.Y/2,z))
  local supported=true
  -- Center plus the body's footprint corners must have the same walkable support.
  for _,offset in {Vector3.zero,Vector3.new(low.X,0,low.Z),Vector3.new(low.X,0,high.Z),
   Vector3.new(high.X,0,low.Z),Vector3.new(high.X,0,high.Z)} do
   local point=surface+floor.CFrame:VectorToWorldSpace(offset)
   local hit=workspace:Raycast(point+Vector3.new(0,height+16,0),Vector3.new(0,-height-16.5,0),params)
   if not hit or hit.Normal.Y<0.9 or math.abs(hit.Position.Y-surface.Y)>0.1 then supported=false;break end
  end
  if supported then
   local cf=CFrame.new(surface+Vector3.new(0,height+0.15,0))*rotation
   local clear=true
   for _,entry in parts do if entry.Collide then
    overlap.CollisionGroup=entry.Group
    if #workspace:GetPartBoundsInBox(cf*entry.Relative,entry.Size-Vector3.one*0.05,overlap)>0 then clear=false;reason="StageEntryObstructed";break end
   end end
   if clear then
    local floorCF,floorSize,wallCF,wallSize=floor.CFrame,floor.Size,wall.CFrame,wall.Size
    return cf,ch,hum,function()
     return unchanged() and floor.Parent==geometry and floor.Anchored and floor.CanCollide
      and floor.CFrame==floorCF and floor.Size==floorSize and wall.Parent==sub
      and wall.CFrame==wallCF and wall.Size==wallSize
    end
   end
  end
 end end
 return nil,reason
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
 if not cf then return false,"Character or Stage not ready ("..tostring(ch)..")" end
 local request=Placement.StreamAt(player,ch,cf.Position)
 if not request or not Placement.IsCurrent(player,request) then return false,"Travel cancelled" end
 local latest,current,_,unchanged=M.GetStartCFrame(player,target)
 if not latest or current~=ch then return false,"Character or Stage not ready ("..tostring(current)..")" end
 local origin=ch.HumanoidRootPart.CFrame
 local _,_,originHeight=bodyAt(ch,ch.HumanoidRootPart,hum,CFrame.identity)
 if debit then
  local accepted,reason=debit(false)
  if not accepted then return false,reason end
 end
 local called,moved,why,placement=pcall(Placement.MoveToCFrame,player,ch,latest)
 local function restore()
  -- A superseding World/death/travel owns the new position; never replay this origin.
  if placement and Placement.IsCurrent(player,placement) and player.Character==ch and hum.Health>0 then
   Placement.CancelPending(player)
   local _,_,height=bodyAt(ch,ch.HumanoidRootPart,hum,CFrame.identity)
   -- A size change during acknowledgement must not restore the old, shorter feet height.
   local safeOrigin=origin+Vector3.new(0,math.max(0,height-originHeight),0)
   local restored,_,back=Placement.MoveToCFrame(player,ch,safeOrigin)
   if restored then
    Placement.AwaitPlacement(player,back)
    if Placement.IsCurrent(player,back) then Placement.CancelPending(player) end
   end
  end
 end
 if not called or not moved then restore();return false,called and why or "Travel failed" end
 local ready,reason=Placement.AwaitPlacement(player,placement,unchanged)
 if not ready then restore();return false,reason end
 -- Charge only after matching client pose/floor acknowledgement; no yield after debit.
 local rollback
 if debit then
  local accepted,reason,undo=debit(true)
  if not accepted then restore();return false,reason end
  rollback=undo
 end
 local initialized,err=pcall(function()
  Training.StopTraining(player)
  Enemy.StartRun(player,target)
  hum.Health=hum.MaxHealth;hum.Sit=false
 end)
 if not initialized then
  if rollback then rollback() end
  restore()
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
 local function debit(commit)
  if not Config.IsSupportedWorld(player) or (not commit and not Config.IsInLobby(player.Character)) or player:GetAttribute("IsFighting") then return false,"Return to Training Lobby" end
  local session=Data.Get(player)
  if not session or not session.Loaded or session.Saving or session.PendingItemMutation or session.OwnershipLost then return false,"Data not ready" end
  local win=session.Data.Win
  if typeof(win)~="number" or win~=win or win==math.huge or win%1~=0 or win<entry.RequiredWin then return false,"Not enough Win" end
  if not commit then return true end
  if not Data.SetWin(player,win-entry.RequiredWin) then return false,"Data not ready" end
  local refunded=false
  return true,nil,function()
   if not refunded then refunded=true;Data.SetWin(player,session.Data.Win+entry.RequiredWin) end
  end
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
