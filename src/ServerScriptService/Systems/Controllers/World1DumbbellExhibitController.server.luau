-- World1 authored equipment only. Purchase/price/contact owners are unchanged.
local Visuals=require(game.ServerScriptService.Services.World1DumbbellVisuals)
local connections={}
local watched={}
local current
local function clear()
 for _,connection in connections do connection:Disconnect() end
 table.clear(connections);table.clear(watched)
end
local function watch(stand)
 if not stand:IsA("Model") or watched[stand] then return end
 watched[stand]=true
 local press=stand:FindFirstChild("Press")
 if press and press:IsA("BasePart") then
  connections[#connections+1]=press:GetPropertyChangedSignal("CFrame"):Connect(function()Visuals.RefreshExhibit(stand,false)end)
 end
 connections[#connections+1]=stand:GetAttributeChangedSignal("ItemId"):Connect(function()Visuals.RefreshExhibit(stand,true)end)
 Visuals.RefreshExhibit(stand,true)
end
local function bind(folder)
 if current==folder then return end
 clear();current=folder
 if not folder then return end
 for _,stand in folder:GetChildren() do watch(stand) end
 connections[#connections+1]=folder.ChildAdded:Connect(watch)
end
workspace.ChildAdded:Connect(function(x)if x.Name=="PerStepButtons" then bind(x)end end)
workspace.ChildRemoved:Connect(function(x)if x==current then bind(nil)end end)
bind(workspace:FindFirstChild("PerStepButtons"))
