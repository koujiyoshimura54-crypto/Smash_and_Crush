-- One-shot standard-camera heading alignment after each server spawn correction.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local handled = setmetatable({}, {__mode="k"})
local function align(character)
 if handled[character] then return end
 handled[character] = true
 local humanoid = character:WaitForChild("Humanoid", 10)
 if not humanoid then return end
 local deadline = os.clock()+10
 local camera
 repeat
  RunService.RenderStepped:Wait()
  camera = workspace.CurrentCamera
  if player.Character ~= character then return end
 until (character:GetAttribute("SpawnFacingDirection") and camera and camera.CameraSubject==humanoid) or os.clock()>=deadline
 if not camera or camera.CameraSubject~=humanoid then return end
 -- Let the standard CameraModule finish its new-subject initialization.
 RunService.RenderStepped:Wait()
 RunService.RenderStepped:Wait()
 if player.Character~=character or camera~=workspace.CurrentCamera
  or camera.CameraSubject~=humanoid or camera.CameraType~=Enum.CameraType.Custom then return end
 local direction = character:GetAttribute("SpawnFacingDirection")
 if typeof(direction)~="Vector3" then return end
 local focus = camera.Focus.Position
 local offset = camera.CFrame.Position-focus
 local horizontal = Vector3.new(offset.X,0,offset.Z).Magnitude
 if horizontal<0.01 then return end
 local look = Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
 if look.Magnitude>0 and look.Unit:Dot(direction)>0.999 then return end
 -- Retain standard zoom distance and elevation; change only the heading.
 local position = focus-direction*horizontal+Vector3.new(0,offset.Y,0)
 camera.CFrame = CFrame.lookAt(position,focus,Vector3.yAxis)
end
player.CharacterAdded:Connect(function(character) task.spawn(align,character) end)
if player.Character then task.spawn(align,player.Character) end
