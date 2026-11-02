-- Presentation only. AuraCharacterEffects owns equip, removal and character lifetime.
-- Reuses authored fire/lightning emitters; never displays the inventory icon in 3D.
local M={}
function M.Create(settings,library)
 local model=Instance.new("Model");model.Name="Eclipse_Aura1"
 model:SetAttribute("AttachTo","HumanoidRootPart")
 local root=Instance.new("Part");root.Name="Root";root.Size=settings.EmitterSize
 root.Transparency=1;root.Anchored=true;root.CanCollide=false;root.CanTouch=false;root.CanQuery=false
 root.Parent=model;model.PrimaryPart=root
 local function flame(name,color,rate,light)
  local emitter=library.Red_Aura1.Root.aura:Clone()
  emitter.Name=name;emitter.Color=ColorSequence.new(color);emitter.Rate=rate
  emitter.Texture=name=="DarkFlame" and settings.DarkTexture or settings.FlameTexture
  emitter.ZOffset=settings.ZOffset;emitter.Rotation=NumberRange.new(-10,10)
  emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,settings.FlameSize*.45),NumberSequenceKeypoint.new(.35,settings.FlameSize),NumberSequenceKeypoint.new(1,0)})
  emitter.Speed=settings.FlameSpeed;emitter.Lifetime=settings.FlameLifetime
  emitter.LightEmission=light;emitter.LightInfluence=0
  emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(.25,.12),NumberSequenceKeypoint.new(1,1)})
  emitter.EmissionDirection=Enum.NormalId.Top;emitter.SpreadAngle=Vector2.new(15,15)
  emitter.Enabled=true;emitter.Parent=root
 end
 flame("DarkFlame",settings.DarkColor,settings.DarkRate,0)
 flame("PurpleFlame",settings.FlameColor,settings.FlameRate,.35)
 local lightning=library.Pink_Aura3.Root.Lightning1:Clone()
 lightning.Name="GoldLightning";lightning.Color=ColorSequence.new(settings.GoldColor)
 lightning.Rate=settings.LightningRate;lightning.Size=NumberSequence.new(settings.LightningSize)
 lightning.Lifetime=settings.LightningLifetime;lightning.Speed=NumberRange.new(0)
 lightning.Orientation=Enum.ParticleOrientation.FacingCamera;lightning.ZOffset=settings.ZOffset
 lightning.LightEmission=.8;lightning.LightInfluence=0;lightning.Enabled=true;lightning.Parent=root
 local ring=Instance.new("Part");ring.Name="FootRing";ring.Size=Vector3.new(.1,.1,.1)
 ring.Transparency=1;ring.Anchored=true;ring.CanCollide=false;ring.CanTouch=false;ring.CanQuery=false
 ring.CFrame=CFrame.new(0,-3+settings.FootClearance,0);ring.Parent=model
 local points={}
 for i=0,3 do
  local a=i*math.pi/2
  local pos=Vector3.new(math.cos(a)*settings.RingRadius,0,math.sin(a)*settings.RingRadius)
  local tangent=Vector3.new(-math.sin(a),0,math.cos(a))
  local attachment=Instance.new("Attachment");attachment.Name="RingPoint"..i
  attachment.CFrame=CFrame.fromMatrix(pos,tangent,Vector3.yAxis);attachment.Parent=ring
  points[i+1]=attachment
 end
 for i=1,4 do
  local beam=Instance.new("Beam");beam.Name="GoldRing"..i
  beam.Attachment0=points[i];beam.Attachment1=points[i%4+1]
  beam.CurveSize0=settings.RingRadius*.55228475;beam.CurveSize1=beam.CurveSize0
  beam.Width0=settings.RingWidth;beam.Width1=settings.RingWidth;beam.Segments=16
  beam.Color=ColorSequence.new(settings.GoldColor);beam.Transparency=NumberSequence.new(settings.RingTransparency)
  beam.FaceCamera=true;beam.LightEmission=.8;beam.LightInfluence=0;beam.Parent=ring
 end
 return model
end
function M.PlaceRing(effect,humanoid,target,settings)
 local ring=effect:FindFirstChild("FootRing")
 if not ring or not humanoid then return end
 local leg=humanoid.Parent:FindFirstChild("Left Leg")
 local depth=humanoid.HipHeight+target.Size.Y/2
 if humanoid.RigType==Enum.HumanoidRigType.R6 and leg then depth+=leg.Size.Y end
 local offset=CFrame.new(0,-depth+settings.FootClearance,0)
 local weld=ring:FindFirstChild("AuraMount")
 if weld and weld:IsA("Weld") then weld.C0=offset
 else ring.CFrame=effect.Root.CFrame*offset end
end
return M
