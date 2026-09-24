local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local gui=script.Parent
local responsive=gui:WaitForChild("ResponsiveEffect")
local effect=responsive:WaitForChild("LevelUpEffect")
local function fit()
 local d=responsive:GetAttribute("DesignSize")
 responsive.ViewportScale.Scale=math.clamp(math.min(1,(gui.AbsoluteSize.X-24)/(d.X*1.08),(gui.AbsoluteSize.Y-24)/(d.Y*1.08)),.55,1)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local scale=effect:WaitForChild("PulseScale")
local sound=effect:WaitForChild("Level_up")
local levelText=effect:WaitForChild("LevelText")
local origin=effect.Position
local tweens={}
local animation
local generation=0
local previous
local function valid(value)
 return typeof(value)=="number" and value==value and value>=1 and value<math.huge
end
local function cancel()
 generation+=1
 if animation then task.cancel(animation);animation=nil end
 for _,t in tweens do t:Cancel();t:Destroy() end
 table.clear(tweens)
 sound:Stop()
 effect.Visible=false
end
local function tween(object,duration,properties,style)
 local t=TweenService:Create(object,TweenInfo.new(duration,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
 table.insert(tweens,t);t:Play()
end
local function show(level)
 cancel()
 local token=generation
 effect.Position=origin
 effect.GroupTransparency=.55
 scale.Scale=.78
 levelText.Text="LV "..tostring(level)
 effect.Visible=true
 sound.TimePosition=0
 sound:Play()
 animation=task.spawn(function()
  tween(scale,.16,{Scale=1.08},Enum.EasingStyle.Back)
  tween(effect,.12,{GroupTransparency=0})
  task.wait(.16)
  if generation~=token then return end
  tween(scale,.12,{Scale=1})
  task.wait(.46)
  if generation~=token then return end
  tween(effect,.36,{Position=origin-UDim2.fromOffset(0,24),GroupTransparency=1})
  tween(scale,.36,{Scale=.97})
  task.wait(.36)
  if generation~=token then return end
  effect.Visible=false
  animation=nil
  for _,t in tweens do t:Destroy() end
  table.clear(tweens)
 end)
end
local function changed()
 local value=player:GetAttribute("Level")
 if not valid(value) then previous=nil;cancel();return end
 local old=previous
 previous=value
 if old==nil then return end
 if value>old then show(value)
 elseif value<old then cancel() end
end
effect.Visible=false
local connection=player:GetAttributeChangedSignal("Level"):Connect(changed)
changed()
script.Destroying:Once(function() connection:Disconnect();cancel() end)
