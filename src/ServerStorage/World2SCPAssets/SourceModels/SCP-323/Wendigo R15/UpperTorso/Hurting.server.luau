function onTouched(hit)
	local humanoid = hit.Parent:findFirstChild("Humanoid")
	if (humanoid ~= nil) then
		humanoid.Health = humanoid.Health - 25
	end
end

script.Parent.Touched:connect(onTouched)