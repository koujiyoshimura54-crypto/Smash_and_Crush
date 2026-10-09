-- Only the seven purchased treadmill captions; no Speed gameplay or old presentation startup.
local function bindTreadmillCaptions(folder,player,config,lifetime)
 local labels={}
 local connections={}
 local function disconnect(label)
  local record=labels[label]
  if not record then return end
  for _,connection in ipairs(record) do connection:Disconnect() end
  labels[label]=nil
 end
 local function bind(label)
  if labels[label] or not label:IsA("TextLabel") then return end
  if label.Name~="Multiplier" and label.Name~="MultiplierShadow" then return end
  local board=label.Parent
  local model=board and board.Parent
  if not board or board.Name~="BillboardGui" or not model or model.Parent~=folder then return end
  if not config.Get(model.Name) then return end
  local function update()
   if model.Parent~=folder or label.Parent~=board then return end
   local text=config.GetGainDisplayText(model.Name,player.LocaleId)
   if not text then return end
   -- Explicit local wording prevents a stale automatic translation from restoring Speed.
   if label.AutoLocalize then label.AutoLocalize=false end
   if label.Text~=text then label.Text=text end
  end
  labels[label]={
   label:GetPropertyChangedSignal("Text"):Connect(update),
   label:GetPropertyChangedSignal("AutoLocalize"):Connect(update),
   player:GetPropertyChangedSignal("LocaleId"):Connect(update),
  }
  update()
 end
 table.insert(connections,folder.DescendantAdded:Connect(bind))
 table.insert(connections,folder.DescendantRemoving:Connect(disconnect))
 for _,label in ipairs(folder:GetDescendants()) do bind(label) end
 table.insert(connections,lifetime.Destroying:Connect(function()
  for label in pairs(labels) do disconnect(label) end
  for _,connection in ipairs(connections) do connection:Disconnect() end
 end))
end

task.spawn(function()
 local folder=workspace:WaitForChild("Treadmills")
 local player=game:GetService("Players").LocalPlayer
 local config=require(game.ReplicatedStorage.Config:WaitForChild("TreadmillConfig"))
 bindTreadmillCaptions(folder,player,config,script)
end)

-- Only Basic Egg/Pet presentation; never start the purchased Main loader.
task.spawn(function()
 local services=game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Services")
 local ok,err=pcall(function() require(services:WaitForChild("PetClient")).bootstrap() end)
 if not ok then warn("[BasicEgg] Client startup failed: "..tostring(err)) end
end)

-- Start only the purchased Feedback module from this existing active client.
task.spawn(function()
 local playerScripts=game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")
 local feedback=playerScripts:WaitForChild("Services"):WaitForChild("FeedbackClient")
 local ok,err=pcall(function() require(feedback).start() end)
 if not ok then warn("[FeedbackClient] Start failed: "..tostring(err)) end
end)

-- Start the isolated purchased Trophy bridge, never the purchased Main/Data loader.
task.spawn(function()
 local services=game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Services")
 local ok,err=pcall(function() require(services:WaitForChild("CheapClient")).start() end)
 if not ok then warn("[TrophyWinPass] Start failed: "..tostring(err)) end
end)

-- Phase 7.2.3.1: shared menu presentation only.
-- Skip and Rebirth are bound by their existing client scripts.
local TweenService=game:GetService("TweenService")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local layout=require(game.ReplicatedStorage.Modules:WaitForChild("HUDLayout")).Mount(gui).Refresh
for _,name in ipairs({"SkipButton","InventoryButton","RebirthButton","ShopButton","MergeButton"}) do
 local button=menu:WaitForChild(name)
 local tween
 local function highlight(on)
  if tween then tween:Cancel() end
  tween=TweenService:Create(button,TweenInfo.new(0.12),{
   BackgroundColor3=on and Color3.fromRGB(53,65,89) or Color3.fromRGB(29,35,49),
  })
  tween:Play()
 end
 button.MouseEnter:Connect(function() highlight(button.Active) end)
 button.MouseLeave:Connect(function() highlight(false) end)
 button.SelectionGained:Connect(function() highlight(button.Active) end)
 button.SelectionLost:Connect(function() highlight(false) end)
end
-- Inventory interaction is handled by InventoryPanelClient.


gui.Parent.ChildAdded:Connect(function(child) if child.Name=="World1DoubleWinGui" then task.defer(layout) end end)
task.defer(layout)
