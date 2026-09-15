local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS:WaitForChild("Config"):WaitForChild("WorldGateConfig"))
local player=Players.LocalPlayer
local activeGate
local function refresh()
 local gate=activeGate
 if not gate or not gate.Parent then return end
 local portal=gate:FindFirstChild("PortalSurface")
 local sign=gate:FindFirstChild("Sign")
 local anchor=sign and sign:FindFirstChild("SignAnchor")
 local gui=anchor and anchor:FindFirstChild("WorldLabel")
 local title=gui and gui:FindFirstChild("Title")
 local subtitle=gui and gui:FindFirstChild("Subtitle")
 local value=player:GetAttribute("HighestUnlockedWorld")
 local unlocked=typeof(value)=="number" and value>=Config.RequiredWorld
 local style=unlocked and Config.Unlocked or Config.Locked
 if portal and portal:IsA("BasePart") then
  portal.Color=style.Color
  portal.Material=style.Material
  portal.Transparency=style.Transparency
 end
 if title then title.Text=Config.Title;title.TextColor3=style.TextColor;title.TextStrokeTransparency=unlocked and 1 or .15 end
 if subtitle then subtitle.Text=unlocked and Config.UnlockedText or Config.LockedText;subtitle.TextColor3=style.TextColor;subtitle.TextStrokeTransparency=unlocked and 1 or .15 end
 -- Local presentation hint only. Future travel must use server CanAccessWorld.
 -- CanTouch stays false for BOTH states; no travel or touch handler is installed.
 gate:SetAttribute("LocallyUnlocked",unlocked)
end
local gateConnection
local function bind(gate)
 if gate.Name~=Config.GateName or not gate:IsA("Model") then return end
 if gateConnection then gateConnection:Disconnect() end
 activeGate=gate
 gateConnection=gate.DescendantAdded:Connect(refresh)
 refresh()
end
player:GetAttributeChangedSignal("HighestUnlockedWorld"):Connect(refresh)
workspace.ChildAdded:Connect(bind)
workspace.ChildRemoved:Connect(function(gate)
 if gate==activeGate then
  if gateConnection then gateConnection:Disconnect();gateConnection=nil end
  activeGate=nil
 end
end)
local gate=workspace:FindFirstChild(Config.GateName)
if gate then bind(gate) end

