-- Reversible, per-character Studio experiment. No account or profile writes.
local RunService=game:GetService("RunService")
local folder=script.Parent
local function enabled()
 return RunService:IsStudio() and game.PlaceId==126576845524886 and folder:GetAttribute("Enabled")==true
end
if not enabled() then return table.freeze({}) end
local Shape=require(folder.PlayableShapeConfig)
local Normal=require(game.ServerScriptService.Config.MuscleScaleConfig)
local M={}
local states=setmetatable({}, {__mode="k"})
local names={"UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
local bodySet={}
for _,name in names do bodySet[name]=true end
local rigNames={{"HumanoidRootPart","LowerTorso","Root"},{"LowerTorso","UpperTorso","Waist"},{"UpperTorso","Head","Neck"}}
for _,side in {"Left","Right"}do
 for _,link in {{"UpperTorso",side.."UpperArm",side.."Shoulder"},{side.."UpperArm",side.."LowerArm",side.."Elbow"},{side.."LowerArm",side.."Hand",side.."Wrist"},{"LowerTorso",side.."UpperLeg",side.."Hip"},{side.."UpperLeg",side.."LowerLeg",side.."Knee"},{side.."LowerLeg",side.."Foot",side.."Ankle"}}do table.insert(rigNames,link)end
end
local function frame(cf,scale)return CFrame.new(cf.Position*scale)*cf.Rotation end
local function halfY(cf,size)return(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)/2 end
local function basis(part)
 local b={Size=part.Size,Attachments={}}
 for _,a in part:GetChildren()do if a:IsA("Attachment")then b.Attachments[a]=a.CFrame end end
 return b
end
local function partOf(attachment)
 return attachment and attachment:FindFirstAncestorWhichIsA("BasePart")
end
local function bodyPart(s,part)
 return part and bodySet[part.Name] and (s.Normal.Parts[part.Name]==part or s.Muscle.Parts[part.Name]==part)
end
local function mapPart(s,part,kind)
 return bodyPart(s,part) and s[kind].Parts[part.Name] or part
end
local function mapAttachment(s,a,kind)
 if not a then return nil end
 local owner=partOf(a)
 if not bodyPart(s,owner)then return a end
 local path={};local at=a
 while at~=owner do table.insert(path,1,at.Name);at=at.Parent end
 local result=s[kind].Parts[owner.Name]
 for _,name in path do result=result and result:FindFirstChild(name) end
 assert(result and result:IsA("Attachment"),"Missing accessory attachment "..a.Name)
 return result
end
local function rememberAccessories(s)
 for _,acc in s.Character:GetChildren()do
  if acc:IsA("Accessory") and not s.Accessories[acc]then
   local records={};s.Accessories[acc]=records
   for _,v in acc:GetDescendants()do
    if v:IsA("Weld")then
     table.insert(records,{Object=v,Class="Weld",Parent=v.Parent,Name=v.Name,Part0=v.Part0,Part1=v.Part1,C0=v.C0,C1=v.C1})
    elseif v:IsA("RigidConstraint")then
     table.insert(records,{Object=v,Class="RigidConstraint",Parent=v.Parent,Name=v.Name,A0=v.Attachment0,A1=v.Attachment1,Enabled=v.Enabled})
    end
   end
  end
 end
end
local function reconnectAccessories(s,kind)
 for acc,records in s.Accessories do
  if acc.Parent==s.Character then
   for _,r in records do
    local object=r.Object
    if not object.Parent then
     object=r.Parent:FindFirstChild(r.Name)
     if not object or object.ClassName~=r.Class then object=Instance.new(r.Class);object.Name=r.Name;object.Parent=r.Parent end
     r.Object=object
    end
    if r.Class=="RigidConstraint"then
     object.Attachment0=mapAttachment(s,r.A0,kind);object.Attachment1=mapAttachment(s,r.A1,kind);object.Enabled=r.Enabled
    else
     object.Part0=mapPart(s,r.Part0,kind);object.Part1=mapPart(s,r.Part1,kind)
     local function endpoint(old,cf)
      if not bodyPart(s,old)then return cf end
      local target=s[kind].Parts[old.Name]
      local handle=acc:FindFirstChild("Handle")
      if handle then for _,a in handle:GetChildren()do
       if a:IsA("Attachment")then local match=target:FindFirstChild(a.Name);if match and match:IsA("Attachment")then return match.CFrame end end
      end end
      return frame(cf,target.Size/s.Normal.Bases[old.Name].Size)
     end
     object.C0=endpoint(r.Part0,r.C0);object.C1=endpoint(r.Part1,r.C1)
    end
   end
   local handle=acc:FindFirstChild("Handle")
   if handle then
    local rigid=handle:FindFirstChildOfClass("RigidConstraint")
    local weld=handle:FindFirstChild("AccessoryWeld")
    if rigid and rigid.Attachment0 and rigid.Attachment1 then
     local own=rigid.Attachment0:IsDescendantOf(handle) and rigid.Attachment0 or rigid.Attachment1
     local other=own==rigid.Attachment0 and rigid.Attachment1 or rigid.Attachment0
     handle.CFrame=other.WorldCFrame*own.CFrame:Inverse()
    elseif weld and weld.Part0 and weld.Part1 then handle.CFrame=weld.Part1.CFrame*weld.C1*weld.C0:Inverse()end
   end
  end
 end
end
local clothingTypes={TShirt=true,Shirt=true,Pants=true,Jacket=true,Sweater=true,Shorts=true,LeftShoe=true,RightShoe=true,DressSkirt=true}
local function wardrobe(s,hidden)
 for _,v in s.Character:GetChildren()do
  if v:IsA("Shirt")and not s.Wardrobe[v]then s.Wardrobe[v]={ShirtTemplate=v.ShirtTemplate}end
  if v:IsA("Accessory")then
   local headItem=v.AccessoryType==Enum.AccessoryType.Hair or v.AccessoryType==Enum.AccessoryType.Hat or v.AccessoryType==Enum.AccessoryType.Face
   if not headItem and(clothingTypes[v.AccessoryType.Name]or v:FindFirstChildWhichIsA("WrapLayer",true))then
    for _,object in v:GetDescendants()do
     if not s.Wardrobe[object]then
      if object:IsA("BasePart")or object:IsA("Decal")then s.Wardrobe[object]={Transparency=object.Transparency}
      elseif object:IsA("WrapLayer")then s.Wardrobe[object]={Enabled=object.Enabled}end
     end
    end
   end
  end
 end
 for object,properties in s.Wardrobe do
  if object:IsDescendantOf(s.Character)then
   for key,value in properties do
    if not hidden then object[key]=value
    elseif key=="Transparency"then object[key]=1
    elseif key=="ShirtTemplate"then object[key]=""
    else object[key]=false end
   end
  end
 end
end
local function scalesFor(kind,stage,manual,y,thickness)
 local scales={Head=Vector3.one,HumanoidRootPart=kind=="Muscle"and Shape.GetScale("HumanoidRootPart",manual and 0 or stage)or Vector3.one}
 for _,name in names do
  local base=kind=="Muscle"and Shape.GetScale(name,manual and 0 or stage)or Normal.GetPartScale(name,manual and 0 or stage)
  scales[name]=manual and base*Vector3.new(thickness,y,thickness)or base
 end
 return scales
end
local function measure(s,kind,scales)
 local frames={HumanoidRootPart=CFrame.identity}
 for _=1,16 do for _,j in s[kind].Rig do
  if frames[j.P0] and not frames[j.P1]then frames[j.P1]=frames[j.P0]*frame(j.C0,scales[j.P0])*frame(j.C1,scales[j.P1]):Inverse()end
 end end
 local bottom=math.huge
 for _,side in {"Left","Right"}do
  local name=side.."Foot";local cf=assert(frames[name],"Disconnected foot")
  bottom=math.min(bottom,cf.Y-halfY(cf,s[kind].Bases[name].Size*scales[name]))
 end
 local head=assert(frames.Head,"Disconnected head")
 local top=head.Y+halfY(head,s.Head.Size)
 return top-bottom,bottom,frames
end
local function settings(s,kind,stage,manual,height,thickness)
 local base=scalesFor(kind,0,false)
 local baseline=measure(s,kind,base)
 local y=1
 if manual then
  -- Solve whole standing height, including the unchanged head, not torso Y alone.
  local lo,hi=.01,32
  local target=baseline*height
  for _=1,32 do
   local mid=(lo+hi)/2
   if measure(s,kind,scalesFor(kind,0,true,mid,thickness))<target then lo=mid else hi=mid end
  end
  y=(lo+hi)/2
 end
 local scales=scalesFor(kind,stage,manual,y,thickness)
 local measured,bottom,frames=measure(s,kind,scales)
 return scales,measured,bottom,frames,baseline,y
end
local function prepareMuscle(s)
 local donor=assert(folder:FindFirstChild("PlayableSourceBody"),"Missing prototype source")
 local d=s.Muscle
 for _,name in names do
  local source=donor:FindFirstChild(name)
  assert(source and source:IsA("MeshPart"),"Missing muscle part "..name)
  local part=source:Clone();part.Parent=d.Store
  for _,v in part:GetDescendants()do
   if v:IsA("JointInstance")or v:IsA("Constraint")or v:IsA("BaseScript")or v:IsA("ValueBase")or v:IsA("WrapTarget")then v:Destroy()end
  end
  -- Keep the avatar's original cage data; no clothing or cage redesign.
  for _,v in s.Normal.Parts[name]:GetChildren()do
   if v:IsA("WrapTarget")then v:Clone().Parent=part
   elseif v:IsA("Attachment")and not part:FindFirstChild(v.Name)then
    local a=v:Clone();a.CFrame=frame(v.CFrame,source.Size/s.Normal.Bases[name].Size);a.Parent=part
   end
  end
  part.Color=s.Normal.Parts[name].Color;part.Anchored=false
  part.CanCollide=name=="UpperTorso"or name=="LowerTorso"
  part.CanTouch=true;part.CollisionGroup=s.Root.CollisionGroup
  d.Parts[name]=part;d.Bases[name]=basis(part)
 end
 d.RootSize=assert(donor:FindFirstChild("HumanoidRootPart")).Size*Shape.GetScale("HumanoidRootPart",0)
 for _,source in donor:GetDescendants()do if source:IsA("Motor6D")then
  assert(source.Part0 and source.Part1,"Broken muscle joint")
  local p0,p1=source.Part0.Name,source.Part1.Name
  assert((p0=="HumanoidRootPart"or d.Parts[p0])and(p1=="Head"or d.Parts[p1]),"Unexpected muscle joint")
  local j=Instance.new("Motor6D");j.Name=source.Name;j.Parent=d.Store
  table.insert(d.Rig,{Object=j,P0=p0,P1=p1,C0=source.C0,C1=p1=="Head"and s.Head.NeckRigAttachment.CFrame or source.C1})
 end end
 assert(#d.Rig==15,"Expected 15 muscle joints")
 measure(s,"Muscle",scalesFor("Muscle",0,false))
end
function M.Apply(character,valid)
 if not enabled()or not valid()then return false,"Inactive"end
 if states[character]then return true,"AlreadyPrepared"end
 local h=character:FindFirstChildOfClass("Humanoid")
 local root=character:FindFirstChild("HumanoidRootPart");local head=character:FindFirstChild("Head")
 if not h or h.RigType~=Enum.HumanoidRigType.R15 or h.Health<=0 or not root or not head then return false,"R15 character not ready"end
 local cache=Instance.new("Folder");cache.Name="RuntimeBodyComparison"
 local s={Character=character,Humanoid=h,Root=root,Head=head,Cache=cache,Kind="Normal",Accessories={},Wardrobe={},Original={Hip=h.HipHeight,Scaling=h.AutomaticScalingEnabled,Neck=h.RequiresNeck,Priority=root.RootPriority,RootCollide=root.CanCollide,HeadCollide=head.CanCollide}}
 for _,kind in {"Normal","Muscle"}do local store=Instance.new("Folder");store.Name=kind;store.Parent=cache;s[kind]={Parts={},Bases={},Rig={},Links={},Store=store}end
 local ok,why=pcall(function()
  s.Normal.RootSize=root.Size
  for _,name in names do local part=character:FindFirstChild(name);assert(part and part:IsA("BasePart"),"Missing avatar part "..name);s.Normal.Parts[name]=part;s.Normal.Bases[name]=basis(part)end
  for _,link in rigNames do
   local p0,p1,name=link[1],link[2],link[3]
   local a=assert(character[p0]:FindFirstChild(name.."RigAttachment"),"Missing "..name.." attachment")
   local b=assert(character[p1]:FindFirstChild(name.."RigAttachment"),"Missing "..name.." attachment")
   table.insert(s.Normal.Rig,{P0=p0,P1=p1,C0=a.CFrame,C1=b.CFrame})
  end
  for _,v in character:GetDescendants()do
   if not v:FindFirstAncestorWhichIsA("Accessory")and(v:IsA("JointInstance")or v:IsA("Constraint"))then
    local a,b
    pcall(function()a=v.Part0;b=v.Part1 end)
    if not a then pcall(function()a=partOf(v.Attachment0);b=partOf(v.Attachment1)end)end
    if bodyPart(s,a)or bodyPart(s,b)then
     local record={Object=v,Parent=v.Parent}
     if v:IsA("Motor6D")then record.P0=a.Name;record.P1=b.Name;record.C0=v.C0;record.C1=v.C1 end
     table.insert(s.Normal.Links,record)
    end
   end
  end
  prepareMuscle(s)
  rememberAccessories(s)
 end)
 if not ok or not valid()or not enabled()then cache:Destroy();return false,ok and "Stale character"or tostring(why)end
 cache.Parent=folder
 states[character]=s
 character:SetAttribute("BodyPrototypeManaged",true)
 return true
end
local function apply(s,stage,options)
 local active=options and options.Active==true
 local kind=active and options.Body or "Normal"
 local manual=active and options.Mode=="Manual"
 local shownStage=active and options.Mode=="Growth"and options.Stage or stage
 local height=manual and options.Height or 1;local thickness=manual and options.Thickness or 1
 local scales,measured,bottom,frames,baseline,y=settings(s,kind,shownStage,manual,height,thickness)
 local root,hum=s.Root,s.Humanoid
 local anchored=root.Anchored;local cf=root.CFrame;local support
 if (not anchored or s.NeckTransition)and s.Last then
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={s.Character};params.RespectCanCollide=true
  local hit=workspace:Raycast(root.Position,Vector3.new(0,-hum.HipHeight-root.Size.Y/2-2,0),params)
  if hit and hit.Normal.Y>.8 and math.abs(root.Position.Y-hit.Position.Y-hum.HipHeight-root.Size.Y/2)<1.2 and math.abs(root.AssemblyLinearVelocity.Y)<2 then support=hit.Position.Y end
 end
 root.Anchored=true;hum.RequiresNeck=false;hum.AutomaticScalingEnabled=false
 rememberAccessories(s)
 if s.Kind~=kind then
  if s.Kind=="Normal"then
   for _,r in s.Normal.Links do r.Object.Parent=s.Normal.Store end
  else for _,j in s.Muscle.Rig do j.Object.Parent=s.Muscle.Store end end
  for _,part in s[s.Kind].Parts do part.Parent=s[s.Kind].Store end
  for _,part in s[kind].Parts do part.Parent=s.Character end
  s.Kind=kind
 end
 root.Size=s[kind].RootSize
 root.RootPriority=active and 127 or s.Original.Priority
 root.CanCollide=kind~="Muscle"and s.Original.RootCollide
 s.Head.CanCollide=kind~="Muscle"and s.Original.HeadCollide
 for name,part in s[kind].Parts do
  local b=s[kind].Bases[name];part.Size=b.Size*scales[name]
  for a,base in b.Attachments do if a.Parent==part then a.CFrame=frame(base,scales[name])end end
 end
 if kind=="Muscle"then
  for _,j in s.Muscle.Rig do
   j.Object.Part0=j.P0=="HumanoidRootPart"and root or s.Muscle.Parts[j.P0]
   j.Object.Part1=j.P1=="Head"and s.Head or s.Muscle.Parts[j.P1]
   j.Object.C0=frame(j.C0,scales[j.P0]);j.Object.C1=frame(j.C1,scales[j.P1]);j.Object.Parent=j.Object.Part1
  end
 else
  for _,r in s.Normal.Links do
   if r.C0 then r.Object.C0=frame(r.C0,scales[r.P0]or Vector3.one);r.Object.C1=frame(r.C1,scales[r.P1]or Vector3.one)end
   r.Object.Parent=r.Parent
  end
 end
 hum.HipHeight=kind=="Normal"and not manual and s.Original.Hip*Normal.GetHeightScale(shownStage)or math.max(.05,-bottom-root.Size.Y/2)
 if support then cf=CFrame.new(cf.X,support+hum.HipHeight+root.Size.Y/2+.03,cf.Z)*cf.Rotation end
 root.CFrame=cf
 for name,pose in frames do
  if name~="HumanoidRootPart"then (name=="Head"and s.Head or s[kind].Parts[name]).CFrame=cf*pose end
 end
 reconnectAccessories(s,kind)
 wardrobe(s,active)
 -- Assigning an already connected limb/accessory can translate its assembly.
 -- Restore the requested root pose after all connected parts have been updated.
 root.CFrame=cf
 hum.RequiresNeck=not s.NeckTransition and s.Original.Neck
 -- This gated controller owns both normal and manual dimensions for this character.
 -- Re-enabling the engine scaler here would overwrite the restored saved SIZE.
 hum.AutomaticScalingEnabled=false
 root.Anchored=anchored
 local dumbbell=kind=="Muscle"and(manual and .5 or Shape.GetDumbbellScale(shownStage))or 1
 if manual then dumbbell*=math.min(3,math.sqrt(thickness))end
 s.Character:SetAttribute("BodyPrototypeDumbbellScale",active and dumbbell or nil)
 s.Character:SetAttribute("BodyPrototypeActive",kind=="Muscle")
 s.Character:SetAttribute("BodyPrototypeStage",manual and 0 or shownStage)
 s.Character:SetAttribute("BodyComparisonActive",active)
 s.Character:SetAttribute("BodyComparisonKind",kind)
 s.Character:SetAttribute("BodyComparisonMode",active and options.Mode or "Saved")
 s.Character:SetAttribute("BodyComparisonHeight",measured)
 s.Character:SetAttribute("BodyComparisonBaseHeight",baseline)
 s.Character:SetAttribute("BodyComparisonHeightRatio",measured/baseline)
 s.Character:SetAttribute("BodyComparisonThickness",manual and thickness or nil)
 s.Character:SetAttribute("BodyComparisonVerticalScale",y)
 local revision=(s.Character:GetAttribute("BodyComparisonRevision")or 0)+1
 for _,part in s[kind].Parts do part:SetAttribute("ComparisonPoseRevision",revision)end
 s.Character:SetAttribute("BodyComparisonRevision",revision)
 s.Character:SetAttribute("MuscleHeightScale",measured/baseline)
end
function M.ApplyStage(character,stage,options)
 local s=states[character]
 if not enabled()or not s or s.Humanoid.Health<=0 then return false,"Character unavailable"end
 if typeof(stage)~="number"or stage%1~=0 or stage<0 or stage>10 then return false,"Invalid stage"end
 if options and options.Active then
  if options.Body~="Normal"and options.Body~="Muscle"then return false,"Invalid body"end
  if options.Mode~="Growth"and options.Mode~="Manual"then return false,"Invalid mode"end
  if typeof(options.Stage)~="number"or options.Stage%1~=0 or options.Stage<0 or options.Stage>10 then return false,"Invalid comparison stage"end
  for _,entry in {{options.Height,Shape.Manual.MinHeight,Shape.Manual.MaxHeight},{options.Thickness,Shape.Manual.MinThickness,Shape.Manual.MaxThickness}}do local value=entry[1];if typeof(value)~="number"or value~=value or value<entry[2]or value>entry[3]then return false,"Invalid multiplier"end end
 end
 local previous=s.Last
 local root=s.Root;local wasAnchored=root.Anchored
 local ok,why=pcall(apply,s,stage,options)
 if not ok then
  local restored,restoreWhy=pcall(apply,s,previous and previous.Stage or 0,previous and previous.Options)
  root.Anchored=wasAnchored;s.Humanoid.RequiresNeck=not s.NeckTransition and s.Original.Neck
  if not restored then warn("[BodyComparison] Restore failed: "..tostring(restoreWhy))end
  return false,"Body change failed: "..tostring(why)
 end
 s.Last={Stage=stage,Options=options and table.clone(options)}
 return true
end
function M.BeginTransition(character)
 local s=states[character]
 if not s then return nil end
 s.NeckTransition=true;s.Humanoid.RequiresNeck=false
 return s.Original.Neck
end
function M.EndTransition(character)
 local s=states[character]
 if s then s.NeckTransition=false;s.Humanoid.RequiresNeck=s.Original.Neck end
end
function M.Release(character)
 local s=states[character];states[character]=nil
 if s then s.Cache:Destroy()end
end
return M
