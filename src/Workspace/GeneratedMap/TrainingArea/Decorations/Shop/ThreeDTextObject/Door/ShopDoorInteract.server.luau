local TweenService = game:GetService('TweenService')
local door = script.Parent
local hingePart = door:WaitForChild('Door_Right')
local attachment = hingePart:WaitForChild('ShopDoorPromptAttachment')
local prompt = attachment:WaitForChild('ShopDoorPrompt')
-- The existing sign handle stays fixed relative to the Shop while the door swings.
local reference = door.Parent:WaitForChild("ThreeDTextHandle")
local referenceCF = reference.CFrame
local hingeCF = hingePart.CFrame * CFrame.new(hingePart.Size.X / 2, 0, 0)
local hingeLocal = referenceCF:ToObjectSpace(hingeCF)
local rotation = CFrame.Angles(0, math.rad(-90), 0)
local parts = {}
for _, name in ipairs({"Door_Top","Door_Under","Door_Left","Doorhandle_2","Door_Center","Door_Right","Doorhandle_1","Door_Grass"}) do
 local part = door:WaitForChild(name)
 local closed = referenceCF:ToObjectSpace(part.CFrame)
 local open = hingeLocal * rotation * hingeLocal:Inverse() * closed
 table.insert(parts, {part=part, closed=closed, open=open})
end
local state = false
local busy = false
local progress = Instance.new('NumberValue')
progress.Name = 'DoorTweenProgress'
progress.Value = 0
progress.Parent = script
local function apply(value)
 for _, item in ipairs(parts) do item.part.CFrame = reference.CFrame * item.closed:Lerp(item.open, value) end
end
progress.Changed:Connect(apply)
apply(0)
local tweenInfo = TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
prompt.Triggered:Connect(function()
 if busy then return end
 busy = true
 local target = state and 0 or 1
 local tween = TweenService:Create(progress, tweenInfo, {Value = target})
 tween.Completed:Once(function(playbackState)
  if playbackState == Enum.PlaybackState.Completed then
   state = (target == 1)
   prompt.ActionText = state and 'Close' or 'Open'
  end
  busy = false
 end)
 tween:Play()
end)