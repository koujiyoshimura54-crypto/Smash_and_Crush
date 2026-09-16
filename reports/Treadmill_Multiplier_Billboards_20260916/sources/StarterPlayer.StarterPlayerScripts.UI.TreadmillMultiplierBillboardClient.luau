-- Local-only group guidance. Standard BillboardGui handles facing and distance.
local Players=game:GetService("Players")
local Config=require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("TreadmillConfig"))
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local settings=Config.MultiplierBillboard
local guiFolder=Instance.new("Folder")
guiFolder.Name="TreadmillMultiplierBillboards"
guiFolder.Parent=playerGui
local anchors=Instance.new("Folder")
anchors.Name="TreadmillMultiplierAnchors"
anchors.Parent=workspace
local groups={}
for modelName in pairs(Config.Assignments) do
 local entry=Config.Get(modelName)
 if entry and Config.StrengthColors[entry.Multiplier] then
  local group=groups[entry.Multiplier] or {names={}}
  groups[entry.Multiplier]=group
  table.insert(group.names,modelName)
 end
end

local function updateVisibility()
 local enabled=player:GetAttribute("IsTraining")~=true
 for _,group in pairs(groups) do
  if group.gui then group.gui.Enabled=enabled end
 end
end

local function removeDisplay(group)
 if group.gui then group.gui:Destroy(); group.gui=nil end
 if group.anchor then group.anchor:Destroy(); group.anchor=nil end
end

local function refresh()
 local folder=workspace:FindFirstChild("Treadmill")
 for multiplier,group in pairs(groups) do
  local center=Vector3.zero
  local complete=folder~=nil and #group.names==2
  for _,name in ipairs(group.names) do
   local model=folder and folder:FindFirstChild(name)
   local display=model and model:FindFirstChild("TreadmillUIDisplay")
   if display and display:IsA("BasePart") then center+=display.Position
   else complete=false end
  end
  if not complete then
   removeDisplay(group)
  else
   if not group.gui then
    local anchor=Instance.new("Part")
    anchor.Name="MultiplierAnchor_"..multiplier
    anchor.Size=Vector3.new(.1,.1,.1)
    anchor.Anchored=true
    anchor.Transparency=1
    anchor.CanCollide=false
    anchor.CanTouch=false
    anchor.CanQuery=false
    anchor.CastShadow=false
    anchor.Parent=anchors
    group.anchor=anchor

    local gui=Instance.new("BillboardGui")
    gui.Name="Multiplier_"..multiplier
    gui.Adornee=anchor
    gui.AlwaysOnTop=false
    gui.LightInfluence=0
    gui.ResetOnSpawn=false
    gui.Active=false
    gui.Parent=guiFolder
    group.gui=gui

    local label=Instance.new("TextLabel")
    label.Name="Multiplier"
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1
    label.Font=Enum.Font.GothamBlack
    label.Text="×"..tostring(multiplier)
    label.TextScaled=true
    label.TextColor3=Config.StrengthColors[multiplier].BeltColor
    label.Parent=gui
    local stroke=Instance.new("UIStroke")
    stroke.Color=Config.StrengthColors[multiplier].MatColor
    stroke.Thickness=3
    stroke.Parent=label
   end
   group.anchor.Position=center/#group.names
   group.gui.Size=UDim2.fromScale(settings.Size.X*settings.TextScale,settings.Size.Y*settings.TextScale)
   group.gui.StudsOffsetWorldSpace=settings.StudsOffset
   group.gui.MaxDistance=settings.MaxDistance
  end
 end
 updateVisibility()
end

-- Rebuild only when relevant streamed objects arrive/leave, never each frame.
local queued=false
local function schedule(instance)
 if instance.Name~="Treadmill" and instance.Name~="TreadmillUIDisplay"
  and not Config.Assignments[instance.Name] then return end
 if queued then return end
 queued=true
 task.defer(function()
  queued=false
  refresh()
 end)
end
local connections={
 player:GetAttributeChangedSignal("IsTraining"):Connect(updateVisibility),
 workspace.DescendantAdded:Connect(schedule),
 workspace.DescendantRemoving:Connect(schedule),
 player.CharacterAdded:Connect(function() task.defer(refresh) end),
}
script.Destroying:Connect(function()
 for _,connection in ipairs(connections) do connection:Disconnect() end
 guiFolder:Destroy()
 anchors:Destroy()
end)
refresh()
