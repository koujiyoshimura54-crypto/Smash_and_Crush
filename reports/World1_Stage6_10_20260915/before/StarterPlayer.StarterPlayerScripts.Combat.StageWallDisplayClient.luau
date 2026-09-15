-- Presentation only: follow each player's existing Wall visibility.
local bindings={}
local function bind(gui)
 if not gui:IsA("SurfaceGui") or gui.Name~="StageSurface" then return end
 local wall=gui.Parent
 if not wall or not wall:IsA("BasePart") or wall.Name~="Wall" then return end
 if bindings[gui] then return end
 local connections={}
 bindings[gui]=connections
 local function refresh()
  gui.Enabled=wall.LocalTransparencyModifier<.99 and wall.Transparency<.99
 end
 local function placeHP(child)
  if child:IsA("BillboardGui") and child.Name=="PersonalWallGauge" then
   child.StudsOffset=Vector3.new(0,0,0)
  end
 end
 table.insert(connections,wall:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(refresh))
 table.insert(connections,wall:GetPropertyChangedSignal("Transparency"):Connect(refresh))
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

