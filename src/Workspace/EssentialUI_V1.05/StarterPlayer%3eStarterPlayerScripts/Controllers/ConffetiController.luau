local ConffetiController = {}

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Conffeti = ReplicatedStorage.Assets.Confetti

function ConffetiController:Emit()
	local char = Player.Character or Player.CharacterAdded:Wait()
	local clone = Conffeti:Clone()
	
	clone.CFrame = char.PrimaryPart:GetPivot()
	clone.Parent = char.PrimaryPart
	
	for _, emit:ParticleEmitter in clone:GetChildren() do
		emit:Emit(emit:GetAttribute("EmitCount"))
	end
	
	task.delay(5, function ()
		clone:Destroy()
	end)
end

function ConffetiController:init()
	require(game:GetService("ReplicatedStorage").Utils.Packets).Conffeti.Emit.OnClientEvent:Connect(function ()
		ConffetiController:Emit()
	end)
end

return ConffetiController
