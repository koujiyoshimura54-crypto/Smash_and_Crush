-- Display only: the server publishes both quantities, including lifecycle resets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = script.Parent
local hud = gui:WaitForChild("HUD")
local HUDLayout = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("HUDLayout"))
local style = gui:WaitForChild("StrengthLevelHUD"):WaitForChild("LevelPanel"):WaitForChild("Level")

local label = Instance.new("TextLabel")
label.Name = "RunInventoryLabel"
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.Active = false
label.Selectable = false
label.AutoLocalize = false
label.FontFace = style.FontFace
label.TextColor3 = style.TextColor3
label.TextStrokeColor3 = style.TextStrokeColor3
label.TextStrokeTransparency = style.TextStrokeTransparency
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Center
label.TextScaled = false
label.TextWrapped = false
label.ZIndex = style.ZIndex
label.Text = ""
local outline = style:FindFirstChild("TextOutline")
if outline then outline:Clone().Parent = label end
label.Parent = hud

local function render()
	local count = player:GetAttribute("RunInventoryCount")
	local capacity = player:GetAttribute("RunInventoryCapacity")
	-- Do not invent a capacity while the initial attributes are replicating.
	label.Text = "Inventory " .. (count == nil and "-" or tostring(count))
		.. " / " .. (capacity == nil and "-" or tostring(capacity))
end

local connections = {
	player:GetAttributeChangedSignal("RunInventoryCount"):Connect(render),
	player:GetAttributeChangedSignal("RunInventoryCapacity"):Connect(render),
}
-- Inactive runs remain visible; no client-side reset or capacity decision.
render()
HUDLayout.Mount(gui).Refresh()
script.Destroying:Connect(function()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	label:Destroy()
end)
