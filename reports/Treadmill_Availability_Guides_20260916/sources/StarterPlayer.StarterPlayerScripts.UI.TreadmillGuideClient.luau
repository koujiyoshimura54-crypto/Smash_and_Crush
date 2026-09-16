-- Local visual only. Server mirrors TrainingManager.CanUseTreadmill; no permission rules here.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Config:WaitForChild("TreadmillConfig"))
local player = Players.LocalPlayer
local settings = Config.Guide
if not settings or not settings.Enabled then return end
local playerGui = player:WaitForChild("PlayerGui")
local surfaces = Instance.new("Folder")
surfaces.Name = "TreadmillGuideSurfaces"
surfaces.Parent = workspace
local guis = Instance.new("Folder")
guis.Name = "TreadmillGuides"
guis.Parent = playerGui
local records, connections = {}, {}
local alive, queued = true, false
local pixels = 40
local spacing = math.max(0.5, settings.Spacing)
local speed = math.max(0.05, settings.Speed)

local function findBelt(model)
 for _,part in model:GetDescendants() do
  if part:IsA("BasePart") then
   local size = part.Size
   if part:GetAttribute("TreadmillVisualRole") == "Belt"
    or (math.abs(size.X-8)<0.08 and math.abs(size.Y-0.98)<0.08 and math.abs(size.Z-18)<0.08) then
    return part
   end
  end
 end
end

local function update(record)
 local available = player:GetAttribute("TreadmillAvailable_"..record.name) == true
 if record.gui.Enabled == available then return end
 record.gui.Enabled = available
 if available then record.tween:Play() else record.tween:Pause() end
end

local function create(name, belt, entry)
 local surface = Instance.new("Part")
 surface.Name = name.."_GuideSurface"
 surface.Anchored = true
 surface.Transparency = 1
 surface.CanCollide = false
 surface.CanTouch = false
 surface.CanQuery = false
 surface.CastShadow = false
 surface.Size = Vector3.new(belt.Size.X, belt.Size.Z, 0.01)
 -- Front faces upward; GUI-down follows the authored belt LookVector.
 surface.CFrame = CFrame.fromMatrix(
  belt.Position + belt.CFrame.UpVector*(belt.Size.Y/2+0.04),
  belt.CFrame.RightVector, -belt.CFrame.LookVector, -belt.CFrame.UpVector)
 surface.Parent = surfaces
 local gui = Instance.new("SurfaceGui")
 gui.Name = name
 gui.Adornee = surface
 gui.Face = Enum.NormalId.Front
 gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
 gui.CanvasSize = Vector2.new(belt.Size.X*pixels, belt.Size.Z*pixels)
 gui.LightInfluence = 0
 gui.AlwaysOnTop = false
 gui.Active = false
 gui.ResetOnSpawn = false
 gui.Enabled = false
 gui.Parent = guis
 local clip = Instance.new("Frame")
 clip.Name = "Clip"
 clip.BackgroundTransparency = 1
 clip.Size = UDim2.fromScale(1,1)
 clip.ClipsDescendants = true
 clip.Parent = gui
 local strip = Instance.new("Frame")
 strip.Name = "MovingChevrons"
 strip.BackgroundTransparency = 1
 strip.Size = UDim2.fromScale(1,1)
 strip.Parent = clip
 local color = entry.RequiresPremium and settings.PremiumColor
  or entry.Multiplier == 3 and settings.BlueColor
  or entry.Multiplier == 5 and settings.GreenColor or settings.NormalColor
 local width = math.min(settings.Size.X, belt.Size.X-0.5)*pixels
 local length = settings.Size.Y*pixels
 -- Same twin-arm Chevron geometry as TutorialGuideClient; no asset dependency.
 for row = -1, math.ceil(belt.Size.Z/spacing)+1 do
  for _,side in {-1,1} do
   local tail = Vector2.new(side*width/2, -length/2)
   local tip = Vector2.new(0, length/2)
   local delta = tip-tail
   local midpoint = (tail+tip)/2
   local arm = Instance.new("Frame")
   arm.Name = "ChevronArm"
   arm.AnchorPoint = Vector2.new(0.5,0.5)
   arm.Position = UDim2.new(0.5,midpoint.X,0,row*spacing*pixels+midpoint.Y)
   arm.Size = UDim2.fromOffset(delta.Magnitude, settings.Thickness*pixels)
   arm.Rotation = math.deg(math.atan2(delta.Y,delta.X))
   arm.BackgroundColor3 = color
   arm.BackgroundTransparency = math.clamp(settings.Transparency,0,1)
   arm.BorderSizePixel = 0
   arm.Parent = strip
  end
 end
 local tween = TweenService:Create(strip,
  TweenInfo.new(spacing/speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut,-1),
  {Position=UDim2.fromOffset(0,spacing*pixels)})
 local record = {name=name,belt=belt,surface=surface,gui=gui,tween=tween}
 record.connection = player:GetAttributeChangedSignal("TreadmillAvailable_"..name):Connect(function() update(record) end)
 update(record)
 return record
end

local function remove(record)
 record.connection:Disconnect()
 record.tween:Cancel()
 record.gui:Destroy()
 record.surface:Destroy()
end
local function refresh()
 if not alive then return end
 local folder = workspace:FindFirstChild("Treadmill")
 for name in pairs(Config.Assignments) do
  local model = folder and folder:FindFirstChild(name)
  local belt = model and findBelt(model)
  local old = records[name]
  if old and old.belt ~= belt then remove(old); records[name]=nil end
  if belt and not records[name] then records[name]=create(name,belt,Config.Get(name)) end
 end
end
local function schedule(instance)
 if instance == surfaces or instance:IsDescendantOf(surfaces) then return end
 local folder = workspace:FindFirstChild("Treadmill")
 if instance.Name ~= "Treadmill" and not (folder and instance:IsDescendantOf(folder)) then return end
 if queued then return end
 queued = true
 task.defer(function() queued=false; refresh() end)
end
table.insert(connections,workspace.DescendantAdded:Connect(schedule))
table.insert(connections,workspace.DescendantRemoving:Connect(schedule))
script.Destroying:Connect(function()
 alive=false
 for _,connection in connections do connection:Disconnect() end
 for _,record in records do remove(record) end
 guis:Destroy()
 surfaces:Destroy()
end)
refresh()
