local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local template=RS.UI.Templates:WaitForChild("EnemyDropGachaTemplate")
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local rarities=Master.Rarities
local queue={}
local seen={}
local running=false
local activeGui,activeTween,tickConnection,pointerTween
local releaseLayout
local HUD=require(RS.Modules:WaitForChild("HUDLayout"))
local function cleanup()
 if releaseLayout then releaseLayout();releaseLayout=nil end
 if tickConnection then tickConnection:Disconnect();tickConnection=nil end
 if activeTween then activeTween:Cancel();activeTween=nil end
 if pointerTween then pointerTween:Cancel();pointerTween=nil end
 if activeGui then activeGui:Destroy();activeGui=nil end
end
local function show(result)
 local gui=template:Clone()
 activeGui=gui
 gui.Name="EnemyDropGacha"
 gui.Enabled=true
 gui:SetAttribute("ResultId",result.Id)
 gui:SetAttribute("Outcome",result.Outcome)
 gui:SetAttribute("Segment",result.Segment)
 gui.Parent=player:WaitForChild("PlayerGui")
 local holder=gui.Root
 holder.Visible=false
 releaseLayout=HUD.Reserve(player.PlayerGui:WaitForChild("StrengthGui"),holder)
 RunService.RenderStepped:Wait();RunService.RenderStepped:Wait()
 if not gui.Parent then return end
 holder.Visible=true
 local wheel=holder.Wheel
 local pointer=holder.Pointer
 local target=-(3*360+(result.Segment-.5)*72)
 wheel.Rotation=0
 local lastTick=0
 tickConnection=RunService.Heartbeat:Connect(function()
  local count=math.floor(math.abs(wheel.Rotation)/72)
  if count>lastTick then
   lastTick=count
   gui.Tick:Play()
   if pointerTween then pointerTween:Cancel() end
   pointer.Rotation=12
   pointerTween=TweenService:Create(pointer,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Rotation=0})
   pointerTween:Play()
  end
 end)
 activeTween=TweenService:Create(wheel,TweenInfo.new(3.0,Enum.EasingStyle.Circular,Enum.EasingDirection.Out),{Rotation=target})
 local started=os.clock()
 activeTween:Play()
 local playback=activeTween.Completed:Wait()
 if tickConnection then tickConnection:Disconnect();tickConnection=nil end
 if playback~=Enum.PlaybackState.Completed or not gui.Parent then return end
 gui:SetAttribute("SpinElapsed",os.clock()-started)
 gui:SetAttribute("Stopped",true)
 if pointerTween then pointerTween:Cancel();pointerTween=nil end
 pointer.Rotation=0
 if result.Outcome=="MISS" then
  holder.Result.Text="MISS";holder.Result.Visible=true
  task.wait(.45)
 else
  local item=Master.Get(result.ItemId)
  if not item then return end
  gui.Reward:Play()
  wheel.Visible=false;pointer.Visible=false
  local card=holder.ItemCard
  card.Icon.Image=item.Image
  card.Stars.Text=string.rep("★",assert(table.find(rarities,item.Rarity)))
  card:SetAttribute("ItemId",item.ItemId)
  card:SetAttribute("Rarity",item.Rarity)
  card.Visible=true
  task.wait(.9)
 end
end
remote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" or result.OwnerUserId~=player.UserId or typeof(result.Id)~="string" or seen[result.Id] then return end
 local segment=result.Segment
 if typeof(segment)~="number" or segment%1~=0 or segment<1 or segment>5 then return end
 if result.Outcome~="MISS" and result.Outcome~="ITEM" then return end
 if (segment%2==0)~=(result.Outcome=="ITEM") then return end
 if result.Outcome=="ITEM" and not Master.Get(result.ItemId) then return end
 seen[result.Id]=true
 task.delay(120,function() seen[result.Id]=nil end)
 table.insert(queue,result)
 if running then return end
 running=true
 task.spawn(function()
  while #queue>0 do
   local nextResult=table.remove(queue,1)
   local ok,err=xpcall(function() show(nextResult) end,debug.traceback)
   cleanup()
   if not ok then warn("[EnemyDropGacha] "..tostring(err)) end
  end
  running=false
 end)
end)
player.CharacterRemoving:Connect(cleanup)

