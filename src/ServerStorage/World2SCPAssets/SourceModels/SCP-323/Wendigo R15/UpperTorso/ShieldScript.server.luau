function ot(hit)
	ch = hit:GetChildren()
	for i = 1, #ch do
		if ch[i].className == "BodyVelocity" then
			ch[i].velocity = ch[i].velocity*-1
		end
	end
	if hit.Parent ~= nil then
		if hit.Parent:FindFirstChild("Humanoid") ~= nil then
			if hit.Parent ~= script.Parent.Parent then
				if hit.Parent:FindFirstChild("Torso") ~= nil then
					hit.Parent.Torso.Velocity = (hit.Parent.Torso.Position - script.Parent.Position)*5
					hit.Parent.Torso.RotVelocity = (hit.Parent.Torso.Position - script.Parent.Position)*5
				end
				hit.Parent.Humanoid.PlatformStand = true
			end
		else
			if hit.Parent.className == "Model" or hit.Parent.className == "Hat" then
				if hit.Parent.Parent:FindFirstChild("Humanoid") == nil then
					hit:breakJoints()
					if hit.Anchored == false then
						hit.Velocity = hit.Velocity*-1 + ((hit.Position - script.Parent.Position)*1000)/hit:GetMass()
					end
				end
			else
				hit:breakJoints()
				if hit.Anchored == false then
					hit.Velocity = hit.Velocity*-1 + ((hit.Position - script.Parent.Position)*1000)/hit:GetMass()
				end
			end
		end
	end
	if hit.Parent ~= nil then
		if hit.Parent:FindFirstChild("Humanoid") ~= nil then
			if hit.Parent ~= script.Parent.Parent then
				wait(0.5)
				hit.Parent.Humanoid.PlatformStand = false
			end
		end
	end
end
function remove(child)
	child:Remove()
end
script.Parent.Touched:connect(ot)
script.Parent.ChildAdded:connect(remove)