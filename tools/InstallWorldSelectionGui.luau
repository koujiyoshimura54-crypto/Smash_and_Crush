local function install()
-- Edit-time installation only. Existing appearance settings survive a re-run.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local SG=game.StarterGui
local gui=SG:WaitForChild("WorldTravelGui")
local Font=require(game.ReplicatedStorage.Config.StrengthHUDStyle).Font
local function make(class,name,parent,props)
 local x=Instance.new(class);x.Name=name
 for k,v in props or {} do x[k]=v end;x.Parent=parent;return x
end
local function corner(parent,r)
 local x=make("UICorner","Corner",parent,{CornerRadius=UDim.new(0,r)});x:SetAttribute("ReferenceRadius",r)
end
local function border(parent,n,mode)
 local x=make("UIStroke",mode=="Text" and "TextOutline" or "Outline",parent,
 {Color=Color3.new(0,0,0),Thickness=n,ApplyStrokeMode=mode=="Text" and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border})
 x:SetAttribute("ReferenceThickness",n);x:SetAttribute("MinimumThickness",mode=="Text" and 2.5 or 3)
end
local function label(parent,name,text)
 local x=make("TextLabel",name,parent,{Text=text,Font=Font,TextSize=80,TextColor3=Color3.new(1,1,1),
 BackgroundTransparency=1,TextStrokeTransparency=1,TextWrapped=false,Active=false,ZIndex=parent.ZIndex+1})
 border(x,7,"Text");return x
end
local function lockIcon(button)
 local lock=make("Frame","Lock",button,{BackgroundTransparency=1,ZIndex=8})
 local shackle=make("Frame","Shackle",lock,{Position=UDim2.fromScale(.23,0),Size=UDim2.fromScale(.54,.67),BackgroundColor3=Color3.new(1,1,1),ZIndex=8})
 corner(shackle,20);border(shackle,4)
 local hole=make("Frame","Opening",shackle,{Position=UDim2.fromScale(.22,.19),Size=UDim2.fromScale(.56,.72),BackgroundColor3=Color3.fromRGB(110,110,110),BorderSizePixel=0,ZIndex=9});corner(hole,12)
 local body=make("Frame","Body",lock,{Position=UDim2.fromScale(.06,.39),Size=UDim2.fromScale(.88,.6),BackgroundColor3=Color3.new(1,1,1),ZIndex=10})
 corner(body,9);border(body,4)
 local dot=make("Frame","Key",body,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.42),Size=UDim2.fromScale(.23,.30),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=11});corner(dot,8)
 make("Frame","Stem",body,{Position=UDim2.fromScale(.43,.47),Size=UDim2.fromScale(.14,.28),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=11})
 return lock
end

if not gui:GetAttribute("WorldSelectionVersion") then
 gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=10010
 local modal=gui:WaitForChild("Modal")
 modal.Visible=false;modal.BackgroundTransparency=1;modal.Active=true
 -- Replace only the retired YES/NO modal; this ScreenGui is already observed by guides.
 modal.Card:Destroy()
 local panel=make("Frame","Card",modal,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.495,.51),
 Size=UDim2.fromOffset(1312,844),BackgroundColor3=Color3.fromRGB(28,32,37),BackgroundTransparency=.12,
 Active=true,ZIndex=2})
 for k,v in {ReferenceWidth=1312,ReferenceHeight=844,SidePadding=36,HeaderHeight=104,CardHeight=234,CardGap=15,TitleTextSize=100,WorldTextSize=106,ButtonTextSize=62,CloseTextSize=85} do panel:SetAttribute(k,v) end
 corner(panel,30);border(panel,7)
 local title=label(panel,"Title","Worlds");title.TextSize=90
 local close=make("TextButton","Close",panel,{Text="",Font=Font,TextColor3=Color3.new(1,1,1),
 TextSize=85,AnchorPoint=Vector2.new(1,0),BackgroundColor3=Color3.new(1,1,1),AutoButtonColor=false,ZIndex=8})
 border(close,6);corner(close,11)
 local closeText=label(close,"Label","X");closeText.Size=UDim2.fromScale(1,1);closeText.ZIndex=9
 make("UIGradient","UIGradient",close,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(255,12,15),Color3.fromRGB(205,0,0))})
 local list=make("ScrollingFrame","WorldList",panel,{BackgroundTransparency=1,BorderSizePixel=0,Active=true,
 ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.new(),ZIndex=3})
 make("UIListLayout","UIListLayout",list,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,15)})
 local styles=make("Folder","Appearance",gui)
 for name,colors in {Current={Color3.fromRGB(0,191,255),Color3.fromRGB(0,66,255)},
  Teleport={Color3.fromRGB(231,255,0),Color3.fromRGB(87,242,0)},Locked={Color3.fromRGB(177,177,177),Color3.fromRGB(112,112,112)}} do
  make("UIGradient",name,styles,{Rotation=90,Color=ColorSequence.new(colors[1],colors[2])})
 end
 for id=1,3 do
  local row=make("Frame","World"..id,list,{BackgroundColor3=Color3.fromRGB(32,36,40),LayoutOrder=id,ClipsDescendants=true,ZIndex=4})
  row:SetAttribute("WorldId",id);row:SetAttribute("LockedBackgroundTransparency",.12)
  corner(row,30);border(row,5)
  local preview=make("ViewportFrame","MapPreview",row,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(46,179,247),
   Ambient=Color3.fromRGB(220,220,220),LightColor=Color3.fromRGB(255,251,231),LightDirection=Vector3.new(-.4,-1,-.4),ZIndex=4})
  corner(preview,30)
  local shade=make("Frame","LockedShade",row,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(26,28,31),
   BackgroundTransparency=.12,BorderSizePixel=0,Active=false,ZIndex=5});corner(shade,30)
  local name=label(row,"WorldName","World "..id);name.ZIndex=6;name.TextXAlignment=Enum.TextXAlignment.Left
  local button=make("TextButton","Action",row,{Text="",AnchorPoint=Vector2.new(1,1),BackgroundColor3=Color3.new(1,1,1),
   AutoButtonColor=false,Active=false,Interactable=false,ZIndex=7})
  corner(button,23);border(button,6)
  make("UIGradient","UIGradient",button,{Rotation=90,Color=styles.Locked.Color})
  local text=label(button,"Label","Locked");text.ZIndex=8
  lockIcon(button)
 end
 gui:SetAttribute("WorldSelectionVersion",1)
