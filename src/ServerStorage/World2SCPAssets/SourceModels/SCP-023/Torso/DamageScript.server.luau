script.Parent.Touched:Connect(function(hit)
	local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.Health-7
	end
end)