local player=game:GetService("Players").LocalPlayer
local services=script.Parent.Parent:WaitForChild("Services")
require(services.PetClient).bootstrap()
local stop=require(game.ReplicatedStorage.Modules.EggPetTutorialGuide).Mount(player,services)
script.Destroying:Connect(stop)
