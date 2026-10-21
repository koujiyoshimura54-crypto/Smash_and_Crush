-- Static display only. Adapted from purchased HatchClient.mount; never plays tracks.
local RS=game:GetService("ReplicatedStorage")
local M={}
local Pet=require(RS.Modules.Pet)
local bindings=setmetatable({}, {__mode="k"})

function M.supports(name) return Pet.UsesModelViewport(name) end

-- Same static purchased-model display/fitting for Pet models and actual normal Egg MeshParts.
function M.mountTemplate(host,template,yaw,viewportName,orientation)
 assert(template and (template:IsA("Model") or template:IsA("BasePart")),"Missing purchased display geometry")
 viewportName=viewportName or "LimitedPetViewport"
 local prior=host:FindFirstChild(viewportName)
 if prior then prior:Destroy() end
 local viewport,model,world,resized
 local ok,result,returnedView=pcall(function()
 viewport=Instance.new("ViewportFrame")
 viewport.Name=viewportName;viewport.BackgroundTransparency=1
 viewport.Size=UDim2.fromScale(1,1);viewport.Position=UDim2.fromScale(0,0)
 viewport.Active=false;viewport.Interactable=false;viewport.ClipsDescendants=true
 viewport.ZIndex=host.ZIndex+1
 viewport.Ambient=Color3.fromRGB(190,190,190);viewport.LightColor=Color3.new(1,1,1)
 viewport.LightDirection=Vector3.new(-1,-1,-1)
 model=template:Clone()
 local parts=model:GetDescendants()
 table.insert(parts,model)
 for _,part in parts do
  if part:IsA("LuaSourceContainer") or part:IsA("LayerCollector") then part:Destroy()
  elseif part:IsA("BasePart") then
   part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
  end
 end
 -- Move the entire rig together, not just its HumanoidRootPart.
 model:PivotTo(orientation or CFrame.Angles(0,math.rad(yaw or 0),0))
 local low=Vector3.new(math.huge,math.huge,math.huge)
 local high=-low
 for _,part in parts do
  if part:IsA("BasePart") and part.Transparency<1 then
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
    low=low:Min(p);high=high:Max(p)
   end end end
  end
 end
 assert(low.X<math.huge,"No visible purchased geometry: "..template.Name)
 local center=(low+high)/2
 model:PivotTo(model:GetPivot()-center)
 low-=center;high-=center
 world=Instance.new("WorldModel");world.Name="DisplayWorld";world.Parent=viewport
 model.Parent=world
 local camera=Instance.new("Camera");camera.Name="DisplayCamera";camera.FieldOfView=32
 camera.Parent=viewport;viewport.CurrentCamera=camera
 local direction=Vector3.new(.65,.3,-1).Unit
 local rotation=CFrame.lookAt(direction,Vector3.zero).Rotation
 local function fit()
  local size=viewport.AbsoluteSize
  local aspect=if size.Y>0 then math.max(size.X/size.Y,.1) else 1
  local tanY=math.tan(math.rad(camera.FieldOfView/2));local tanX=tanY*aspect
  local distance=0
  for x=0,1 do for y=0,1 do for z=0,1 do
   local point=Vector3.new(x==0 and low.X or high.X,y==0 and low.Y or high.Y,z==0 and low.Z or high.Z)
   local p=rotation:VectorToObjectSpace(point)
   distance=math.max(distance,p.Z+math.abs(p.X)/tanX,p.Z+math.abs(p.Y)/tanY)
  end end end
  camera.CFrame=CFrame.lookAt(direction*math.max(distance*1.12,1),Vector3.zero)
 end
 viewport.Parent=host;fit()
 resized=viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
 local destroyed=false
 local function cleanup()
  if destroyed then return end destroyed=true
  resized:Disconnect();viewport:Destroy()
 end
 return cleanup,viewport
 end)
 if not ok then
  if resized then resized:Disconnect() end
  if model then model:Destroy() end
  if world then world:Destroy() end
  if viewport then viewport:Destroy() end
  error(result)
 end
 return result,returnedView
end

function M.mount(host,name)
 local entry=Pet.VisualEntry(name)
 if not entry then return nil end
 local template=Pet.model(name)
 assert(template and template:IsA("Model"),"Missing purchased limited Pet: "..name)
 return M.mountTemplate(host,template,entry.Yaw,"LimitedPetViewport")
end

function M.mountEgg(host,name)
 local template=require(RS.Modules.Egg).part(name)
 assert(template and template:IsA("BasePart"),"Missing actual normal Egg: "..name)
 return M.mountTemplate(host,template,0,"NormalEggViewport",template.CFrame.Rotation)
end

-- Inventory tabs/menus can hide through an ancestor. Release static models then.
function M.bind(host,name,reserveTitle)
 if not M.supports(name) then return nil end
 if bindings[host] then bindings[host]() end
 local watched={};local lifetime={};local unmount;local dead=false
 local originalImage=host.Image
 host.Image=""
 local function clear()
  if unmount then unmount();unmount=nil end
 end
 local function refresh()
  if dead then return end
  local visible=true;local layer=false;local p=host
  while p do
   if p:IsA("GuiObject") and not p.Visible then visible=false end
   if p:IsA("LayerCollector") then layer=true;if not p.Enabled then visible=false end end
   p=p.Parent
  end
  if visible and layer then
   if not unmount then
    local view
    unmount,view=M.mount(host,name)
    -- Reserve the purchased tile title band above the visible model.
    view.Position=reserveTitle==false and UDim2.fromScale(0,0) or UDim2.fromScale(.03,.20)
    view.Size=reserveTitle==false and UDim2.fromScale(1,1) or UDim2.fromScale(.94,.76)
   end
  else clear() end
 end
 local function watch()
  for _,c in watched do c:Disconnect() end table.clear(watched)
  local p=host
  while p do
   if p:IsA("GuiObject") then table.insert(watched,p:GetPropertyChangedSignal("Visible"):Connect(refresh))
   elseif p:IsA("LayerCollector") then table.insert(watched,p:GetPropertyChangedSignal("Enabled"):Connect(refresh)) end
   p=p.Parent
  end
  refresh()
 end
 local function cleanup()
  if dead then return end dead=true
  clear()
  for _,c in watched do c:Disconnect() end
  for _,c in lifetime do c:Disconnect() end
  bindings[host]=nil;host.Image=originalImage
 end
 bindings[host]=cleanup
 table.insert(lifetime,host.AncestryChanged:Connect(watch))
 table.insert(lifetime,host.Destroying:Connect(cleanup))
 watch()
 return cleanup
end
return table.freeze(M)
