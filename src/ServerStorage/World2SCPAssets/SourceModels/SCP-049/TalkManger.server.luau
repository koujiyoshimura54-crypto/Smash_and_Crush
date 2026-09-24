 local IgnoreSounds = {
	["Kill"] = true, 
	["Climbing"] = true, 
	["Died"] = true,
	["FreeFalling"] = true,
	["Breath"] = true,
	["GettingUp"] = true,
	["Jumping"] = true,
	["Running"] = true,
	["Landing"] = true,
	["Splash"] = true,
	["Swimming"] = true
}


while wait(0) do
	
	for _,soudns in pairs (script.Parent:GetDescendants()) do
		if soudns and soudns:IsA("Sound") then
			if not IgnoreSounds[soudns.Name] then
				if soudns.IsPlaying == true then
					script.Parent.Talking.Value = true
				else
					script.Parent.Talking.Value = false
				end
			end
		end
	end
	
	
end