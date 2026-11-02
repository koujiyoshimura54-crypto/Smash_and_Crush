-- Edit-only v1 -> v2 migration. Never run at Play startup. A second run preserves edits.
assert(not game:GetService("RunService"):IsRunning())
local RS=game.ReplicatedStorage
local config=require(RS.Modules.Config)
local gui=game.StarterGui:FindFirstChild("OreMergeTutorialGui")
if gui and (gui:GetAttribute("PresentationVersion") or 0)>=2 then return "v2 template preserved" end
local changes={}
local function set(x,key,old,new)
 if x[key]==old then x[key]=new;table.insert(changes,x:GetFullName().."."..key) end
end
local function attribute(x,key,value,old)
 if x:GetAttribute(key)==nil or old~=nil and x:GetAttribute(key)==old then x:SetAttribute(key,value) end
end
local function frame(name,parent,z)
 local x=Instance.new("Frame");x.Name=name;x.BackgroundTransparency=1;x.BorderSizePixel=0
 x.Active=false;x.Selectable=false;x.Interactable=false;x.ClipsDescendants=false;x.ZIndex=z;x.Parent=parent;return x
end
if not gui then
 gui=Instance.new("ScreenGui");gui.Name="OreMergeTutorialGui";gui.ResetOnSpawn=false
 gui.IgnoreGuiInset=true;gui.DisplayOrder=45;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local c=frame("Canvas",gui,1);c.Size=UDim2.fromScale(1,1)
 local h=RS.Assets.Tutorial.TutorialHighlight:Clone();h.Name="Highlight";h.ZIndex=config.Tutorial.zIndex;h.Parent=c
 for _,x in h:GetChildren() do
  if x:IsA("UIStroke") then x.Name=x.Color.R+x.Color.G+x.Color.B>1 and "Outline" or "Shadow"
  elseif x:IsA("UICorner") then x.Name="Corner" end
 end
 gui.Parent=game.StarterGui
end
local canvas=gui.Canvas;local focus=canvas.Highlight
canvas.Active=false;canvas.Interactable=false;canvas.Selectable=false
set(gui,"IgnoreGuiInset",false,game.StarterGui.ScreenGui.IgnoreGuiInset)
local donor=RS.Assets.Tutorial.TutorialHighlight
local white,black
for _,x in donor:GetChildren() do if x:IsA("UIStroke") then if x.Color.R+x.Color.G+x.Color.B>1 then white=x else black=x end end end
assert(white and black,"Purchased highlight strokes missing")
set(focus,"AnchorPoint",Vector2.zero,donor.AnchorPoint)
set(focus,"ZIndex",2,config.Tutorial.zIndex)
set(focus.Outline,"Thickness",3,white.Thickness)
set(focus.Outline,"StrokeSizingMode",Enum.StrokeSizingMode.FixedSize,white.StrokeSizingMode)
set(focus.Shadow,"Thickness",6,black.Thickness)
set(focus.Shadow,"StrokeSizingMode",Enum.StrokeSizingMode.FixedSize,black.StrokeSizingMode)
set(focus.Corner,"CornerRadius",UDim.new(0,8),donor:FindFirstChildOfClass("UICorner").CornerRadius)
attribute(focus,"PaddingX",0,6);attribute(focus,"PaddingY",0,6)
attribute(focus,"GuiGrow",config.Tutorial.guiGrow);attribute(focus,"MoveSeconds",config.Tutorial.moveSeconds)
-- Existing color, translucency, stroke layering, clipping and extra children survive.
focus.Active=false;focus.Selectable=false;focus.Interactable=false;focus.Visible=false
local note=frame("Notification",canvas,config.Tutorial.zIndex+10);note.Size=UDim2.fromScale(1,1);note.Visible=false
note:SetAttribute("ReferenceHeight",720)
local old=canvas:FindFirstChild("Message")
for key,value in {HeaderWidthScale=.7,HeaderCenterX=.5} do note:SetAttribute(key,old and old:GetAttribute(key) or value) end
local shade=frame("Shade",note,1);shade.BackgroundTransparency=0;shade.BackgroundColor3=Color3.new()
shade.AnchorPoint=Vector2.new(.5,.5);shade.Position=UDim2.fromScale(.5,config.Notify.middle);shade.Size=UDim2.new()
local fade=Instance.new("UIGradient");fade.Rotation=config.Notify.shadeRotation;fade.Parent=shade
local stack=frame("Stack",note,2);stack.AnchorPoint=Vector2.new(.5,.5);stack.Position=shade.Position;stack.Size=UDim2.fromScale(1,1)
local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Vertical
layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center
layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Padding=UDim.new(config.Notify.linePadding,0);layout.Parent=stack
local line=frame("Line",stack,1);line.AnchorPoint=Vector2.new(.5,.5);line.Position=UDim2.fromScale(.5,.5)
line.Size=UDim2.fromScale(config.Notify.lineWidth,config.Notify.lineHeight);line.Visible=false
local label=old or Instance.new("TextLabel");label.Name="Message"
if old then
 set(label,"FontFace",Font.fromEnum(Enum.Font.Legacy),Font.fromEnum(Enum.Font.GothamBlack))
 set(label,"BackgroundTransparency",0,1)
 local corner=label:FindFirstChildOfClass("UICorner")
 if corner and corner.CornerRadius==UDim.new(0,8) then corner:Destroy() end
 local limit=label:FindFirstChildOfClass("UITextSizeConstraint")
 if limit and limit.MinTextSize==12 and limit.MaxTextSize==26 then limit:Destroy() end
