local player=game:GetService("Players").LocalPlayer
local services=script.Parent.Parent:WaitForChild("Services")
local Guide=require(game.ReplicatedStorage.Modules.EquipmentTutorialGuide)
local stopItem=Guide.Mount(player,services,"Item")
local stopDumbbell=Guide.Mount(player,services,"Dumbbell")
script.Destroying:Connect(function()stopItem();stopDumbbell()end)
