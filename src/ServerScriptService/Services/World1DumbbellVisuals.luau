-- Geometry-only clones shared by the authored stands and existing held display.
-- No asset/network loads, equipment mutation, purchases, rewards, or data writes.
local Storage=game:GetService("ServerStorage")
-- Historical module path retained for World1 callers. Both worlds share the
-- same clone/attach lifecycle; the full equipped ItemId selects the registry.
local Config=require(game.ReplicatedStorage.Config.World1DumbbellVisualConfig)
local World2Config=require(game.ReplicatedStorage.Config.World2DumbbellVisualConfig)
local function registration(itemId)
 if typeof(itemId)~="string" then return nil end
 if Config.Items[itemId] then return Config,Config.Items[itemId],1 end
 if World2Config.Items[itemId] then return World2Config,World2Config.Items[itemId],2 end
end
local M={}
local warned={}
local function warnOnce(key,message)
 key=tostring(key)
 if warned[key] then return end
 warned[key]=true;warn("[World1DumbbellVisuals] "..message)
end
local function rotation(degrees)
 return CFrame.Angles(math.rad(degrees.X),math.rad(degrees.Y),math.rad(degrees.Z))
end
function M.Get(itemId,worldId)
 if worldId~=1 and worldId~=2 then return nil end
 -- Moving worlds does not itself change the authoritative equipped ItemId.
 local _,row=registration(itemId)
 return row
end
function M.ThicknessForCharacter(character,itemId)
 local config,row=registration(itemId)
 local base=row and row.HeldThicknessMultiplier or 1
 local tuning=config and config.BodyThickness
 local height=character:GetAttribute("MuscleHeightScale")
 if typeof(height)~="number" or height~=height or not tuning then return base end
 local span=tuning.FullHeightRatio-tuning.BaseHeightRatio
 if span<=0 then return base end
 local progress=math.clamp((height-tuning.BaseHeightRatio)/span,0,1)
 return base*(1+(tuning.MaxMultiplier-1)*progress)
end
function M.Clone(itemId,kind,bodyScale,thicknessOverride)
 local config,row,worldId=registration(itemId)
 local library=config and Storage:FindFirstChild(config.LibraryName)
 local source=row and library and library:FindFirstChild(row.Template)
 if not source or not source:IsA("Model") or not source.PrimaryPart then
  warnOnce(itemId,"Missing registered geometry for "..tostring(itemId));return nil
 end
 local display=source:Clone()
 local root=display.PrimaryPart
 -- Only geometry/materials/attachments may enter either display. Template
 -- purchase Parts, scripts, Tools, prompts and external joints never come along.
 for _,x in display:GetDescendants() do
  if not (x:IsA("Model") or x:IsA("BasePart") or x:IsA("SurfaceAppearance")
   or x:IsA("DataModelMesh") or x:IsA("Decal") or x:IsA("Texture") or x:IsA("Attachment")) then x:Destroy() end
 end
 local _,size=display:GetBoundingBox()
 if size.X<=0 then display:Destroy();return nil end
 local length=kind=="Exhibit" and row.DisplayLength or row.HeldLength
 local factor=kind=="Exhibit" and 1 or bodyScale or 1
 if typeof(length)~="number" or length<=0 or typeof(factor)~="number" or factor<=0 or factor~=factor then
  display:Destroy();return nil
 end
 display:ScaleTo(display:GetScale()*length/size.X*factor)
 -- Registered templates have the handle along local X. Increase only the
 -- cross-section (Y/Z) around the grip; keep bar width and grip center fixed.
 -- Apply from a fresh clone before welding, never to last frame's display.
 local thickness=kind=="Exhibit" and 1 or thicknessOverride or row.HeldThicknessMultiplier or 1
 if typeof(thickness)~="number" or thickness<=0 or thickness~=thickness or thickness==math.huge then
  display:Destroy();return nil
 end
 if thickness~=1 then
  local pivot=display:GetPivot()
  local stretch=Vector3.new(1,thickness,thickness)
  for _,part in display:GetDescendants() do if part:IsA("BasePart") then
   local localFrame=pivot:ToObjectSpace(part.CFrame)
   -- All registered mesh/primitive axes are aligned with the grip axes.
   local partScale=Vector3.new((localFrame.RightVector*stretch).Magnitude,
    (localFrame.UpVector*stretch).Magnitude,(localFrame.LookVector*stretch).Magnitude)
   part.Size*=partScale
   part.CFrame=pivot*CFrame.new(localFrame.Position*stretch)*localFrame.Rotation
  end end
 end
 for _,part in display:GetDescendants() do if part:IsA("BasePart") then
  part.Anchored=kind=="Exhibit"
  part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
  if kind~="Exhibit" and part~=root then
   local weld=Instance.new("WeldConstraint");weld.Name="VisualWeld"
   weld.Part0=root;weld.Part1=part;weld.Parent=part
  end
 end end
 display:SetAttribute("ItemId",itemId)
 display:SetAttribute("DumbbellVisual",true)
 display:SetAttribute("World"..worldId.."DumbbellVisual",true)
 display:SetAttribute("VisualWorldId",worldId)
 return display
end
function M.Attach(character,side,hand,itemId,bodyScale,prototype)
 local display=M.Clone(itemId,"Held",bodyScale,M.ThicknessForCharacter(character,itemId))
 if not display then return false end
 local config,row=registration(itemId)
 local offset=prototype and Vector3.new(0,-hand.Size.Y*.12,0) or config.HandOffset*(bodyScale or 1)
 local grip=row.GripOffset*(bodyScale or 1)
 display.Name="TrainingDumbbell"..side
 display:PivotTo(hand.CFrame*CFrame.new(offset+grip)*rotation(row.HeldRotation))
 local weld=Instance.new("WeldConstraint");weld.Name=side.."HandWeld"
 weld.Part0=hand;weld.Part1=display.PrimaryPart;weld.Parent=display.PrimaryPart
 display.Parent=character
 return true
end
local function iconFor(stand)
 local board=stand:FindFirstChild("BillboardGui")
 local icon=board and board:FindFirstChild("ItemIcon")
 return icon and icon:IsA("ImageLabel") and icon or nil
end
function M.RefreshExhibit(stand,rebuild)
 -- ItemId is authoritative. Never assign models by child order or World2 grade.
 local itemId=stand:GetAttribute("ItemId")
 local config,row,worldId=registration(itemId)
 local press=stand:FindFirstChild("Press")
 if not row or (stand:GetAttribute("WorldId") or 1)~=worldId or not press or not press:IsA("BasePart") then return false end
 local display=stand:FindFirstChild(config.ExhibitName)
 if display and (rebuild or display:GetAttribute("ItemId")~=itemId) then display:Destroy();display=nil end
 if not display then
  display=M.Clone(itemId,"Exhibit")
  if display then display.Name=config.ExhibitName;display.Parent=stand end
 end
 local icon=iconFor(stand)
 if icon then
  local original="World"..worldId.."DumbbellOriginalImageTransparency"
  if icon:GetAttribute(original)==nil then
   icon:SetAttribute(original,icon.ImageTransparency)
  end
  -- Keep Visible/layout/Image intact: hiding the row would move price text.
  icon.ImageTransparency=display and 1 or icon:GetAttribute(original)
 end
 if not display then return false end
 display:PivotTo(press.CFrame*CFrame.new(row.DisplayOffset)*rotation(row.DisplayRotation))
 return true
end
return M
