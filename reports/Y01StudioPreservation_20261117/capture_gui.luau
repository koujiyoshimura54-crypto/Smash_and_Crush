-- Read-only typed snapshot. Call returned function(offset, limit); never restores properties.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857 and not game:GetService("RunService"):IsRunning(),"Wrong target/mode")
local function address(o)
 local a={} while o and o~=game do
  local n=1 if o.Parent then for _,s in ipairs(o.Parent:GetChildren()) do if s==o then break end if s.Name==o.Name and s.ClassName==o.ClassName then n+=1 end end end
  table.insert(a,1,{Name=o.Name,ClassName=o.ClassName,Ordinal=n}) o=o.Parent
 end return a
end
local function encode(v)
 local t=typeof(v)
 if t=="nil" then return {Type="nil"} end
 if t=="string" or t=="boolean" then return v end
 if t=="number" then if v~=v then return {Type="number",Value="NaN"} elseif v==math.huge then return {Type="number",Value="+Infinity"} elseif v==-math.huge then return {Type="number",Value="-Infinity"} end return v end
 if t=="Instance" then return {Type=t,FullPath=v:GetFullName(),ClassName=v.ClassName,Address=address(v)} end
 if t=="EnumItem" then return {Type=t,Enum=tostring(v.EnumType),Name=v.Name,Value=v.Value} end
 if t=="Color3" then return {Type=t,Value={v.R,v.G,v.B}} end
 if t=="Vector2" then return {Type=t,Value={v.X,v.Y}} end
 if t=="Vector3" then return {Type=t,Value={v.X,v.Y,v.Z}} end
 if t=="UDim" then return {Type=t,Scale=v.Scale,Offset=v.Offset} end
 if t=="UDim2" then return {Type=t,X={v.X.Scale,v.X.Offset},Y={v.Y.Scale,v.Y.Offset}} end
 if t=="CFrame" then return {Type=t,Components={v:GetComponents()}} end
 if t=="Rect" then return {Type=t,Min=encode(v.Min),Max=encode(v.Max)} end
 if t=="Font" then return {Type=t,Family=v.Family,Weight=encode(v.Weight),Style=encode(v.Style)} end
 if t=="NumberSequence" or t=="ColorSequence" then local k={} for _,p in ipairs(v.Keypoints) do table.insert(k,{Time=p.Time,Value=encode(p.Value),Envelope=t=="NumberSequence" and p.Envelope or nil}) end return {Type=t,Keypoints=k} end
 if t=="NumberRange" then return {Type=t,Min=v.Min,Max=v.Max} end
 error("Unsupported snapshot type: "..t)
end
local roots,seen,objects={},{},{}
local function add(o)
 if not o then return end table.insert(roots,o)
 local all={o} for _,d in ipairs(o:GetDescendants()) do table.insert(all,d) end
 for _,d in ipairs(all) do if not seen[d] then seen[d]=true table.insert(objects,d) end end
end
local sg=game:GetService("StarterGui") local strength=sg:FindFirstChild("StrengthGui")
if strength then
 add(strength:FindFirstChild("DailyRewardsPanel"))
 local menu=strength:FindFirstChild("LeftMenu")
 if menu then add(menu:FindFirstChild("TimeRewardsButton")) add(menu:FindFirstChild("DailyRewardsButton")) end
end
add(sg:FindFirstChild("World1DoubleWinGui"))
for _,o in ipairs(workspace:GetDescendants()) do
 if o:IsA("LayerCollector") then local p=o:GetFullName()
  if p:find("PerStepButtons",1,true) or o.Name:find("Trophy") or
    (p:find("BattleCorridor",1,true) and (o.Name=="SurfaceGui" or o.Name=="PersonalGauge" or o.Name=="StageSurface")) then add(o) end
 end
