-- Presentation only. Existing callers own eligibility, visibility and seen state.
local RunService=game:GetService("RunService")
local M={}
M.Style=table.freeze({Image="rbxassetid://126155807251943",Scale=1.5,Interval=3,Duration=.4,Angle=10})
local names={NotificationBadge=true,ReadyBadge=true,AuraPurchaseBadge=true,SpeedPurchaseBadge=true,
 DumbbellGuideBadge=true,Dumbbell1GuideBadge=true,ItemGuideBadge=true,RarityGuideBadge=true}
local records={}
local mounts={}
local heartbeat
local function visible(badge)
 local x=badge
 while x do
  if x:IsA("GuiObject") and not x.Visible then return false end
  if x:IsA("LayerCollector") then return x.Enabled and x.Parent~=nil end
  x=x.Parent
 end
 return false
end
local function remove(badge)
 local record=records[badge];if not record then return end
 records[badge]=nil
 record.Image.Rotation=0
 if record.ParentConnection then record.ParentConnection:Disconnect() end
 for _,c in record.Connections do c:Disconnect() end
 if not next(records) and heartbeat then heartbeat:Disconnect();heartbeat=nil end
end
local function animate(dt)
 for badge,record in records do
  if visible(badge) then
   record.Elapsed+=dt
   local phase=record.Elapsed%M.Style.Interval
   record.Image.Rotation=record.Elapsed>=M.Style.Interval and phase<M.Style.Duration
    and math.sin(phase/M.Style.Duration*math.pi*2)*M.Style.Angle or 0
  else
   record.Elapsed=0;record.Image.Rotation=0
  end
 end
end
function M.Attach(badge)
 if records[badge] then return badge end
 local image=badge:FindFirstChild("NotificationImage")
 if not image then image=Instance.new("ImageLabel");image.Name="NotificationImage";image.Parent=badge end
 image.Image=M.Style.Image;image.BackgroundTransparency=1
 image.AnchorPoint=Vector2.new(.5,.5);image.Position=UDim2.fromScale(.5,.5)
 image.Size=UDim2.fromScale(M.Style.Scale,M.Style.Scale);image.ScaleType=Enum.ScaleType.Fit
 image.Active=false;image.Interactable=false;image.Selectable=false;image.Rotation=0
 image.ZIndex=badge.ZIndex+2;image.Visible=true
 local record={Image=image,Connections={},Watched={},Elapsed=0};records[badge]=record
 local function connect(signal,fn)table.insert(record.Connections,signal:Connect(fn))end
 local function mute(x,property)
  local function apply()if x[property]~=1 then x[property]=1 end end
  apply();connect(x:GetPropertyChangedSignal(property),apply)
 end
 local function oldPaint(x)
  if x==image or x:IsDescendantOf(image) or record.Watched[x] then return end
  record.Watched[x]=true
  if x:IsA("GuiObject") then mute(x,"BackgroundTransparency");x.Active=false;x.Selectable=false end
  if x:IsA("TextLabel") or x:IsA("TextButton") then mute(x,"TextTransparency");mute(x,"TextStrokeTransparency")
  elseif x:IsA("ImageLabel") or x:IsA("ImageButton") then mute(x,"ImageTransparency")
  elseif x:IsA("UIStroke") then mute(x,"Transparency") end
 end
 oldPaint(badge);for _,x in badge:GetDescendants() do oldPaint(x)end
 connect(badge.DescendantAdded,oldPaint)
 local function layer()
  local parent=badge.Parent
  if parent and parent:IsA("GuiObject") and badge.ZIndex<=parent.ZIndex then badge.ZIndex=parent.ZIndex+1 end
  image.ZIndex=badge.ZIndex+2
 end
 local function bindParent()
  if record.ParentConnection then record.ParentConnection:Disconnect();record.ParentConnection=nil end
  local parent=badge.Parent
  if parent and parent:IsA("GuiObject") then record.ParentConnection=parent:GetPropertyChangedSignal("ZIndex"):Connect(layer) end
  layer()
 end
 connect(badge:GetPropertyChangedSignal("ZIndex"),layer)
 connect(badge.AncestryChanged,bindParent)
 bindParent()
 connect(badge:GetPropertyChangedSignal("Visible"),function()if not badge.Visible then record.Elapsed=0;image.Rotation=0 end end)
 connect(badge.Destroying,function()remove(badge)end)
 if not heartbeat then heartbeat=RunService.Heartbeat:Connect(animate) end
 return badge
end
function M.Mount(root)
 if mounts[root] then return mounts[root] end
 local connections={}
 local function discover(x)
  if x:IsA("GuiObject") and names[x.Name] then M.Attach(x) end
 end
 for _,x in root:GetDescendants() do discover(x)end
 table.insert(connections,root.DescendantAdded:Connect(discover))
 table.insert(connections,root.DescendantRemoving:Connect(function(x)
  if records[x] then task.defer(function()if not x:IsDescendantOf(root) then remove(x)end end)end
 end))
 local function cleanup()
  if not mounts[root] then return end
  mounts[root]=nil
  for _,c in connections do c:Disconnect()end
  local list={};for badge in records do if badge:IsDescendantOf(root) then table.insert(list,badge)end end
  for _,badge in list do remove(badge)end
 end
 mounts[root]=cleanup
 table.insert(connections,root.Destroying:Connect(cleanup))
 return cleanup
end
function M.GetOrClone(template,parent,name)
 local badge=parent:FindFirstChild(name)
 if not badge then
  badge=template:Clone();badge.Name=name;badge.Visible=false;badge.Parent=parent
 end
 return M.Attach(badge)
end
function M.SetVisible(badge,value) M.Attach(badge);badge.Visible=value==true end
function M.SetText(badge,text)
 M.Attach(badge)
 local label=badge:FindFirstChild("TextLabel")
 if label then label.Text=text end
end
return table.freeze(M)
