-- One provisional acquisition cue. Closing a cue never removes loot.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local ContentProvider=game:GetService("ContentProvider")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local Ore=require(RS.Config.OreConfig)
local Format=require(RS.Modules.NumberFormat)
local HUD=require(RS.Modules.HUDLayout)
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local dropRemote=RS.Remotes:WaitForChild("RunDrop")
local strength=player.PlayerGui:WaitForChild("StrengthGui")
local hud=strength:WaitForChild("HUD")
local back=hud:WaitForChild("RunReturnButton")
local button=back:Clone();button.Name="RunDropButton";button.Text="Drop"
button.AutomaticSize=Enum.AutomaticSize.None;button.BackgroundColor3=Color3.fromRGB(200,92,30)
button.Visible=false;button.Parent=hud
local serial=0
local active,activeGui,awaiting,busy,pendingRun
local seen={}
local function valid(result)
 local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 return result.RunId==player:GetAttribute("RunInventoryId") and player:GetAttribute("RunInventoryActive")==true
  and result.WorldId==(player:GetAttribute("CurrentWorld") or 1) and hum and hum.Health>0
  and player:GetAttribute("RunReturnBusy")~=true
end
local function close()
 serial+=1
 local old=active;active=nil;busy=nil;button.Visible=false
 if activeGui then activeGui:Destroy();activeGui=nil end
 if old then task.spawn(function()pcall(function()dropRemote:InvokeServer("Close",old.RunId,old.Id)end)end) end
end
local function positionButton()
 local scale=HUD.GetScale(hud)
 local pos=(back.AbsolutePosition-hud.AbsolutePosition)/scale
 local size=back.AbsoluteSize/scale
 local gap=10/scale
 local w=math.max(size.X,68/scale);local h=math.max(size.Y,44/scale)
 button.AnchorPoint=Vector2.zero
 button.Position=UDim2.fromOffset(pos.X+size.X+gap,pos.Y)
 button.Size=UDim2.fromOffset(w,h)
 button.TextSize=back.TextSize;button.ZIndex=back.ZIndex
end
local function discardDisplayed()
 if busy or not active or not button.Visible then return end
 local result=active;local generation=serial;busy=true;button.Interactable=false
 local ok,dropped=pcall(function()return dropRemote:InvokeServer("Drop",result.RunId,result.Id)end)
 if generation~=serial then return end
 busy=nil
 if ok and dropped then close() else button.Interactable=true end
end
button.Activated:Connect(discardDisplayed)
local function show(result,generation)
 local character=player.Character
 local item=result.Outcome=="ORE" and Ore.Get(result.OreId) or Master.Get(result.ItemId)
 if not item then return end
 pcall(function()ContentProvider:PreloadAsync({item.Image})end)
 local deadline=os.clock()+2
 while generation==serial and not valid(result) and player.Character==character and os.clock()<deadline do task.wait() end
 if generation~=serial or not valid(result) or player.Character~=character then return end
 local head=character:FindFirstChild("Head");if not head then return end
 local gui=Instance.new("BillboardGui");gui.Name="PersonalDropReward";gui.Size=UDim2.fromOffset(110,110)
 gui.Adornee=head;gui.AlwaysOnTop=true;gui.Active=false;gui.AutoLocalize=false
 gui.StudsOffsetWorldSpace=Vector3.new(0,head.Size.Y/2+2,0)
 local icon=Instance.new("ImageLabel");icon.Name="Icon";icon.BackgroundTransparency=1
 icon.Size=UDim2.fromScale(.88,.88);icon.Image=item.Image;icon.ScaleType=Enum.ScaleType.Fit;icon.Parent=gui
 if result.Outcome=="ORE" then
  gui.Size=UDim2.fromOffset(180,110);icon.Size=UDim2.fromOffset(97,97)
  local points=Instance.new("TextLabel");points.Name="Points";points.BackgroundTransparency=1
  points.AutoLocalize=false;points.Text=Format.Format(item.Points).." pt"
  points.FontFace=Font.fromEnum(Enum.Font.GothamBlack);points.TextColor3=Color3.new(1,1,1)
  points.TextStrokeTransparency=0;points.TextSize=28;points.TextScaled=true
  points.Size=UDim2.fromOffset(83,38);points.Position=UDim2.fromOffset(97,34);points.Parent=gui
 end
 active=result;activeGui=gui;gui.Parent=player.PlayerGui
 RunService.RenderStepped:Wait();RunService.RenderStepped:Wait()
 if generation~=serial or not valid(result) then if generation==serial then close()end;return end
 local shown=os.clock()
 task.delay(5,function()if generation==serial then close()end end)
 local ok,accepted=pcall(function()return dropRemote:InvokeServer("Shown",result.RunId,result.Id)end)
 if generation~=serial then return end
 if not ok or not accepted or os.clock()-shown>=5 or not valid(result) then close();return end
 positionButton();button.Visible=true;button.Interactable=true
end
remote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" or result.OwnerUserId~=player.UserId or typeof(result.Id)~="string" then return end
 if result.Outcome=="REPLACE" then
  if awaiting~=result.Id then close();awaiting=result.Id;pendingRun=result.RunId end
  return
 end
 if seen[result.Id] or awaiting and awaiting~=result.Id then return end
 close();awaiting=result.Id;pendingRun=result.RunId;seen[result.Id]=true
 task.delay(120,function()seen[result.Id]=nil end)
 if result.Discarded or result.Outcome~="ITEM" and result.Outcome~="ORE" then return end
 task.spawn(show,result,serial)
end)
for _,attribute in {"RunInventoryId","RunInventoryActive","CurrentWorld","RunReturnBusy"} do
 player:GetAttributeChangedSignal(attribute):Connect(function()
  if active and not valid(active) then close() end
  if attribute=="RunInventoryId" and player:GetAttribute("RunInventoryId")~=pendingRun then close();awaiting=nil;pendingRun=nil end
 end)
end
player.CharacterRemoving:Connect(function()close();awaiting=nil end)
RunService.Heartbeat:Connect(function()
 if active then
  if not valid(active) then close();return end
  positionButton()
 end
end)