else
 label.BackgroundTransparency=1;label.FontFace=Font.fromEnum(Enum.Font.GothamBlack);label.TextColor3=Color3.new(1,1,1)
end
label.AnchorPoint=Vector2.new(.5,.5);label.Position=UDim2.fromScale(.5,.5)
label.Size=UDim2.fromScale(config.Notify.textScale,config.Notify.textScale)
-- NotifyClient creates a new TextLabel with AutomaticSize=None, then enables TextScaled.
-- The old purchase-button clone inherited AutomaticSize.X; retain no content-driven width.
set(label,"AutomaticSize",Enum.AutomaticSize.X,Enum.AutomaticSize.None)
label.Text="";label.AutoLocalize=false;label.TextWrapped=true;label.TextScaled=true
label.Active=false;label.Interactable=false;label.Selectable=false;label.Visible=true;label.Parent=line
local stroke=label:FindFirstChildOfClass("UIStroke")
if stroke then
 if math.abs(stroke.Thickness-.05)<1e-6 then stroke.Thickness=720*config.Notify.strokeShare*config.Notify.textScale end
 set(stroke,"StrokeSizingMode",Enum.StrokeSizingMode.ScaledSize,Enum.StrokeSizingMode.FixedSize)
else stroke=Instance.new("UIStroke");stroke.Thickness=720*config.Notify.strokeShare*config.Notify.textScale;stroke.Parent=label end
stroke.Name="UIStroke"
local scale=Instance.new("UIScale");scale.Name="UIScale";scale.Parent=label
local gradient=label:FindFirstChildOfClass("UIGradient")
if not gradient then gradient=Instance.new("UIGradient");gradient.Rotation=config.Inventory.gradientRotation
 gradient.Color=ColorSequence.new(config.Tutorial.from,config.Tutorial.to);gradient.Parent=label end
local text=gui:FindFirstChild("Messages") or Instance.new("Folder");text.Name="Messages";text.Parent=gui
for name,value in {GoToMerge="Go to Merge to create a dumbbell!",ChooseOre="Select Ore.",
 AddOres="Choose 2 ores.",AddAnother="Tap this ore again.",
 ScrollOres="Scroll to another ore.",Merge="Press Merge.",Saving="Creating your dumbbell…"} do
 local x=text:FindFirstChild(name)
 if not x then x=Instance.new("StringValue");x.Name=name;x.Value=value;x.Parent=text
 elseif name=="AddOres" and x.Value=="Tap ore cards to add 2–5. Tap again for another." then x.Value=value
 elseif name=="Merge" and x.Value=="Press Merge to create a dumbbell!" then x.Value=value end
end
gui:SetAttribute("PresentationVersion",2)
return changes
