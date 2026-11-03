local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Config.WorldGateConfig)
local View=require(RS.Modules.WorldSelectionPresentation)
local remote=RS.Remotes:WaitForChild("WorldTravelRequest")
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("WorldTravelGui")
local modal=gui:WaitForChild("Modal")
local card=modal:WaitForChild("Card")
local requestPending=false
local state
local world2Gate
local function world2Unlocked()
 local value=player:GetAttribute("HighestUnlockedWorld")
 return typeof(value)=="number" and value>=Config.RequiredWorld
end

local function refreshWorld2Gate()
 local gate=world2Gate
 if not gate or not gate.Parent then return end
 local portal=gate:FindFirstChild("PortalSurface")
 local sign=gate:FindFirstChild("Sign")
 local anchor=sign and sign:FindFirstChild("SignAnchor")
 local surface=anchor and anchor:FindFirstChild("WorldLabel")
 local gateTitle=surface and surface:FindFirstChild("Title")
 local subtitle=surface and surface:FindFirstChild("Subtitle")
 local canEnter=world2Unlocked()
 local style=canEnter and Config.Unlocked or Config.Locked
 if portal and portal:IsA("BasePart") then
  portal.Color=style.Color;portal.Material=style.Material;portal.Transparency=style.Transparency
 end
 if gateTitle then gateTitle.Text=Config.Title;gateTitle.TextColor3=style.TextColor;gateTitle.TextStrokeTransparency=canEnter and 1 or .15 end
 if subtitle then subtitle.Text=canEnter and Config.UnlockedText or Config.LockedText;subtitle.TextColor3=style.TextColor;subtitle.TextStrokeTransparency=canEnter and 1 or .15 end
 gate:SetAttribute("LocallyUnlocked",canEnter)
end


local function render()if state then View.Render(gui,state,requestPending) else View.Layout(gui) end end
local function close()
 modal.Visible=false -- Server's contact latch re-arms only after leaving the wall.
end
card.Close.Activated:Connect(close)
for _,row in card.WorldList:GetChildren() do if row:IsA("Frame") then
 local button=row.Action
 button.Activated:Connect(function()
  if requestPending or not modal.Visible or not button.Active or not button.Interactable
   or button:GetAttribute("Status")~="Teleport" then return end
  requestPending=true;render()
  remote:FireServer("Teleport",row:GetAttribute("WorldId"))
 end)
end end
remote.OnClientEvent:Connect(function(result)
 if type(result)~="table" then return end
 state=result
 if result.Type=="Open" then requestPending=false;modal.Visible=true
 elseif result.Type=="Close" then requestPending=false;close()
 elseif result.Type=="Result" then
  requestPending=false
  if result.Success then close() end
 end
 render()
end)
modal:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
player.CharacterAdded:Connect(function()requestPending=false;close();remote:FireServer("State")end)
for _,attribute in {"HighestUnlockedWorld","CurrentWorld"} do
 player:GetAttributeChangedSignal(attribute):Connect(function()
  refreshWorld2Gate()
  if attribute=="CurrentWorld" then close() end
  remote:FireServer("State")
 end)
end
workspace.ChildAdded:Connect(function(child)
 if child.Name==Config.GateName and child:IsA("Model") then world2Gate=child;refreshWorld2Gate() end
end)
workspace.ChildRemoved:Connect(function(child)if child==world2Gate then world2Gate=nil end end)
-- Viewport cameras belong only to these authored GUI previews, never Workspace.
for _,row in card.WorldList:GetChildren() do if row:IsA("Frame") then
 row.MapPreview.CurrentCamera=row.MapPreview:FindFirstChildOfClass("Camera")
end end
modal.Visible=false
world2Gate=workspace:FindFirstChild(Config.GateName)
refreshWorld2Gate();render();remote:FireServer("State")
