while wait(0) do
	if script.Parent.Wandering == true then
		wait(math.random(9,10))
		if script.Parent.Talking.Value == false then
			script.Parent.HumanoidRootPart["Wander"..math.random(1,2)]:Play()
		end
				script.Parent.Humanoid.WalkSpeed= 0
				wait(math.random(6,7))
				script.Parent.Humanoid.WalkSpeed= 10
	else
		wait(math.random(5,9))
		if script.Parent.Talking.Value == false then
			script.Parent.UpperTorso["Taunt"..math.random(1,9)]:Play()
		end
		
	end
end