wait(0.2)
local player=game.Players.LocalPlayer
local camera=workspace.CurrentCamera
local tool=script.Parent
local char=player.Character
local humanoid=char:WaitForChild("Humanoid")
SETTINGS={
	
	FIRST_PERSON={
		left_arm=true, --if left arm is Enabled
		right_arm=true, --If right arm is Enabled
		arm_transparency=0, --The transparency of the Arms
		arm_color=BrickColor.new("Really black"), --The colo(u)r of the arms, If below is set to true, This will be the BrickColor of the Arms.
		change_color=false, --Changes the colo(u)r of the arms, If false, Will set them as the Players arm colo(u)r
		add_shirt=true, --If true, add's the Character's shirt to the Arms--
	},
	
}

function FirstPerson()
		if (camera.focus.p - camera.CoordinateFrame.p).magnitude > 1 then
			return false
		else
			return true
		end
end
function Start()
			    anim_arms=Instance.new("Model")
			anim_arms.Name="Arms_Model"
			local Shirt=player.Character:FindFirstChild("Shirt")
				if Shirt then
					Shirt:clone().Parent=anim_arms
					Instance.new("Humanoid",anim_arms)
				end
			local r,l = char:FindFirstChild("Right Arm"):clone(), char:FindFirstChild("Left Arm"):clone()
			if r and SETTINGS.FIRST_PERSON.right_arm then
				r.Transparency=SETTINGS.FIRST_PERSON.arm_transparency
				r.Material=Enum.Material.SmoothPlastic
				if SETTINGS.FIRST_PERSON.change_color then
				r.BrickColor=SETTINGS.FIRST_PERSON.arm_color
				end
			end
			if l and SETTINGS.FIRST_PERSON.left_arm then
				l.Transparency=SETTINGS.FIRST_PERSON.arm_transparency
				l.Material=Enum.Material.SmoothPlastic
				if SETTINGS.FIRST_PERSON.change_color then
				l.BrickColor=SETTINGS.FIRST_PERSON.arm_color
				end
			end
			local rw,lw = Instance.new("Weld"),Instance.new("Weld")
			if rw and SETTINGS.FIRST_PERSON.right_arm then
				rw.Part0=r
				rw.Part1=char:FindFirstChild("Right Arm")
				rw.Parent=r
				r.Parent=anim_arms
			end
			if lw and SETTINGS.FIRST_PERSON.left_arm then
				lw.Part0=l
				lw.Part1=char:FindFirstChild("Left Arm")
				lw.Parent=l
				l.Parent=anim_arms
			end
			l.CanCollide=false
			r.CanCollide=false
			if SETTINGS.FIRST_PERSON.right_arm then
			if r:FindFirstChild("RightGrip")~=nil then r:FindFirstChild("RightGrip"):Destroy() end
			end
			if tool.Handle:FindFirstChild("Mesh") ~= nil then tool.Handle.Mesh:Destroy() end
			while equipped do
			if FirstPerson() then
					if anim_arms ~= nil then
						anim_arms.Parent=camera
						humanoid.CameraOffset = Vector3.new(0, -0.2, -0.5)
					end
				else
					if anim_arms ~= nil then
						anim_arms.Parent=nil
						humanoid.CameraOffset = Vector3.new(0,0,0)
					end
				end
				wait()
			end
end
function End()
	anim_arms:Destroy()
	anim_arms=nil
	humanoid.CameraOffset = Vector3.new(0,0,0)
end

tool.Equipped:connect(function ()
	equipped=true
	Start()
end)
tool.Unequipped:connect(function ()
	equipped=false
	End()
end)