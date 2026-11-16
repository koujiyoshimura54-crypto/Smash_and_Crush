-- Loaded only after the Studio/place/Enabled gate in the current spawn owner.
local RunService = game:GetService("RunService")
local folder = script.Parent
local function enabled()
 return RunService:IsStudio() and game.PlaceId == 126576845524886
  and folder:GetAttribute("Enabled") == true
end
if not enabled() then return table.freeze({}) end
local Shape = require(folder.PlayableShapeConfig)
local M = {}
local states = setmetatable({}, {__mode="k"})
local names = {"UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand",
 "RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot",
 "RightUpperLeg","RightLowerLeg","RightFoot"}
local bodySet = {}
for _,name in names do bodySet[name] = true end
local function scaledFrame(cf, scale)
 return CFrame.new(cf.Position * scale) * cf.Rotation
end
local function skinColor(character, name, fallback)
 local colors = character:FindFirstChildOfClass("BodyColors")
 if not colors then return fallback end
 local key = "TorsoColor3"
 for _,side in {"Left","Right"} do
  if name:sub(1,#side)==side then
   key = side .. ((name:find("Arm") or name:find("Hand")) and "ArmColor3" or "LegColor3")
  end
 end
 return colors[key]
end
local function keepAccessory(accessory, head)
 local handle = accessory:FindFirstChild("Handle")
 if not handle then return false end
 for _,v in handle:GetChildren() do
  if v:IsA("Attachment") and head:FindFirstChild(v.Name) then return true end
  if v:IsA("Weld") and (v.Part0==head or v.Part1==head) then return true end
  if v:IsA("RigidConstraint") and
   ((v.Attachment0 and v.Attachment0:IsDescendantOf(head)) or
    (v.Attachment1 and v.Attachment1:IsDescendantOf(head))) then return true end
 end
 return false
end
local function restFrames(state)
 local frames = {[state.Root]=CFrame.identity}
 for _=1,16 do
  for _,j in state.Joints do
   if frames[j.Part0] and not frames[j.Part1] then
    frames[j.Part1] = frames[j.Part0] * j.C0 * j.C1:Inverse()
   end
  end
 end
 for _,name in names do assert(frames[state.Parts[name]], "Disconnected "..name) end
 assert(frames[state.Head], "Disconnected head")
 return frames
end
local function resize(state, stage, placeParts)
 for name,part in state.Parts do
  local scale = Shape.GetScale(name,stage)
  local base = state.Bases[name]
  part.Size = base.Size * scale
  for attachment,cf in base.Attachments do
   if attachment.Parent==part then attachment.CFrame = scaledFrame(cf,scale) end
  end
 end
 -- Keep the collision/replication root constant while growing the visible rig.
 state.Root.Size = state.RootSourceSize * Shape.GetScale("HumanoidRootPart",0)
 for joint,base in state.JointBases do
  joint.C0 = scaledFrame(base.C0,Shape.GetScale(base.P0,stage))
  joint.C1 = base.P1=="Head" and state.NeckFrame or scaledFrame(base.C1,Shape.GetScale(base.P1,stage))
 end
 local frames = restFrames(state)
 local bottom = math.huge
 for _,side in {"Left","Right"} do
  local foot = state.Parts[side.."Foot"]
  local cf = frames[foot]
  local half = (math.abs(cf.RightVector.Y)*foot.Size.X + math.abs(cf.UpVector.Y)*foot.Size.Y + math.abs(cf.LookVector.Y)*foot.Size.Z)/2
  bottom = math.min(bottom,cf.Position.Y-half)
 end
 -- Derive clearance from the fully assembled rest rig, including feet and root.
 state.Humanoid.HipHeight = math.max(0.05,-bottom-state.Root.Size.Y/2)
 for part,shorts in state.Shorts do
  shorts.Size = part.Size * Vector3.new(1.018,1.012,1.018)
 end
 if placeParts then
  for part,cf in frames do if part~=state.Root then part.CFrame=state.Root.CFrame*cf end end
  for part,shorts in state.Shorts do shorts.CFrame=part.CFrame end
 end
 state.Character:SetAttribute("BodyPrototypeDumbbellScale",Shape.GetDumbbellScale(stage))
 state.Character:SetAttribute("BodyPrototypeStage",stage)
 state.Character:SetAttribute("MuscleHeightScale",Shape.GetScale("UpperTorso",stage).Y / Shape.GetScale("UpperTorso",0).Y)
end

function M.Apply(character, valid)
 if not enabled() or not valid() then return false,"Inactive" end
 if states[character] then return true,"AlreadyApplied" end
 local hum = character:FindFirstChildOfClass("Humanoid")
 local head = character:FindFirstChild("Head")
 local root = character:FindFirstChild("HumanoidRootPart")
 local donor = folder:FindFirstChild("PlayableSourceBody")
 if not hum or hum.RigType~=Enum.HumanoidRigType.R15 or hum.Health<=0
  or not head or not head:IsA("BasePart") or not root or not donor then
  return false,"Missing R15 character or prototype source"
 end
 local neck = head:FindFirstChild("NeckRigAttachment")
 if not neck or not neck:IsA("Attachment") then return false,"Missing original head neck attachment" end
 -- Prepare and validate every replacement before touching the live character.
 local staging = Instance.new("Model")
 local state = {Character=character,Humanoid=hum,Head=head,Root=root,NeckFrame=neck.CFrame,
  Parts={},Bases={},Joints={},JointBases={},Shorts={}}
 local ok,why = pcall(function()
  local donorRoot = assert(donor:FindFirstChild("HumanoidRootPart"),"Missing donor root")
  state.RootSourceSize = donorRoot.Size
  for _,name in names do
   local old = character:FindFirstChild(name)
   local source = donor:FindFirstChild(name)
   assert(old and old:IsA("BasePart") and source and source:IsA("MeshPart"),"Missing body part "..name)
   local part = source:Clone()
   part.Parent = staging
   for _,v in part:GetDescendants() do
    if v:IsA("JointInstance") or v:IsA("Constraint") or v:IsA("BaseScript")
     or v:IsA("ValueBase") or v:IsA("WrapTarget") then v:Destroy() end
   end
   part.Color = skinColor(character,name,old.Color)
   part.Anchored=false;part.CanCollide=(name=="UpperTorso" or name=="LowerTorso")
   part.CanTouch=true;part.CollisionGroup=root.CollisionGroup
   local attachments={}
   for _,a in part:GetChildren() do if a:IsA("Attachment") then attachments[a]=a.CFrame end end
   state.Parts[name]=part;state.Bases[name]={Size=source.Size,Attachments=attachments}
  end
  for _,source in donor:GetDescendants() do
   if source:IsA("Motor6D") then
    assert(source.Part0 and source.Part1,"Broken donor joint")
    local p0,p1=source.Part0.Name,source.Part1.Name
    local joint=Instance.new("Motor6D")
    joint.Name=source.Name
    joint.Part0=p0=="HumanoidRootPart" and root or state.Parts[p0]
    joint.Part1=p1=="Head" and head or state.Parts[p1]
    assert(joint.Part0 and joint.Part1,"Unexpected donor joint "..source.Name)
    joint.C0=source.C0;joint.C1=p1=="Head" and neck.CFrame or source.C1
    joint.Parent=staging
    table.insert(state.Joints,joint)
    state.JointBases[joint]={P0=p0,P1=p1,C0=source.C0,C1=source.C1}
   end
  end
  assert(#state.Joints==15,"Expected complete 15-joint R15 body")
  restFrames(state)
  local shorts=Instance.new("Model");shorts.Name="PrototypeShorts";shorts.Parent=staging
  for _,name in {"LowerTorso","LeftUpperLeg","RightUpperLeg"} do
   local body=state.Parts[name]
   local shell=body:Clone();shell.Name=name.."Shorts"
   shell:ClearAllChildren();shell.TextureID=""
   shell.Color=Color3.fromRGB(19,21,26);shell.Material=Enum.Material.SmoothPlastic
   shell.CanCollide=false;shell.CanTouch=false;shell.CanQuery=false;shell.Massless=true
   shell.Parent=shorts
   state.Shorts[body]=shell
  end
  state.ShortModel=shorts
 end)
 if not ok then staging:Destroy();return false,tostring(why) end
 if not valid() or not enabled() then staging:Destroy();return false,"Stale character" end

 local retained={}
 local accessoryWelds={}
 for _,accessory in character:GetChildren() do
  if accessory:IsA("Accessory") then
   for _,w in accessory:GetDescendants() do
    if w:IsA("Weld") and w.Name=="AccessoryWeld" then
     table.insert(accessoryWelds,{Parent=w.Parent,Name=w.Name,Part0=w.Part0,Part1=w.Part1,
      C0=w.C0,C1=w.C1,HandleFrame=w.Parent:IsA("BasePart") and w.Parent.CFrame or nil})
    end
   end
  end
 end
 local function detach(object)
  table.insert(retained,{Object=object,Parent=object.Parent})
  object.Parent=nil
 end
 local original={Size=root.Size,Anchored=root.Anchored,Collide=root.CanCollide,Priority=root.RootPriority,
  Scaling=hum.AutomaticScalingEnabled,Neck=hum.RequiresNeck,Hip=hum.HipHeight,
  HeadCollide=head.CanCollide,HeadCF=head.CFrame}
 -- No yielding inside this transaction: a failure restores the complete original rig.
 ok,why=pcall(function()
  root.Anchored=true;root.RootPriority=127
  hum.RequiresNeck=false;hum.AutomaticScalingEnabled=false
  local originals={}
  for _,name in names do originals[character[name]]=true end
  for _,v in character:GetDescendants() do
   local remove=false
   if v:IsA("JointInstance") then remove=originals[v.Part0] or originals[v.Part1]
   elseif v:IsA("NoCollisionConstraint") then remove=originals[v.Part0] or originals[v.Part1]
   elseif v:IsA("Constraint") then
    local readable,a0,a1=pcall(function()return v.Attachment0,v.Attachment1 end)
    remove=readable and ((a0 and originals[a0.Parent]) or (a1 and originals[a1.Parent]))
   end
   if remove then detach(v) end
  end
  for _,v in character:GetChildren() do
   if originals[v] or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic")
    or (v:IsA("Accessory") and not keepAccessory(v,head)) then detach(v) end
  end
  for _,part in state.Parts do part.Parent=character end
  for _,joint in state.Joints do joint.Parent=joint.Part1 end
  state.ShortModel.Parent=character
  root.CanCollide=false;head.CanCollide=false
  resize(state,0,true)
  for part,shell in state.Shorts do
   local weld=Instance.new("WeldConstraint");weld.Name="BodyFit"
   weld.Part0=part;weld.Part1=shell;weld.Parent=shell
  end
  for _,acc in character:GetChildren() do
   if acc:IsA("Accessory") then
    local handle=acc:FindFirstChild("Handle")
    local weld=handle and handle:FindFirstChild("AccessoryWeld")
    if weld and weld.Part0 and weld.Part1 then handle.CFrame=weld.Part1.CFrame*weld.C1*weld.C0:Inverse() end
   end
  end
  hum.RequiresNeck=original.Neck
  root.Anchored=original.Anchored
 end)
 if not ok then
  for _,j in state.Joints do j:Destroy() end
  for _,p in state.Parts do p:Destroy() end
  state.ShortModel:Destroy()
  for _,entry in retained do entry.Object.Parent=entry.Parent end
  root.Size=original.Size;root.CanCollide=original.Collide;root.RootPriority=original.Priority
  head.CanCollide=original.HeadCollide;head.CFrame=original.HeadCF
  hum.HipHeight=original.Hip;hum.AutomaticScalingEnabled=original.Scaling
  hum.RequiresNeck=original.Neck;root.Anchored=original.Anchored
  -- Humanoid can remove engine-managed accessory welds while rebuilding a rig.
  -- Recreate their original links if a failed transaction caused that cleanup.
  for _,record in accessoryWelds do
   if record.Parent.Parent then
    local weld=record.Parent:FindFirstChild(record.Name)
    if not weld then weld=Instance.new("Weld");weld.Name=record.Name end
    weld.Part0=record.Part0;weld.Part1=record.Part1;weld.C0=record.C0;weld.C1=record.C1
    if record.HandleFrame then record.Parent.CFrame=record.HandleFrame end
    weld.Parent=record.Parent
   end
  end
  character:SetAttribute("BodyPrototypeDumbbellScale",nil)
  character:SetAttribute("BodyPrototypeStage",nil)
  character:SetAttribute("MuscleHeightScale",nil)
  staging:Destroy()
  return false,"Rolled back: "..tostring(why)
 end
 for _,entry in retained do entry.Object:Destroy() end
 staging:Destroy()
 states[character]=state
 character:SetAttribute("BodyPrototypeActive",true)
 return true
end

function M.ApplyStage(character,stage)
 local state=states[character]
 if not enabled() or not state or state.Humanoid.Health<=0 then return false end
 if typeof(stage)~="number" or stage%1~=0 or stage<0 or stage>10 then return false end
 resize(state,stage,false)
 return true
end
function M.Release(character)
 states[character]=nil
end
return M
