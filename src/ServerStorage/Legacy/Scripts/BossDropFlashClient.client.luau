-- Common is an editable VFX container. The legacy Remote name remains compatible.
local RS=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local remote=RS.Remotes:WaitForChild("BossDropFlash")
local library=RS.VFX:WaitForChild("BossDropVFX")
local function numberAttribute(instance,name,fallback)
 local value=instance:GetAttribute(name)
 if typeof(value)~="number" or value~=value or value<0 or value==math.huge then return fallback end
 return value
end
local function play(cf)
 if typeof(cf)~="CFrame" then return end
 local template=library:FindFirstChild("Common")
 if not template then return end
 local effect=Instance.new("Model");effect.Name="BossDropVFXEffect"
 local anchor=Instance.new("Part")
 anchor.Name="Origin";anchor.Size=Vector3.new(4,1,2);anchor.Transparency=1
 anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
 anchor.CFrame=cf;anchor.Parent=effect
 local content=template:Clone()
 local origin=template:IsA("BasePart") and template.CFrame or (template:IsA("Model") and template:GetPivot() or CFrame.identity)
 local nodes={content}
 for _,v in content:GetDescendants() do table.insert(nodes,v) end
 local duration=0
 for _,v in nodes do
  if v:IsA("BaseScript") or v:IsA("ModuleScript") then v:Destroy()
  elseif v:IsA("BasePart") then
   v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
   v.CFrame=cf*origin:ToObjectSpace(v.CFrame)
  elseif v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then v.Enabled=false end
 end
 content.Parent=effect
 -- Loose attachments/emitters are supported, as well as authored Part/Model rigs.
 for _,v in nodes do
  if v.Parent and v:IsA("Attachment") and not (v.Parent:IsA("BasePart") or v.Parent:IsA("Attachment")) then
   v.Parent=anchor
  elseif v.Parent and (v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")) and not (v.Parent:IsA("BasePart") or v.Parent:IsA("Attachment")) then
   v.Parent=anchor
  end
 end
 effect.Parent=workspace
 for _,v in nodes do
  if v.Parent and v:IsA("ParticleEmitter") then
   local delay=numberAttribute(v,"EmitDelay",0)
   local count=math.floor(numberAttribute(v,"EmitCount",1))
   duration=math.max(duration,delay+v.Lifetime.Max/math.max(v.TimeScale,0.01))
   task.delay(delay,function() if v.Parent then v:Emit(count) end end)
  elseif v.Parent and (v:IsA("Beam") or v:IsA("Trail") or v:IsA("Light")) then
   local delay=numberAttribute(v,"EmitDelay",0)
   local length=numberAttribute(v,"EmitDuration",0.4)
   duration=math.max(duration,delay+length+(v:IsA("Trail") and v.Lifetime or 0))
   task.delay(delay,function()
    if not v.Parent then return end
    v.Enabled=true
    task.delay(length,function() if v.Parent then v.Enabled=false end end)
   end)
  end
 end
 Debris:AddItem(effect,duration+0.5)
end
remote.OnClientEvent:Connect(play)
