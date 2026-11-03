-- Display-only bag: quantities remain authoritative; visibility follows authored areas.
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
local humanoid,healthConnection
local function footprint(floor,root)
 if not (floor and floor:IsA("BasePart")) then return false end
 local pos=floor.CFrame:PointToObjectSpace(root.Position)
 return math.abs(pos.X)<=floor.Size.X/2 and math.abs(pos.Z)<=floor.Size.Z/2
end
local function inBattle()
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root or not humanoid or humanoid.Parent~=character or humanoid.Health<=0 then return false end
 local world=player:GetAttribute("CurrentWorld")
 if world~=1 and world~=2 then return false end
 local map=workspace:FindFirstChild(world==2 and "World2Map" or "GeneratedMap")
 local training=map and map:FindFirstChild("TrainingArea")
 local lobby=training and training:FindFirstChild("Floor")
 -- Same floor-footprint convention as RunReturnClient, with missing data hidden.
 if not lobby or footprint(lobby,root) then return false end
 local corridor=map:FindFirstChild("BattleCorridor")
 if not corridor then return false end
 for _,stage in ipairs(corridor:GetChildren()) do
  if stage:IsA("Model") and stage.Name:match("^Stage%d%d$") then
   if footprint(stage:FindFirstChild("LevelFloor") or stage:FindFirstChild("Floor"),root) then return true end
  end
 end
 return false
end
local function render()
 local count=player:GetAttribute("RunInventoryCount")
 local capacity=player:GetAttribute("RunInventoryCapacity")
 label.Text=(count==nil and "-" or tostring(count)).." / "..(capacity==nil and "-" or tostring(capacity))
 local visible=type(count)=="number" and type(capacity)=="number" and inBattle()
 label.Visible=visible;icon.Visible=visible
end
local connections={}
for _,name in {"RunInventoryCount","RunInventoryCapacity","CurrentWorld","RunInventoryId","RunInventoryActive"} do
 table.insert(connections,player:GetAttributeChangedSignal(name):Connect(render))
end
local function bindCharacter(character)
 if healthConnection then healthConnection:Disconnect();healthConnection=nil end
 humanoid=nil;render()
 local hum=character:WaitForChild("Humanoid",10)
 if player.Character~=character or not hum then return end
 humanoid=hum;healthConnection=hum.HealthChanged:Connect(render);render()
end
table.insert(connections,player.CharacterAdded:Connect(bindCharacter))
table.insert(connections,player.CharacterRemoving:Connect(function()
 if healthConnection then healthConnection:Disconnect();healthConnection=nil end
 humanoid=nil;render()
end))
local elapsed=0
table.insert(connections,RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.2 then return end
 elapsed=0;render()
end))
if player.Character then task.spawn(bindCharacter,player.Character) end
render();HUDLayout.Mount(gui).Refresh()
script.Destroying:Connect(function()
 for _,connection in ipairs(connections) do connection:Disconnect() end
 if healthConnection then healthConnection:Disconnect() end
end)
