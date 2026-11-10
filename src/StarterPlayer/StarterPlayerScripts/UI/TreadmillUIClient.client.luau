local CollectionService=game:GetService("CollectionService")
local TREADMILL_TAG="TrainingTreadmill"
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Config = require(game:GetService("ReplicatedStorage").Config:WaitForChild("TreadmillConfig"))
local Heading=require(game.ReplicatedStorage.Modules.TreadmillStationHeading)
local MarketplacePrice=require(game.ReplicatedStorage.Modules.MarketplacePrice)
local PurchaseHUD=require(game.ReplicatedStorage.Modules.HUDLayout)
local premiumPrice
local red = Color3.fromRGB(255, 60, 60)
local blue = Color3.fromRGB(55, 145, 255)

-- Keep purchased artwork/fonts; reserve explicit text width instead of
-- AutomaticSize.X + TextScaled competing inside a clipped horizontal row.
local function set(object,key,value) if object and object[key]~=value then object[key]=value end end
local TextService=game:GetService("TextService")
local schedule
local titleWatches=setmetatable({}, {__mode="k"})
local function treadmillTitle(gui)
 local label=gui:FindFirstChild("Name")
 local icon=gui:FindFirstChild("Icon")
 if not label then return end
 -- Same world-space height/icon/gap as the normal Egg and Dumbbell headings.
 -- Extend the row for the actual localized string instead of shrinking its font.
 local height,iconWidth,gap,margin=7.5,6.8,1.2,1.6
 local text=label.ContentText~="" and label.ContentText or label.Text
 local bounds=TextService:GetTextSize(text,100,label.Font,Vector2.new(100000,1000))
 local textWidth=math.max(30.4,bounds.X/math.max(bounds.Y,1)*(height*.9)*1.12)
 local width=iconWidth+gap+textWidth+margin
 set(gui,"Size",UDim2.fromScale(width,height))
 local row=gui:FindFirstChildOfClass("UIListLayout")
 if row then
  set(row,"Padding",UDim.new(gap/width,0))
  set(row,"HorizontalAlignment",Enum.HorizontalAlignment.Center)
  set(row,"VerticalAlignment",Enum.VerticalAlignment.Center)
 end
 set(label,"AutomaticSize",Enum.AutomaticSize.None)
 set(label,"Size",UDim2.fromScale(textWidth/width,.9))
 -- Roblox disables TextScaled when TextWrapped is turned off. The measured
 -- one-line width prevents wrapping while leaving distance scaling enabled.
 set(label,"TextWrapped",true);set(label,"TextScaled",true);set(label,"TextTruncate",Enum.TextTruncate.None)
 set(icon,"Size",UDim2.fromScale(iconWidth/width,.9))
 set(icon,"Image","rbxassetid://106106287008236");set(icon,"ScaleType",Enum.ScaleType.Fit)
 if not titleWatches[label] then
  local connections={label:GetPropertyChangedSignal("ContentText"):Connect(function()schedule()end),
   label:GetPropertyChangedSignal("FontFace"):Connect(function()schedule()end)}
  titleWatches[label]=connections
  label.Destroying:Once(function()
   for _,connection in connections do connection:Disconnect() end
   titleWatches[label]=nil
  end)
 end
end
local function title(folder,treadmill)
 local part=folder and folder:FindFirstChild("Billboard")
 local gui=part and part:FindFirstChildWhichIsA("BillboardGui")
 if not gui then return end
 set(gui,"Adornee",part)
 if treadmill then
  set(gui,"StudsOffsetWorldSpace",Vector3.new(0,4,0));treadmillTitle(gui)
  return
 end
 local row=gui:FindFirstChildOfClass("UIListLayout")
 if row then set(row,"Padding",UDim.new(.03,0));set(row,"HorizontalAlignment",Enum.HorizontalAlignment.Center);set(row,"VerticalAlignment",Enum.VerticalAlignment.Center)end
 local icon=gui:FindFirstChild("Icon");set(icon,"Size",UDim2.fromScale(.17,.9))
 local label=gui:FindFirstChild("Name")
 if label then set(label,"AutomaticSize",Enum.AutomaticSize.None);set(label,"Size",UDim2.fromScale(.76,.9));set(label,"TextScaled",true);set(label,"TextWrapped",true)end
end
local function layout(model,gui,world,entry)
 if not gui or not entry then return end
 local style=Config.StationHeading
 set(gui,"Size",UDim2.fromScale(style.Size.X,style.Size.Y))
 if world==2 then set(gui,"StudsOffsetWorldSpace",style.World2Offset) end
 local label=gui:FindFirstChild("Multiplier")
 if not label then return end
 local needsRebirth=not entry.RequiresPremium and (entry.RequiredRebirth or 0)>0
 local requirement=gui:FindFirstChild("Rebirth")
 if world==2 and (needsRebirth or entry.RequiresPremium) and not requirement then
  local folder=workspace:FindFirstChild("Treadmills")
  local donor=folder and folder:FindFirstChild(entry.RequiresPremium and "Diamond01" or "Iron01")
  local board=donor and donor:FindFirstChild("BillboardGui")
  local source=board and board:FindFirstChild("Rebirth")
  if source then
   requirement=source:Clone();requirement.Name="Rebirth";requirement.Parent=gui
   if board:FindFirstChild("Multiplier") then label.FontFace=board.Multiplier.FontFace end
  end
 end
 Heading.Apply(gui,entry,world)
 if requirement then
  local amount=requirement:FindFirstChild("Amount")
  if entry.RequiresPremium then
   PurchaseHUD.ApplyPurchaseTextFont(amount)
   if world==2 and amount then
    amount.Text=entry.PurchaseEnabled==false and "Unavailable"
     or player:GetAttribute("HasWorld2PremiumTreadmill")==true and "Owned" or MarketplacePrice.Format(premiumPrice,"")
   end
  end
 elseif world==2 and entry.RequiresPremium then
  -- Streaming fallback until the existing donor arrives; retain the price.
  label.Text..="\n"..MarketplacePrice.Format(premiumPrice," Robux")
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
  layout(model,world==1 and model:FindFirstChild("BillboardGui")or model:FindFirstChild("StationBillboard"),world,entry)
  if not entry then continue end
  local strength = gui and gui:FindFirstChild("Strength")
  if strength then strength.Text = "×"..tostring(entry.Multiplier).." Strength" end
  if required and entry.RequiredRebirth then
   required.Text = tostring(entry.RequiredRebirth).." Rebirth Required"
   required.TextColor3 = count >= entry.RequiredRebirth and blue or red
  end
 end
end
local queued=false
schedule=function()
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
player:GetAttributeChangedSignal("HasWorld2PremiumTreadmill"):Connect(schedule)
task.spawn(function()
 local price=MarketplacePrice.Get(Config.GetPremiumTreadmillPassId(2),Enum.InfoType.GamePass,nil)
 if typeof(price)=="number" and price>0 and price<math.huge then premiumPrice=price end
 schedule()
end)
CollectionService:GetInstanceAddedSignal(TREADMILL_TAG):Connect(function() task.defer(refresh) end)
CollectionService:GetInstanceRemovedSignal(TREADMILL_TAG):Connect(function() task.defer(refresh) end)
refresh()
