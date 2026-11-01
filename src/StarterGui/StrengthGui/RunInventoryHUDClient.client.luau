-- Display only: the server publishes both quantities, including lifecycle resets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = script.Parent
local hud = gui:WaitForChild("HUD")
local HUDLayout = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("HUDLayout"))
local HUDStyle = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("StrengthHUDStyle"))
-- Existing purchased UI instances are stored in the HUD; no UI is reconstructed.
local label = hud:WaitForChild("RunInventoryLabel")
local icon = hud:WaitForChild("RunInventoryIcon")
label.AutoLocalize = false
label.Font = HUDStyle.Font

local function render()
	local count = player:GetAttribute("RunInventoryCount")
	local capacity = player:GetAttribute("RunInventoryCapacity")
	-- Do not invent a capacity while the initial attributes are replicating.
	label.Text = (count == nil and "-" or tostring(count))
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
	icon:Destroy()
end)
