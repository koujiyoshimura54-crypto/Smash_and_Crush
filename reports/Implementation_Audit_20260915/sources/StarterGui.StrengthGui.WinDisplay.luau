local player=game:GetService("Players").LocalPlayer
local Format=require(game:GetService("ReplicatedStorage").Modules:WaitForChild("NumberFormat"))
local label=script.Parent:WaitForChild("WinLabel"):WaitForChild("Amount")
local function update()
 label.Text=Format.Format(player:GetAttribute("Win") or 0)
end
player:GetAttributeChangedSignal("Win"):Connect(update)
update()