end
local ui=game:GetService("ReplicatedStorage"):FindFirstChild("UI") local templates=ui and ui:FindFirstChild("Templates")
if templates then for _,o in ipairs(templates:GetChildren()) do if o.Name:find("Trophy") or o.Name:find("Dumbbell") then add(o) end end end
-- Preserve ancestor visibility/scaling, without traversing unrelated siblings.
for _,root in ipairs(roots) do local o=root.Parent while o and o~=game do if not seen[o] then seen[o]=true table.insert(objects,o) end o=o.Parent end end
table.sort(objects,function(a,b) local ap,bp=a:GetFullName(),b:GetFullName() if ap~=bp then return ap<bp end return a.ClassName<b.ClassName end)
local function record(o)
 local r={FullPath=o:GetFullName(),ClassName=o.ClassName,Address=address(o),Properties={},Attributes={},Derived={},Unavailable={}}
 local function props(names,derived)
  for n in names:gmatch("%S+") do local ok,v=pcall(function() return o[n] end)
   if ok then (derived and r.Derived or r.Properties)[n]=encode(v) else table.insert(r.Unavailable,n) end
  end
 end
 props("Archivable")
 for k,v in pairs(o:GetAttributes()) do r.Attributes[k]=encode(v) end
 if o:IsA("GuiObject") then
  props("Visible Position Size AnchorPoint Rotation BackgroundColor3 BackgroundTransparency BorderColor3 BorderSizePixel BorderMode ClipsDescendants LayoutOrder ZIndex AutomaticSize Active Selectable SelectionOrder")
  props("AbsolutePosition AbsoluteSize AbsoluteRotation",true)
 end
 if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then props("Text TextColor3 TextTransparency TextStrokeColor3 TextStrokeTransparency Font FontFace TextSize TextScaled TextWrapped TextXAlignment TextYAlignment RichText LineHeight MaxVisibleGraphemes TextTruncate AutoLocalize") end
 if o:IsA("ImageLabel") or o:IsA("ImageButton") then props("Image ImageColor3 ImageTransparency ImageRectOffset ImageRectSize ScaleType SliceCenter SliceScale TileSize ResampleMode") end
 if o:IsA("GuiButton") then props("AutoButtonColor Modal") end
 if o:IsA("LayerCollector") then props("Enabled ZIndexBehavior") end
 if o:IsA("ScreenGui") then props("DisplayOrder IgnoreGuiInset ResetOnSpawn ScreenInsets ClipToDeviceSafeArea SafeAreaCompatibility") end
 if o:IsA("BillboardGui") then props("Adornee Size SizeOffset StudsOffset StudsOffsetWorldSpace ExtentsOffset ExtentsOffsetWorldSpace AlwaysOnTop MaxDistance LightInfluence Brightness Active ClipsDescendants") props("AbsolutePosition AbsoluteSize",true) end
 if o:IsA("SurfaceGui") then props("Adornee Face CanvasSize SizingMode PixelsPerStud AlwaysOnTop LightInfluence Brightness MaxDistance Active ClipsDescendants ZOffset") end
 if o:IsA("UIScale") then props("Scale") end
 if o:IsA("UIStroke") then props("Color Thickness Transparency ApplyStrokeMode LineJoinMode Enabled") end
 if o:IsA("UIGradient") then props("Color Transparency Rotation Offset Enabled") end
 if o:IsA("UICorner") then props("CornerRadius") end
 if o:IsA("UIPadding") then props("PaddingTop PaddingBottom PaddingLeft PaddingRight") end
 if o:IsA("UIListLayout") or o:IsA("UIGridLayout") then props("FillDirection HorizontalAlignment VerticalAlignment SortOrder") end
 if o:IsA("UIListLayout") then props("Padding Wraps") end
 if o:IsA("UIGridLayout") then props("CellSize CellPadding FillDirectionMaxCells StartCorner") end
 if o:IsA("UIAspectRatioConstraint") then props("AspectRatio AspectType DominantAxis") end
 if o:IsA("UISizeConstraint") then props("MinSize MaxSize") end
 if o:IsA("UITextSizeConstraint") then props("MinTextSize MaxTextSize") end
 if o:IsA("ScrollingFrame") then props("CanvasSize CanvasPosition AutomaticCanvasSize ScrollingDirection ScrollBarThickness ScrollBarImageColor3 ScrollBarImageTransparency ScrollingEnabled ElasticBehavior") end
 return r
end
return function(offset,limit)
 local rows={} local bytes=0 for i=offset+1,math.min(offset+limit,#objects) do local row=record(objects[i]) local size=#game:GetService('HttpService'):JSONEncode(row) if bytes+size>65000 and #rows>0 then break end table.insert(rows,row) bytes+=size end
 return {Schema="RobloxTypedGuiSnapshot/1",CapturedAtUTC=DateTime.now():ToIsoDate(),PlaceId=game.PlaceId,UniverseId=game.GameId,Total=#objects,Offset=offset,Records=rows,RootCount=#roots}
end