end
for _,gate in {workspace.World2Gate,workspace.World2Map.TrainingArea.World1ReturnGate} do
 if not gate:FindFirstChild("WorldSelectionWall") then
  local portal=gate.PortalSurface;local trigger=gate.WorldGateTrigger
  local offset=trigger.CFrame:PointToObjectSpace(portal.Position)
  make("Part","WorldSelectionWall",gate,{Anchored=true,CanCollide=true,CanQuery=true,CanTouch=false,
   Transparency=1,CastShadow=false,Size=Vector3.new(portal.Size.X,portal.Size.Y+2,.5),
   CFrame=trigger.CFrame*CFrame.new(0,offset.Y-1,0)})
 end
end
require(game.ReplicatedStorage.Modules.WorldSelectionPresentation).Layout(gui)
return {Gui=gui:GetFullName(),Version=gui:GetAttribute("WorldSelectionVersion")}

end
install()
-- UI-only static previews, copied from owned scenery. Never a new gameplay Map.
assert(not game.RunService:IsRunning())
local list=game.StarterGui.WorldTravelGui.Modal.Card.WorldList
local descriptions={}
local function preview(id,roots,eye,target,source)
 local view=list["World"..id].MapPreview
 if view:FindFirstChild("Scenery") then return end
 local model=Instance.new("Model");model.Name="Scenery";model.Parent=view
 local count=0
 for _,root in roots do
  local parts=root:IsA("BasePart") and {root} or root:GetDescendants()
  for _,part in parts do if part:IsA("BasePart") and part.Transparency<1 then
   local copy=part:Clone()
   for _,child in copy:GetChildren() do
    if not child:IsA("DataModelMesh") and not child:IsA("Decal") and not child:IsA("Texture") and not child:IsA("SurfaceAppearance") then child:Destroy() end
   end
   copy.Anchored=true;copy.CanCollide=false;copy.CanQuery=false;copy.CanTouch=false
   copy.Parent=model;count+=1
   if count%150==0 then task.wait() end
  end end
 end
 local camera=Instance.new("Camera");camera.Name="PreviewCamera";camera.FieldOfView=38
 camera.CFrame=CFrame.lookAt(eye,target);camera.Parent=view;view.CurrentCamera=camera
 view:SetAttribute("PreviewSource",source);descriptions[id]={Parts=count,Source=source}
end
local one=workspace.GeneratedMap.TrainingArea
preview(1,{one.Floor,one.Borders,one.Decorations,one.PathToTreadmills,one.EntranceCarpets,workspace.Treadmills},
 Vector3.new(287,32,52),Vector3.new(287,16,-42),"Current World1 owned lobby scenery")
local two=workspace.World2Map.TrainingArea
preview(2,{two.Floor,two.Borders,two.Decorations,two.PathToTreadmills,two.PathToRun,two.TreadmillDisplays},
 Vector3.new(15,31,1982),Vector3.new(15,15,1882),"Current World2 owned lobby scenery")
-- No World3 Map/destination exists. A purchased scenery sample is a visual-only placeholder.
local templates={}
for _,root in game.ServerStorage.PurchasedCourseOriginals:GetChildren() do for _,x in root:GetChildren() do
 if x.Name=="LevelTemplate" then table.insert(templates,x) end
end end
local sample=templates[1]
if sample then
 local p=sample.LevelFloor.Position;local z=sample.LevelFloor.Size.Z
 preview(3,{sample},p+Vector3.new(0,30,z*.28),p+Vector3.new(0,15,-z*.25),
 "Purchased LevelTemplate scenery sample ONLY; World3 map and destination not available")
end
return descriptions
