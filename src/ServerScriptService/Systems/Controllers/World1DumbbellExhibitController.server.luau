-- Both authored equipment folders share this event-driven visual owner.
-- Historical path retained; purchase/price/contact owners stay unchanged.
local Visuals=require(game.ServerScriptService.Services.World1DumbbellVisuals)
local Stands=require(game.ReplicatedStorage.Config.DumbbellStandConfig)
local bindings={}
local function disconnect(list)
 for _,c in list do c:Disconnect()end
end
local function unbind(world)
 local b=bindings[world];if not b then return end
 disconnect(b.Connections)
 for _,entry in b.Stands do disconnect(entry.Connections)end
 bindings[world]=nil
end
local function bind(world,folder)
 if bindings[world] and bindings[world].Folder==folder then return end
 unbind(world)
 if not folder then return end
 local b={Folder=folder,Connections={},Stands={}};bindings[world]=b
 local function watch(stand)
  if not stand:IsA("Model") or b.Stands[stand] then return end
  local entry={Connections={}};b.Stands[stand]=entry
  local function update(rebuild)Visuals.RefreshExhibit(stand,rebuild)end
  local function pressAdded(press)
   if press.Name~="Press" or not press:IsA("BasePart") or entry.Press==press then return end
   entry.Press=press
   if entry.PressConnection then entry.PressConnection:Disconnect()end
   entry.PressConnection=press:GetPropertyChangedSignal("CFrame"):Connect(function()update(false)end)
   table.insert(entry.Connections,entry.PressConnection)
   update(false)
  end
  table.insert(entry.Connections,stand:GetAttributeChangedSignal("ItemId"):Connect(function()update(true)end))
  table.insert(entry.Connections,stand:GetAttributeChangedSignal("WorldId"):Connect(function()update(true)end))
  table.insert(entry.Connections,stand.ChildAdded:Connect(function(x)
   if x.Name=="Press" then pressAdded(x) elseif x.Name=="BillboardGui" then update(false)end
  end))
  local press=stand:FindFirstChild("Press");if press then pressAdded(press)end
  update(false)
 end
 for _,stand in folder:GetChildren() do watch(stand) end
 table.insert(b.Connections,folder.ChildAdded:Connect(watch))
 table.insert(b.Connections,folder.ChildRemoved:Connect(function(stand)
  local entry=b.Stands[stand];if entry then disconnect(entry.Connections);b.Stands[stand]=nil end
 end))
end
local function sync()for world=1,2 do bind(world,Stands.GetFolder(world))end end
workspace.DescendantAdded:Connect(function(x)if x.Name==Stands.FolderName then sync()end end)
workspace.DescendantRemoving:Connect(function(x)
 for world,b in bindings do if x==b.Folder then unbind(world)end end
end)
sync()
