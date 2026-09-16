local RS=game:GetService("ReplicatedStorage")
local WallDisplayConfig=require(RS.Config:WaitForChild("WallDisplayConfig"))

-- Fixed world-space UI metrics from the original 27-stud Wall, 580x270 canvas.
-- Only the pixel conversion follows wall height; presentation sizes remain stud based.
local BASE_GAUGE_BOTTOM=4.32
local BASE_GAUGE_HEIGHT=5.13
local BASE_GAUGE_WIDTH=.76
local BASE_STAGE_HEIGHT=6.75
local BASE_STAGE_WIDTH=.8
local BASE_HEADING_HEIGHT=4.32
local BASE_HEADING_GAP=.4

local WallGaugeLayout={}
local function metrics(wall,surface)
 local height=wall.Size.Y
 surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
 surface.CanvasSize=Vector2.new(580,height*10)
 return height
end
local function scaleStrokes(panel,scale)
 for _,descendant in panel:GetDescendants() do
  if descendant:IsA("UIStroke") then
   local base=descendant:GetAttribute("WallDisplayBaseThickness")
   if typeof(base)~="number" then
    base=descendant.Thickness
    descendant:SetAttribute("WallDisplayBaseThickness",base)
   end
   descendant.Thickness=base*scale
  end
 end
end
function WallGaugeLayout.ApplyWall(wall,surface)
 local panel=surface:FindFirstChild("Panel")
 local bar=panel and panel:FindFirstChild("HPBar")
 if not bar then return end
 local height=metrics(wall,surface)
 local settings=WallDisplayConfig.Get()
 local scale=settings.Scale
 local bottom=BASE_GAUGE_BOTTOM
 local barHeight=BASE_GAUGE_HEIGHT*scale
 local barWidth=BASE_GAUGE_WIDTH*scale
 bar.Position=UDim2.new((1-barWidth)/2,0,1-(bottom+barHeight)/height,0)
 bar.Size=UDim2.new(barWidth,0,barHeight/height,0)
 local stage=panel:FindFirstChild("StageNumber")
 local heading=panel:FindFirstChild("Heading")
 local stageHeight=BASE_STAGE_HEIGHT*scale
 local stageWidth=BASE_STAGE_WIDTH*scale
 local stageBottom=bottom+barHeight+settings.StageGap
 if stage then
  stage.Position=UDim2.new((1-stageWidth)/2,0,1-(stageBottom+stageHeight)/height,0)
  stage.Size=UDim2.new(stageWidth,0,stageHeight/height,0)
 end
 if heading then
  local headingHeight=BASE_HEADING_HEIGHT*scale
  local headingBottom=stageBottom+stageHeight+BASE_HEADING_GAP*scale
  heading.Position=UDim2.new((1-stageWidth)/2,0,1-(headingBottom+headingHeight)/height,0)
  heading.Size=UDim2.new(stageWidth,0,headingHeight/height,0)
 end
 scaleStrokes(panel,scale)
end

-- Presentation only: follow each player's existing Wall visibility.
local bindings={}
local function bind(gui)
 if not gui:IsA("SurfaceGui") or gui.Name~="StageSurface" then return end
 local map=workspace:FindFirstChild("GeneratedMap")
 local corridor=map and map:FindFirstChild("BattleCorridor")
 if not corridor or not gui:IsDescendantOf(corridor) then return end
 local wall=gui.Parent
 if not wall or not wall:IsA("BasePart") or wall.Name~="Wall" then return end
 if bindings[gui] then return end
 local connections={}
 bindings[gui]=connections
 local function refresh()
  WallGaugeLayout.ApplyWall(wall,gui)
  local personal=gui:GetAttribute("PersonalStageDisplayEnabled")
  gui.Enabled=wall.LocalTransparencyModifier<.99 and wall.Transparency<.99 and personal==true
 end
 local function placeHP(child)
  if child:IsA("BillboardGui") and child.Name=="PersonalWallGauge" then
   child.StudsOffset=Vector3.new(0,0,0)
  end
 end
 table.insert(connections,wall:GetPropertyChangedSignal("Size"):Connect(refresh))
 table.insert(connections,wall:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(refresh))
 table.insert(connections,wall:GetPropertyChangedSignal("Transparency"):Connect(refresh))
 table.insert(connections,gui:GetAttributeChangedSignal("PersonalStageDisplayEnabled"):Connect(refresh))
 table.insert(connections,wall.ChildAdded:Connect(placeHP))
 table.insert(connections,gui.Destroying:Connect(function()
  for _,connection in connections do connection:Disconnect() end
  bindings[gui]=nil
 end))
 for _,child in wall:GetChildren() do placeHP(child) end
 refresh()
end
workspace.DescendantAdded:Connect(bind)
for _,child in workspace:GetDescendants() do bind(child) end

