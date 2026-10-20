local CollectionService=game:GetService("CollectionService")
local TREADMILL_TAG="TrainingTreadmill"
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Config = require(game:GetService("ReplicatedStorage").Config:WaitForChild("TreadmillConfig"))
local red = Color3.fromRGB(255, 60, 60)
local blue = Color3.fromRGB(55, 145, 255)

-- Keep purchased artwork/fonts; reserve explicit text width instead of
-- AutomaticSize.X + TextScaled competing inside a clipped horizontal row.
local function set(object,key,value) if object and object[key]~=value then object[key]=value end end
local function title(folder,treadmill)
 local part=folder and folder:FindFirstChild("Billboard")
 local gui=part and part:FindFirstChildWhichIsA("BillboardGui")
 if not gui then return end
 set(gui,"Adornee",part)
 if treadmill then set(gui,"Size",UDim2.fromScale(40,9));set(gui,"StudsOffsetWorldSpace",Vector3.new(0,4,0))end
 local row=gui:FindFirstChildOfClass("UIListLayout")
 if row then set(row,"Padding",UDim.new(.03,0));set(row,"HorizontalAlignment",Enum.HorizontalAlignment.Center);set(row,"VerticalAlignment",Enum.VerticalAlignment.Center)end
 local icon=gui:FindFirstChild("Icon");set(icon,"Size",UDim2.fromScale(.17,.9))
 local label=gui:FindFirstChild("Name")
 if label then
  set(label,"AutomaticSize",Enum.AutomaticSize.None);set(label,"Size",UDim2.fromScale(.76,.9));set(label,"TextScaled",true)
  -- Fit the complete localized heading in one line; keep the row's outline margin.
  set(label,"TextWrapped",not treadmill)
  if treadmill then
   set(label,"TextTruncate",Enum.TextTruncate.None)
   local limit=label:FindFirstChildOfClass("UITextSizeConstraint")
   if limit then set(limit,"MinTextSize",1) end
  end
 end
 if treadmill then
  set(icon,"Image","rbxassetid://106106287008236");set(icon,"ScaleType",Enum.ScaleType.Fit)
 end
end
local function layout(model,gui,world)
 if not gui then return end
 set(gui,"Size",UDim2.fromScale(12,5))
 if world==1 then
  local text=gui:FindFirstChild("Multiplier")
  if text then set(text,"Position",UDim2.fromScale(.5,.70));set(text,"Size",UDim2.fromScale(.94,.43))end
  local requirement=gui:FindFirstChild("Rebirth")
  if requirement then
   set(requirement,"AutomaticSize",Enum.AutomaticSize.None);set(requirement,"Size",UDim2.fromScale(.94,.36));set(requirement,"Position",UDim2.fromScale(.5,.12))
   local amount=requirement:FindFirstChild("Amount")
   set(amount,"AutomaticSize",Enum.AutomaticSize.None);set(amount,"Size",UDim2.fromScale(.70,1))
  end
 else
  local label=gui:FindFirstChild("Multiplier")
  set(label,"Position",UDim2.fromScale(.04,.04));set(label,"Size",UDim2.fromScale(.92,.92))
  set(gui,"StudsOffsetWorldSpace",Vector3.new(0,7.35,0))
 end
end

local function refresh()
 title(workspace:FindFirstChild("Treadmills"),true)
 title(workspace:FindFirstChild("PerStepButtons"));title(workspace:FindFirstChild("Eggs"))
 local map=workspace:FindFirstChild("World2Map");local area=map and map:FindFirstChild("TrainingArea");title(area and area:FindFirstChild("TreadmillDisplays"),true)
 local dumb=area and area:FindFirstChild("DumbbellDisplays");title(dumb and dumb:FindFirstChild("PerStepButtons"))
 local facilities=area and area:FindFirstChild("FacilityDisplays");local eggs=facilities and facilities:FindFirstChild("EggDisplays");title(eggs and eggs:FindFirstChild("Visuals"))
 local count = tonumber(player:GetAttribute("RebirthCount")) or 0
 for _,model in ipairs(CollectionService:GetTagged(TREADMILL_TAG)) do
  local modelName=model.Name
  local display = model and model:FindFirstChild("TreadmillUIDisplay")
  local gui = display and display:FindFirstChild("TreadmillInfo")
  local required = gui and gui:FindFirstChild("Required")
  local entry,kind = Config.GetForModel(model)
  local world=Config.WorldForModel(model)
  layout(model,world==1 and model:FindFirstChild("BillboardGui")or model:FindFirstChild("StationBillboard"),world)
  if not entry then continue end
  if Config.WorldForModel(model)==2 then
   local label=model:FindFirstChild("StationBillboard") and model.StationBillboard:FindFirstChild("Multiplier")
   if label then label.Text=string.format("%02d",tonumber(kind:match("(%d+)$")) or 0).." | "..tostring(entry.Multiplier).."x Strength\n"..(entry.PurchaseEnabled==false and "Robux - Unavailable" or (entry.RequiredRebirth>0 and "Rebirth "..entry.RequiredRebirth.." Required" or "Available")) end
  end
  local strength = gui and gui:FindFirstChild("Strength")
  if strength then strength.Text = "×"..tostring(entry.Multiplier).." Strength" end
  if required and entry.RequiredRebirth then
   required.Text = tostring(entry.RequiredRebirth).." Rebirth Required"
   required.TextColor3 = count >= entry.RequiredRebirth and blue or red
  end
 end
end
local queued=false
local function schedule()
 if queued then return end;queued=true
 task.defer(function()queued=false;refresh()end)
end
player:GetPropertyChangedSignal("LocaleId"):Connect(schedule)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(schedule)
workspace.DescendantAdded:Connect(function(v)
 if (v:IsA("BillboardGui") and (v.Name=="BillboardGui"or v.Name=="StationBillboard"))
  or (v:IsA("TextLabel")and(v.Name=="Name"or v.Name=="Multiplier"or v.Name=="Amount"))then schedule()end
end)
player:GetAttributeChangedSignal("RebirthCount"):Connect(schedule)
CollectionService:GetInstanceAddedSignal(TREADMILL_TAG):Connect(function() task.defer(refresh) end)
CollectionService:GetInstanceRemovedSignal(TREADMILL_TAG):Connect(function() task.defer(refresh) end)
refresh()
