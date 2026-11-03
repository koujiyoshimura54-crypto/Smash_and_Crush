-- Display-only bag: hidden in either Lobby footprint, visible everywhere else.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=script.Parent
local hud=gui:WaitForChild("HUD")
local HUDLayout=require(RS.Modules.HUDLayout)
local HUDStyle=require(RS.Config.StrengthHUDStyle)
local label=hud:WaitForChild("RunInventoryLabel")
local icon=hud:WaitForChild("RunInventoryIcon")
label.Visible=false;icon.Visible=false
label.AutoLocalize=false;label.Font=HUDStyle.Font
local bounds=RS:WaitForChild("BattleBagLobbyBounds")
local function outsideLobby()
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root then return false end -- No location yet, including character replacement.
 -- Bounds come from the actual server floors and survive client streaming.
 -- Check both physical Lobbies; CurrentWorld/teleport replication order is irrelevant.
 for world=1,2 do
  local cf=bounds:GetAttribute("World"..world.."CFrame")
  local size=bounds:GetAttribute("World"..world.."Size")
  if typeof(cf)~="CFrame" or typeof(size)~="Vector3" then return false end
  local pos=cf:PointToObjectSpace(root.Position)
  if math.abs(pos.X)<=size.X/2 and math.abs(pos.Z)<=size.Z/2 then return false end
 end
 return true
end
local function render()
 local count=player:GetAttribute("RunInventoryCount")
 local capacity=player:GetAttribute("RunInventoryCapacity")
 label.Text=(count==nil and "-" or tostring(count)).." / "..(capacity==nil and "-" or tostring(capacity))
 local visible=outsideLobby()
 label.Visible=visible;icon.Visible=visible
end
local connections={}
for _,name in {"RunInventoryCount","RunInventoryCapacity","CurrentWorld"} do
 table.insert(connections,player:GetAttributeChangedSignal(name):Connect(render))
end
table.insert(connections,player.CharacterAdded:Connect(render))
table.insert(connections,player.CharacterRemoving:Connect(function()
 label.Visible=false;icon.Visible=false
end))
local elapsed=0
table.insert(connections,RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.2 then return end
 elapsed=0;render()
end))
render();HUDLayout.Mount(gui).Refresh()
script.Destroying:Connect(function()
 for _,connection in ipairs(connections) do connection:Disconnect() end
end)
