-- Explicit, Studio-only experiment. No PlayerAdded connection and no production installer.
local M = {}
local RunService = game:GetService("RunService")
local bodyNames = {"UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
local bodySet = {}
for _, name in bodyNames do bodySet[name] = true end
local colorKeys = {Head="HeadColor3",UpperTorso="TorsoColor3",LowerTorso="TorsoColor3"}
for _, side in {"Left","Right"} do
 for _, suffix in {"UpperArm","LowerArm","Hand"} do colorKeys[side..suffix]=side.."ArmColor3" end
 for _, suffix in {"UpperLeg","LowerLeg","Foot"} do colorKeys[side..suffix]=side.."LegColor3" end
end
function M.Skin(character, override)
 local colors=character:FindFirstChildOfClass("BodyColors")
 for name,key in colorKeys do
  local part=character:FindFirstChild(name)
  if part then part.Color=override or (colors and colors[key]) or part.Color end
 end
 -- Color only the skin channel. Never touch head texture, Decal, Shirt/Pants, or accessories.
end
function M.Clothes(character, shirt, pants)
 for _,v in character:GetChildren() do
  if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then v:Destroy() end
 end
 if shirt then shirt:Clone().Parent=character end
 if pants then pants:Clone().Parent=character end
end
function M.Signature(character)
 local h=character:FindFirstChild("Head")
 local result={headClass=h.ClassName,headSize=tostring(h.Size),mesh=h:IsA("MeshPart") and h.MeshId or "",faceControls=0,bones=0,decals={},attachments={},accessories={}}
 for _,v in h:GetDescendants() do
  if v:IsA("FaceControls") then result.faceControls+=1 end
  if v:IsA("Bone") then result.bones+=1 end
  if v:IsA("Decal") then table.insert(result.decals,v.Name.."="..v.Texture) end
  if v:IsA("Attachment") and not v:IsA("Bone") then table.insert(result.attachments,v.Name.."="..tostring(v.CFrame)) end
 end
 for _,v in character:GetChildren() do
  if v:IsA("Accessory") then
   local handle=v:FindFirstChild("Handle")
   local a=handle and handle:FindFirstChildOfClass("Attachment")
   local weld=handle and handle:FindFirstChild("AccessoryWeld")
   local rigid=handle and handle:FindFirstChild("AccessoryRigidConstraint")
   table.insert(result.accessories,{name=v.Name,attachment=a and a.Name or "",part1=(weld and weld.Part1 and weld.Part1.Name) or (rigid and rigid.Attachment1 and rigid.Attachment1.Parent.Name) or ""})
  end
 end
 table.sort(result.attachments);table.sort(result.decals)
 return result
end
function M.Apply(character, ratio)
 assert(RunService:IsStudio() and game.PlaceId==126576845524886,"Duplicate Studio only")
 assert(ratio==0.3 or ratio==0.4,"Experimental ratios only")
 if character:GetAttribute("BodyPrototypeRatio") then
  assert(character:GetAttribute("BodyPrototypeRatio")==ratio,"Use a freshly loaded character to change base ratio")
  return false -- Same-character reapplication does not recapture grown dimensions.
 end
 local humanoid=assert(character:FindFirstChildOfClass("Humanoid"))
 local head=assert(character:FindFirstChild("Head"))
 local root=assert(character:FindFirstChild("HumanoidRootPart"))
 assert(humanoid.RigType==Enum.HumanoidRigType.R15)
 local before=M.Signature(character)
 for _,acc in character:GetChildren() do
  if acc:IsA("Accessory") then
   local handle=acc:FindFirstChild("Handle")
   local attachment=handle and handle:FindFirstChildOfClass("Attachment")
   local weld=handle and handle:FindFirstChild("AccessoryWeld")
   local onHead=(attachment and head:FindFirstChild(attachment.Name)) or (weld and weld.Part1==head)
   if not onHead then acc:Destroy() end -- Body layered clothing has no cage on this prototype.
  end
 end
 local neck=assert(head:FindFirstChild("NeckRigAttachment"),"Keep donor head's neck attachment")
 local source=script.Parent.SourceBody:Clone()
 source.Humanoid.AutomaticScalingEnabled=false
 source:ScaleTo(ratio)
 local fixed=source:FindFirstChild("Handle");if fixed then fixed:Destroy() end
 local motors={}
 for _,v in source:GetDescendants() do
  if v:IsA("Motor6D") then
   table.insert(motors,{Name=v.Name,P0=v.Part0.Name,P1=v.Part1.Name,C0=v.C0,C1=v.C1})
   v:Destroy()
  elseif v:IsA("Constraint") or v:IsA("Weld") then v:Destroy() end
 end
 local wasAnchored=root.Anchored
 root.Anchored=true
 humanoid.AutomaticScalingEnabled=false
 humanoid.RequiresNeck=false
 for _,v in character:GetDescendants() do
  if v:IsA("Motor6D") and ((v.Part0 and bodySet[v.Part0.Name]) or (v.Part1 and (bodySet[v.Part1.Name] or v.Part1==head))) then v:Destroy()
  elseif v:IsA("NoCollisionConstraint") then v:Destroy()
  elseif v:IsA("Constraint") and ((v.Attachment0 and bodySet[v.Attachment0.Parent.Name]) or (v.Attachment1 and bodySet[v.Attachment1.Parent.Name])) then v:Destroy() end
 end
 for _,name in bodyNames do local old=character:FindFirstChild(name);if old then old:Destroy() end end
 root.Size=source.HumanoidRootPart.Size
 root.CanCollide=false
 for _,name in bodyNames do
  local part=source[name]
  part.CFrame=root.CFrame*source.HumanoidRootPart.CFrame:ToObjectSpace(part.CFrame)
  part.Anchored=false
  part.CanCollide=(name=="UpperTorso" or name=="LowerTorso")
  part.CollisionGroup=root.CollisionGroup
  part.Parent=character
 end
 local joints={}
 for _,data in motors do
  local motor=Instance.new("Motor6D")
  motor.Name=data.Name
  motor.Part0=assert(character:FindFirstChild(data.P0))
  motor.Part1=assert(character:FindFirstChild(data.P1))
  motor.C0=data.C0
  motor.C1=data.P1=="Head" and neck.CFrame or data.C1
  motor.Parent=motor.Part1
  table.insert(joints,motor)
 end
 -- Resolve the new rest pose without asking the engine to rebuild/replace the purchased head.
 local done={[root]=true}
 for _=1,16 do
  for _,joint in joints do
   if done[joint.Part0] and not done[joint.Part1] then
    joint.Part1.CFrame=joint.Part0.CFrame*joint.C0*joint.C1:Inverse()
    done[joint.Part1]=true
   end
  end
 end
 for _,acc in character:GetChildren() do
  if acc:IsA("Accessory") then
   local handle=acc:FindFirstChild("Handle")
   local weld=handle and handle:FindFirstChild("AccessoryWeld")
   if weld and weld.Part0 and weld.Part1 then handle.CFrame=weld.Part1.CFrame*weld.C1*weld.C0:Inverse() end
   if handle then handle.CanCollide=false;handle.Massless=true end
  end
 end
 humanoid.HipHeight=source.Humanoid.HipHeight
 humanoid.RequiresNeck=true
 head.CanCollide=false
 M.Skin(character)
 source:Destroy()
 character:SetAttribute("BodyPrototypeRatio",ratio)
 character:SetAttribute("BodyPrototypeHeadPolicy","Original asset and original dimensions")
 character:SetAttribute("BodyPrototypeHeadBefore",game:GetService("HttpService"):JSONEncode(before))
 character:SetAttribute("BodyPrototypeBaseHip",humanoid.HipHeight)
 character:SetAttribute("BodyPrototypeBaseUpperTorso",character.UpperTorso.Size)
 character:SetAttribute("BodyPrototypeBaseUpperArm",character.RightUpperArm.Size)
 root.Anchored=wasAnchored
 return true
end
return M
