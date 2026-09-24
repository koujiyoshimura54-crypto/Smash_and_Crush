local model = script.Parent
local prompt = model.Prompt.ProximityPrompt

prompt.Triggered:Connect(function(player)
	local oldCharacter = player.Character
	local morphModel = model:FindFirstChildOfClass("Model")
	local newCharacter = morphModel:Clone()
	
	newCharacter.HumanoidRootPart.Anchored = false
	newCharacter:SetPrimaryPartCFrame(oldCharacter.PrimaryPart.CFrame)
	
	player.Character = newCharacter
	newCharacter.Parent = workspace
end)