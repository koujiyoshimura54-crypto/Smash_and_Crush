local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local ItemPresentation=require(RS.Modules:WaitForChild("InventoryPresentation"))
local template=RS.UI.Templates:WaitForChild("EnemyDropGachaTemplate")
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local rarities=Master.Rarities
local queue={}
local seen={}
local running=false
local activeGui,activeTween,tickConnection,pointerTween
local releaseLayout
local ContentProvider=game:GetService("ContentProvider")
task.spawn(function()
 local images={} for _,ore in ipairs(require(RS.Config.OreConfig).GetAvailable()) do table.insert(images,ore.Image) end
 pcall(function() ContentProvider:PreloadAsync(images) end)
end)
local HUD=require(RS.Modules:WaitForChild("HUDLayout"))
local function disableTokenLocalization(root)
 if root:IsA("GuiBase2d") then root.AutoLocalize=false end
 for _,instance in ipairs(root:GetDescendants()) do
  if instance:IsA("GuiBase2d") then instance.AutoLocalize=false end
 end
end
local function cleanup()
 if releaseLayout then releaseLayout();releaseLayout=nil end
 if tickConnection then tickConnection:Disconnect();tickConnection=nil end
 if activeTween then activeTween:Cancel();activeTween=nil end
 if pointerTween then pointerTween:Cancel();pointerTween=nil end
 if activeGui then activeGui:Destroy();activeGui=nil end
end
local function currentRun(result)
 return result.WorldId~=1 or (result.RunId==player:GetAttribute("RunInventoryId")
  and player:GetAttribute("RunInventoryActive")==true)
end
local function show(result)
 if not currentRun(result) then return end
 local gui=template:Clone()
 disableTokenLocalization(gui)
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
 if playback~=Enum.PlaybackState.Completed or not gui.Parent or not currentRun(result) then return end
 gui:SetAttribute("SpinElapsed",os.clock()-started)
 gui:SetAttribute("Stopped",true)
 if pointerTween then pointerTween:Cancel();pointerTween=nil end
 pointer.Rotation=0
 if result.Outcome=="MISS" then
  holder.Result.Text=result.Reason=="InventoryFull" and "RUN INVENTORY FULL" or "MISS";holder.Result.Visible=true
  task.wait(.45)
 else
  local item=Master.Get(result.ItemId)
  if not item then return end
  gui.Reward:Play()
  wheel.Visible=false;pointer.Visible=false
  local card=holder.ItemCard
  card.Icon.Image=item.Image
  ItemPresentation.SetItemStars(card.Icon,item,card.Stars)
  card:SetAttribute("ItemId",item.ItemId)
  card:SetAttribute("Rarity",item.Rarity)
  card.Visible=true
  task.wait(.9)
 end
end
-- Local-only, nonblocking acquisition cue. No replicated BillboardGui or level label.
local overhead={}
local function clearOverhead()
 for gui,connection in pairs(overhead) do connection:Disconnect();gui:Destroy() end
 table.clear(overhead)
end
local function showOverhead(result)
 local character=player.Character
 local item=result.Outcome=="ORE" and require(RS.Config.OreConfig).Get(result.OreId) or Master.Get(result.ItemId)
 if not item then return end
 -- Loading runs in its own task; movement, combat and the next input continue.
 pcall(function() ContentProvider:PreloadAsync({item.Image}) end)
 if player.Character~=character then return end
 local head=character and character:FindFirstChild("Head")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not head or not humanoid or humanoid.Health<=0 then return end
 local gui=Instance.new("BillboardGui");gui.Name="PersonalDropReward";gui.Size=UDim2.fromOffset(110,110)
 gui.Adornee=head;gui.AlwaysOnTop=true;gui.Active=false;gui:SetAttribute("RewardId",result.Id)
 local icon=Instance.new("ImageLabel");icon.Name="Icon";icon.BackgroundTransparency=1;icon.Size=UDim2.fromScale(.88,.88)
 icon.Image=item.Image;icon.ScaleType=Enum.ScaleType.Fit;icon.Parent=gui
 local quantity=Instance.new("TextLabel");quantity.Name="Quantity";quantity.BackgroundTransparency=1
 quantity.Text="×1";quantity.FontFace=Font.fromEnum(Enum.Font.GothamBlack);quantity.TextColor3=Color3.new(1,1,1)
 quantity.TextStrokeTransparency=0;quantity.TextSize=28;quantity.Size=UDim2.fromScale(.5,.3);quantity.Position=UDim2.fromScale(.5,.68);quantity.Parent=gui
 gui.Parent=player.PlayerGui
 local function remove()
  local c=overhead[gui];if c then c:Disconnect();overhead[gui]=nil end
  gui:Destroy()
 end
 overhead[gui]=RunService.Heartbeat:Connect(function()
  if player.Character~=character or not head.Parent or humanoid.Health<=0 then remove();return end
  gui.StudsOffsetWorldSpace=Vector3.new(0,head.Size.Y/2+2,0)
 end)
 task.delay(2,remove)
end
player.CharacterRemoving:Connect(clearOverhead)
remote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" or result.OwnerUserId~=player.UserId or typeof(result.Id)~="string" or seen[result.Id] then return end
 if result.WorldId==1 then
  if result.Outcome~="ITEM" and result.Outcome~="ORE" then return end
  seen[result.Id]=true;task.delay(120,function() seen[result.Id]=nil end)
  task.spawn(showOverhead,result);return
 end
 if not currentRun(result) then return end
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
