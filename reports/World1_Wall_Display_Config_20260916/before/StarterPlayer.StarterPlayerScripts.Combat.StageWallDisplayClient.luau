-- Fixed world-space UI metrics from the original 27-stud Wall, 580x270 canvas.
-- Resize the canvas with the physical wall: text pixels and bar height no longer stretch.
local WallGaugeLayout={}
WallGaugeLayout.StageGapStuds=1
local function metrics(wall,surface)
 local height=wall.Size.Y
 surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
 surface.CanvasSize=Vector2.new(580,height*10)
 return height,4.32,5.13
end
function WallGaugeLayout.ApplyWall(wall,surface)
 local panel=surface:FindFirstChild("Panel")
 local bar=panel and panel:FindFirstChild("HPBar")
 if not bar then return end
 local height,bottom,barHeight=metrics(wall,surface)
 bar.Position=UDim2.new(bar.Position.X.Scale,bar.Position.X.Offset,1-(bottom+barHeight)/height,0)
 bar.Size=UDim2.new(bar.Size.X.Scale,bar.Size.X.Offset,barHeight/height,0)
 local stage=panel:FindFirstChild("StageNumber")
 local heading=panel:FindFirstChild("Heading")
 local stageBottom=bottom+barHeight+WallGaugeLayout.StageGapStuds
 if stage then
  stage.Position=UDim2.new(.1,0,1-(stageBottom+6.75)/height,0)
  stage.Size=UDim2.new(.8,0,6.75/height,0)
 end
 if heading then
  heading.Position=UDim2.new(.1,0,1-(stageBottom+6.75+.4+4.32)/height,0)
  heading.Size=UDim2.new(.8,0,4.32/height,0)
 end
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

