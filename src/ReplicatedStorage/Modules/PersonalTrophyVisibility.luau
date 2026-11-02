-- World1 only. Server Trophy records authorize presentation; never authorize rewards here.
local M={}
function M.Mount(player)
 local grants={}
 local roots={}
 local connections={}
 local revision
 local dead=false
 local deathConnection
 local function connect(signal,fn)local c=signal:Connect(fn);table.insert(connections,c);return c end
 local function alive()
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  return hum and hum.Health>0 and (player:GetAttribute("CurrentWorld") or 1)==1
 end
 local function equipment(x)
  while x and x~=workspace do
   if x.Name=="TrophyNormalButton" or x.Name=="TrophyDoubleButton" then
    local stage=x.Parent;local corridor=stage and stage.Parent;local map=corridor and corridor.Parent
    local n=stage and tonumber(stage.Name:match("^Stage(%d%d)$"))
    if n and n>=1 and n<=10 and corridor and corridor.Name=="BattleCorridor" and map
     and map.Name=="GeneratedMap" and map.Parent==workspace then return x,n end
   end
   x=x.Parent
  end
 end
 local function permitted(record)return alive() and grants[record.Stage]~=nil end
 local function apply(record,item)
  if not item.Object.Parent then return end
  item.Writing=true
  local show=permitted(record)
  for property,original in item.Values do
   local hidden=property=="LocalTransparencyModifier" and 1
    or property=="Volume" and 0 or false
   local value=show and original or hidden
   item.Applied[property]=value
   item.Object[property]=value
  end
  if not show and (item.Object:IsA("ParticleEmitter") or item.Object:IsA("Trail")) then item.Object:Clear() end
  item.Writing=false
 end
 local function add(record,x)
  if record.Items[x] then return end
  local properties
  if x:IsA("BasePart") or x:IsA("Decal") then properties={"LocalTransparencyModifier"}
  elseif x:IsA("LayerCollector") or x:IsA("ParticleEmitter") or x:IsA("Trail") or x:IsA("Beam")
   or x:IsA("Light") or x:IsA("Highlight") or x:IsA("Fire") or x:IsA("Smoke") or x:IsA("Sparkles")
   or x:IsA("ProximityPrompt") then properties={"Enabled"}
  elseif x:IsA("GuiObject") or x:IsA("GuiBase3d") then properties={"Visible"}
  elseif x:IsA("Sound") then properties={"Volume"} end
  if not properties then return end
  local item={Object=x,Values={},Applied={},Connections={}};record.Items[x]=item
  for _,property in properties do
   item.Values[property]=x[property]
   table.insert(item.Connections,x:GetPropertyChangedSignal(property):Connect(function()
    -- Property notifications can be deferred until after apply returns.
    if item.Writing or x[property]==item.Applied[property] then return end
    item.Values[property]=x[property];apply(record,item)
   end))
  end
  apply(record,item)
 end
 local function refresh()
  for _,record in roots do for _,item in record.Items do apply(record,item) end end
 end
 local function release(root)
  local record=roots[root];if not record then return end;roots[root]=nil
  for _,c in record.Connections do c:Disconnect() end
  for x,item in record.Items do
   for _,c in item.Connections do c:Disconnect() end
   if x.Parent then for property,value in item.Values do x[property]=value end end
  end
 end
 local function discover(x)
  if dead then return end
  local root,stage=equipment(x);if not root then return end
  local record=roots[root]
  if not record then
   record={Stage=stage,Items={},Connections={}};roots[root]=record
   table.insert(record.Connections,root.DescendantAdded:Connect(function(child)add(record,child)end))
   table.insert(record.Connections,root.DescendantRemoving:Connect(function(child)
    task.defer(function()
     local item=record.Items[child]
     if not item or child:IsDescendantOf(root) then return end
     record.Items[child]=nil
     for _,c in item.Connections do c:Disconnect() end
     if child.Parent then for property,value in item.Values do child[property]=value end end
    end)
   end))
   table.insert(record.Connections,root.AncestryChanged:Connect(function()
    if equipment(root)~=root then release(root) end
   end))
   add(record,root);for _,child in root:GetDescendants() do add(record,child) end
  else add(record,x) end
 end
 local function clear()table.clear(grants);refresh()end
 local function characterAdded(character)
  if deathConnection then deathConnection:Disconnect();deathConnection=nil end
  clear()
  task.spawn(function()
   local hum=character:WaitForChild("Humanoid",10)
   if dead or player.Character~=character or not hum then return end
   deathConnection=hum.Died:Connect(clear)
  end)
 end
 connect(workspace.DescendantAdded,discover)
 local map=workspace:FindFirstChild("GeneratedMap")
 local corridor=map and map:FindFirstChild("BattleCorridor")
 if corridor then
  for _,stage in corridor:GetChildren() do
   for _,name in {"TrophyNormalButton","TrophyDoubleButton"} do local root=stage:FindFirstChild(name);if root then discover(root) end end
  end
 end
 connect(player:GetAttributeChangedSignal("CurrentWorld"),clear)
 connect(player.CharacterRemoving,clear)
 connect(player.CharacterAdded,characterAdded)
 if player.Character then characterAdded(player.Character) end
 local controller={}
 function controller.Handle(d)
  -- Called only after CombatClient's owner/world/revision/sequence fence.
  if d.Type=="Initialize" then
   if revision~=d.RunRevision then revision=d.RunRevision;clear() end
  elseif d.Type=="TrophySpawn" and d.StaticButtons and typeof(d.Stage)=="number" and typeof(d.Id)=="number" then
   grants[d.Stage]=d.Id;refresh()
  elseif d.Type=="TrophyRemoved" or d.Type=="TrophyCollected" then
   for stage,id in grants do if id==d.Id then grants[stage]=nil end end
   refresh()
  end
 end
 function controller.Destroy()
  dead=true
  for _,c in connections do c:Disconnect() end
  if deathConnection then deathConnection:Disconnect() end
  for root in roots do release(root) end
 end
 return controller
end
return M
