-- Treadmill appearance only. Never reads Player state or changes training eligibility.
local RS=game:GetService("ReplicatedStorage")
local M={}
function M.Apply(treadmill,config)
 local name=config.VisualInstanceName or "TreadmillVisual"
 local existing=treadmill:FindFirstChild(name)
 local templateName=config.VisualTemplate
 if not templateName or templateName=="" then
  if existing then existing:Destroy() end
  return true
 end
 local library=RS:FindFirstChild("TreadmillVisualTemplates")
 local template=library and library:FindFirstChild(templateName)
 local root=template and template:IsA("Model") and template:FindFirstChild("Root")
 local zone=treadmill:FindFirstChild("TrainingZone")
 if not root or not root:IsA("BasePart") or not zone or not zone:IsA("BasePart") then
  return false,"Missing treadmill visual template / Root / TrainingZone: "..tostring(templateName)
 end
 local anchor=zone:FindFirstChild("VisualRoot")
 if not anchor then
  anchor=Instance.new("Attachment")
  anchor.Name="VisualRoot"
  anchor.Parent=zone
 end
 if not anchor:IsA("Attachment") then return false,"TrainingZone.VisualRoot must be an Attachment" end
 if existing and existing:GetAttribute("VisualTemplate")==templateName and existing:FindFirstChild("Root") then
  existing:PivotTo(anchor.WorldCFrame)
  return true
 end
 local effect=template:Clone()
 effect.Name=name
 effect.PrimaryPart=effect.Root
 effect:SetAttribute("VisualTemplate",templateName)
 effect:SetAttribute("ManagedBy","TreadmillVisualService")
 for _,v in effect:GetDescendants() do
  if v:IsA("BasePart") then
   v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
  elseif v:IsA("Highlight") then
   v.Adornee=treadmill
  end
 end
 effect:PivotTo(anchor.WorldCFrame)
 -- Replaces the authored PremiumAura too; never leave both old and new emitters.
 if existing then existing:Destroy() end
 effect.Parent=treadmill
 return true
end
return M
