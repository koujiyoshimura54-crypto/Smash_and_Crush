-- Shared authored/runtime layout. Only presentation changes; prices remain with purchase code.
local Config=require(script.Parent.Parent.Config.TreadmillConfig)
local Heading={}
local function set(object,key,value)
 if object and object[key]~=value then object[key]=value end
end
function Heading.Apply(gui,entry,world)
 local style=Config.StationHeading
 set(gui,"Size",UDim2.fromScale(style.Size.X,style.Size.Y))
 if world==2 then set(gui,"StudsOffsetWorldSpace",style.World2Offset) end
 local label=gui:FindFirstChild("Multiplier")
 if not label then return false end
 local requirement=gui:FindFirstChild("Rebirth")
 local needsRebirth=not entry.RequiresPremium and (entry.RequiredRebirth or 0)>0
 local hasGroup=requirement~=nil and (needsRebirth or entry.RequiresPremium==true)
 local row=gui:FindFirstChildOfClass("UIListLayout")
 if not row then row=Instance.new("UIListLayout");row.Parent=gui end
 set(row,"Wraps",false);set(row,"FillDirection",Enum.FillDirection.Vertical)
 set(row,"HorizontalAlignment",Enum.HorizontalAlignment.Center)
 set(row,"VerticalAlignment",Enum.VerticalAlignment.Center)
 set(row,"SortOrder",Enum.SortOrder.LayoutOrder)
 set(row,"Padding",UDim.new(style.GroupGap,0))
 set(label,"LayoutOrder",2);set(label,"AnchorPoint",Vector2.zero)
 set(label,"AutomaticSize",Enum.AutomaticSize.None)
 set(label,"Size",UDim2.fromScale(style.MultiplierWidth,style.RowHeight))
 set(label,"TextWrapped",true);set(label,"TextScaled",true);set(label,"AutoLocalize",false)
 label.Text="×"..tostring(entry.Multiplier).." Strength"
 if requirement then
  local groupWidth=entry.RequiresPremium and style.PremiumRequirementWidth or style.RequirementWidth
  local iconWidth=style.Size.Y*style.RowHeight/(style.Size.X*groupWidth)
  set(requirement,"Visible",hasGroup);set(requirement,"LayoutOrder",1)
  set(requirement,"AnchorPoint",Vector2.zero);set(requirement,"AutomaticSize",Enum.AutomaticSize.None)
  set(requirement,"Size",UDim2.fromScale(groupWidth,style.RowHeight))
  local icon=requirement:FindFirstChild("Icon")
  local amount=requirement:FindFirstChild("Amount")
  set(icon,"LayoutOrder",1);set(icon,"AnchorPoint",Vector2.zero)
  set(icon,"Size",UDim2.fromScale(iconWidth,1));set(icon,"ScaleType",Enum.ScaleType.Fit)
  set(amount,"LayoutOrder",2);set(amount,"AnchorPoint",Vector2.zero)
  set(amount,"AutomaticSize",Enum.AutomaticSize.None)
  set(amount,"Size",UDim2.fromScale(1-iconWidth-style.IconGap,1))
  set(amount,"TextXAlignment",Enum.TextXAlignment.Left)
  set(amount,"TextWrapped",true);set(amount,"TextScaled",true);set(amount,"AutoLocalize",false)
  local inner=requirement:FindFirstChildOfClass("UIListLayout")
  if not inner then inner=Instance.new("UIListLayout");inner.Parent=requirement end
  set(inner,"Wraps",false);set(inner,"Padding",UDim.new(style.IconGap,0))
  set(inner,"FillDirection",Enum.FillDirection.Horizontal)
  set(inner,"HorizontalAlignment",Enum.HorizontalAlignment.Center)
  set(inner,"VerticalAlignment",Enum.VerticalAlignment.Center)
  set(inner,"SortOrder",Enum.SortOrder.LayoutOrder)
  if needsRebirth and amount then amount.Text="×"..tostring(entry.RequiredRebirth) end
 end
 return hasGroup
end
return Heading
