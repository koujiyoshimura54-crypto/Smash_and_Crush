-- World2 reuses the authored World1 stand GUI, without copying its item data.
local M={}
local RS=game:GetService("ReplicatedStorage")
local Style=require(RS.Config.DumbbellLabelStyle)
local NumberFormat=require(RS.Modules.NumberFormat)
function M.ApplyValue(board,value)
 if not board then return end
 if board:GetAttribute("DumbbellExhibitLabel")~=true then
  local size=Style.TemplateSize;local scale=Style.SizeMultiplier
  board.Size=UDim2.new(size.X.Scale*scale,size.X.Offset*scale,size.Y.Scale*scale,size.Y.Offset*scale)
 end
 local amount=board:FindFirstChild("Amount")
 if amount and amount:IsA("GuiObject") then amount.Visible=false end
 local icon=board:FindFirstChild("ItemIcon")
 if icon and icon:IsA("GuiObject") then icon.Visible=false end
 for _,name in {"Status","StatusShadow"} do
  local status=board:FindFirstChild(name)
  if status and status:IsA("TextLabel") then status.Text="";status.Visible=false end
 end
 for _,name in {"Price","PriceShadow"} do
  local label=board:FindFirstChild(name)
  if label and label:IsA("TextLabel") then
   local scale=Style.SizeMultiplier
   local ui=label:FindFirstChild("NumericScale") or Instance.new("UIScale")
   ui.Name="NumericScale";ui.Scale=scale;ui.Parent=label
   -- Keep the original logical text bounds, then scale their actual rendering.
   -- UITextSizeConstraint caps MaxTextSize at 100, so doubling that is insufficient.
   local height=board:GetAttribute("DumbbellExhibitLabel")==true
    and Style.ExhibitValueHeight/board.Size.Y.Scale or Style.TemplateValueHeight/scale
   label.Size=UDim2.fromScale(Style.ValueWidth/scale,height)
   if value~=nil then label.Text="+"..NumberFormat.Format(value) end
   label.AutoLocalize=false;label.Font=Style.Font;label.TextColor3=Style.Color
   label.TextWrapped=false;label.TextScaled=true;label.TextTruncate=Enum.TextTruncate.None
   label.TextStrokeColor3=Style.OutlineColor;label.TextStrokeTransparency=1
   local stroke=label:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
   stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;stroke.Color=Style.OutlineColor
   stroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
   stroke.Thickness=Style.OutlineThickness;stroke.Transparency=0;stroke.Parent=label
   local limit=label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
   limit.MinTextSize=Style.MinTextSize;limit.MaxTextSize=Style.MaxTextSize;limit.Parent=label
  end
 end
end
local fields={
 BillboardGui={"Size","ClipsDescendants","AlwaysOnTop","LightInfluence","Brightness","MaxDistance","SizeOffset","ExtentsOffset","ExtentsOffsetWorldSpace","StudsOffsetWorldSpace","ZIndexBehavior"},
 GuiObject={"Size","Position","AnchorPoint","AutomaticSize","SizeConstraint","LayoutOrder","ZIndex","BackgroundColor3","BackgroundTransparency","BorderSizePixel","BorderColor3","ClipsDescendants","Visible","Rotation"},
 TextLabel={"FontFace","TextSize","TextScaled","TextWrapped","TextXAlignment","TextYAlignment","TextColor3","TextTransparency","TextStrokeColor3","TextStrokeTransparency","RichText","TextTruncate","LineHeight"},
 ImageLabel={"ScaleType","ImageColor3","ImageTransparency","ImageRectOffset","ImageRectSize","SliceCenter","SliceScale","TileSize"},
 UIListLayout={"FillDirection","HorizontalAlignment","VerticalAlignment","SortOrder","Padding","HorizontalFlex","VerticalFlex","ItemLineAlignment","Wraps"},
 UIAspectRatioConstraint={"AspectRatio","AspectType","DominantAxis"},
 UIStroke={"Color","Thickness","Transparency","ApplyStrokeMode","LineJoinMode","Enabled","StrokeSizingMode"},
 UICorner={"CornerRadius"},
 UIGradient={"Color","Transparency","Rotation","Offset","Enabled"},
 UITextSizeConstraint={"MinTextSize","MaxTextSize"},
 UIPadding={"PaddingTop","PaddingBottom","PaddingLeft","PaddingRight"},
}
local function copyStyle(target,source)
 for class,properties in pairs(fields) do
  if source:IsA(class) then
   for _,property in ipairs(properties) do
    if target[property]~=source[property] then target[property]=source[property] end
   end
  end
 end
 for _,child in ipairs(source:GetChildren()) do
  if child:IsA("GuiObject") or child:IsA("UIComponent") then
   local match=target:FindFirstChild(child.Name)
   if not match then match=child:Clone();match.Parent=target end
   assert(match.ClassName==child.ClassName,"Unexpected stand GUI class: "..match:GetFullName())
   copyStyle(match,child)
  end
 end
end
function M.Apply(board)
 -- Registered 3D exhibits already own their compact above-model label layout.
 -- Reapplying the legacy template would restore its hidden icon gap and offset.
 if board:GetAttribute("DumbbellExhibitLabel")==true then M.ApplyValue(board);return true end
 local template=game.ReplicatedStorage:FindFirstChild("DumbbellStandBillboardTemplate")
 if not template then return false end
 copyStyle(board,template)
 -- This World2-only extra row changed the purchased row order and overflowed it.
 local number=board:FindFirstChild("StationNumber")
 if number then number:Destroy() end
 M.ApplyValue(board)
 return true
end
function M.Ensure(model)
 local board=model:FindFirstChild("BillboardGui")
 if not board then
  local template=game.ReplicatedStorage:FindFirstChild("DumbbellStandBillboardTemplate")
  if not template then return nil end
  board=template:Clone();board.Name="BillboardGui";board.Adornee=model:FindFirstChild("Press");board.Parent=model
 end
 M.Apply(board)
 return board
end
return M
