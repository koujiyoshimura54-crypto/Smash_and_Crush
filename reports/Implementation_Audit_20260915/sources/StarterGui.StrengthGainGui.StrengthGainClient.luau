local STRENGTH_GAIN_SOUND_A_ID = "rbxassetid://113108830240353"
local STRENGTH_GAIN_SOUND_B_ID = "rbxassetid://102855535543930"
local STRENGTH_GAIN_SOUND_VOLUME = 0
local STRENGTH_GAIN_SOUND_INTERVAL = 0.03
local STRENGTH_GAIN_SOUND_STOP_DELAY = 0.65

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=script.Parent
local Format=require(RS.Modules:WaitForChild("NumberFormat"))
local slots={}
local soundPool=gui:WaitForChild("SoundPool")
local sounds={}
local soundNames={"Keyboard Click","Keyboard Click2","Keyboard Click3","Keyboard Click4"}
local soundIds={STRENGTH_GAIN_SOUND_A_ID,STRENGTH_GAIN_SOUND_B_ID,STRENGTH_GAIN_SOUND_A_ID,STRENGTH_GAIN_SOUND_B_ID}
for i,name in ipairs(soundNames) do
 local sound=soundPool:FindFirstChild(name)
 if sound and sound:IsA("Sound") then
  sound.SoundId=soundIds[i]
  sound.Volume=STRENGTH_GAIN_SOUND_VOLUME
  sounds[#sounds+1]=sound
 end
end
local offsets={Vector2.new(-100,-40),Vector2.new(105,-65),Vector2.new(-65,-100),Vector2.new(95,-10),Vector2.new(-110,10)}
local index=0
local soundIndex=0
local lastGainAt=-math.huge
local nextSoundAt=0
local soundActive=false
local function playGainSound()
 soundIndex=soundIndex%#sounds+1
 local sound=sounds[soundIndex]
 sound:Stop();sound.TimePosition=0;sound:Play()
end
local soundConnection=RunService.Heartbeat:Connect(function()
 if not soundActive then return end
 local now=os.clock()
 if now-lastGainAt>=STRENGTH_GAIN_SOUND_STOP_DELAY then
  soundActive=false
  for _,sound in sounds do sound:Stop() end
 elseif now>=nextSoundAt then
  playGainSound()
  -- Do not catch up with a burst of sounds after a slow frame.
  nextSoundAt=now+math.max(0.01,STRENGTH_GAIN_SOUND_INTERVAL)
 end
end)
for i=1,5 do
 local frame=gui:WaitForChild("PopupPool"):WaitForChild("Popup"..i)
 slots[i]={frame=frame,tweens={}}
end
local function stop(slot)
 if slot.thread then task.cancel(slot.thread);slot.thread=nil end
 for _,t in slot.tweens do t:Cancel();t:Destroy() end
 table.clear(slot.tweens)
 slot.active=false;slot.frame.Visible=false
end
local function tween(slot,obj,time,props,style)
 local t=TweenService:Create(obj,TweenInfo.new(time,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
 table.insert(slot.tweens,t);t:Play()
end
local function gain(amount)
 if typeof(amount)~="number" or amount~=amount or amount<=0 or amount==math.huge then return end
 local now=os.clock()
 local expired=now-lastGainAt>=STRENGTH_GAIN_SOUND_STOP_DELAY
 lastGainAt=now
 if not soundActive or expired then
  soundActive=true
  playGainSound()
  nextSoundAt=now+math.max(0.01,STRENGTH_GAIN_SOUND_INTERVAL)
 end
 index=index%5+1
 local slot=slots[index];stop(slot)
 local frame=slot.frame;local label=frame.Amount
 label.Text="+"..Format.Format(amount)
 label.TextTransparency=0;label.Outline.Transparency=0
 frame.Pulse.Scale=.72
 slot.started=os.clock();slot.offset=offsets[index];slot.active=true
 slot.thread=task.spawn(function()
  tween(slot,frame.Pulse,.13,{Scale=1.08},Enum.EasingStyle.Back)
  task.wait(.13)
  tween(slot,frame.Pulse,.12,{Scale=1})
  task.wait(.25)
  tween(slot,label,.42,{TextTransparency=1})
  tween(slot,label.Outline,.42,{Transparency=1})
  task.wait(.42)
  slot.thread=nil;stop(slot)
 end)
end
local remoteConnection=RS.Remotes:WaitForChild("StrengthGain").OnClientEvent:Connect(gain)
local renderConnection=RunService.RenderStepped:Connect(function()
 local character=player.Character
 local head=character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
 local camera=workspace.CurrentCamera
 for _,slot in slots do
  if slot.active then
   local point,visible
   if head and camera then point,visible=camera:WorldToViewportPoint(head.Position) end
   slot.frame.Visible=visible==true
   if visible then
    local x=point.X+slot.offset.X
    local y=point.Y+slot.offset.Y-(os.clock()-slot.started)*55
    -- Keep the level-up title's central band free while both effects are visible.
    local levelGui=player.PlayerGui:FindFirstChild("LevelUpGui")
    local effect=levelGui and levelGui:FindFirstChild("LevelUpEffect",true)
    if effect and effect.Visible and math.abs(y-camera.ViewportSize.Y*.36)<80 then
     x=point.X+(slot.offset.X<0 and -1 or 1)*math.min(245,camera.ViewportSize.X*.32)
    end
    local half=slot.frame.AbsoluteSize*.54
    x=math.clamp(x,half.X+12,math.max(half.X+12,gui.AbsoluteSize.X-half.X-12))
    y=math.clamp(y,half.Y+12,math.max(half.Y+12,gui.AbsoluteSize.Y-half.Y-12))
    slot.frame.Position=UDim2.fromOffset(x,y)
   end
  end
 end
end)
script.Destroying:Once(function()
 remoteConnection:Disconnect();renderConnection:Disconnect();soundConnection:Disconnect()
 soundActive=false
 for _,slot in slots do stop(slot) end
 for _,sound in sounds do sound:Stop() end
end)

