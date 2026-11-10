-- World2 reuses the authored World1 stand GUI, without copying its item data.
local M={}
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
 local template=game.ReplicatedStorage:FindFirstChild("DumbbellStandBillboardTemplate")
 if not template then return false end
 copyStyle(board,template)
 -- This World2-only extra row changed the purchased row order and overflowed it.
 local number=board:FindFirstChild("StationNumber")
 if number then number:Destroy() end
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
