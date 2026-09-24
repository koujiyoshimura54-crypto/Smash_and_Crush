--[[
	SCP-058
	Will follow near players in a X range
	I could have used pathfinding but it would lag moar so no!
	~felipeblox10
--]]
local Players 						= 	game:GetService("Players")
local IdealTarget					=	nil
local Range							=	10
local Body							=	script.Parent.Parent.Body
local MyCharacter					=	script.Parent
local closestDist					=	Range
local body_part_names = {"Head", "LeftArm", "LeftLeg", "RightArm", "RightLeg", "Torso"}

local function GetAllParts(char, func)
	local function scan(ch)
		for _, obj in pairs(ch:GetChildren()) do
			scan(obj)
			if obj:IsA("BasePart") then
				func(obj)
			end
		end
	end
	scan(char)
end
local function RemoveClothing(char)
	local function scan(ch)
		for _, obj in pairs(ch:GetChildren()) do
			scan(obj)
			if obj:IsA("Shirt") or obj:IsA("ShirtGraphic") or obj:IsA("Pants") or obj:IsA("CharacterMesh") or (obj:IsA("Decal") and obj.Name == "roblox")
			or (obj:IsA("Sparkles") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("ParticleEmitter")) then
				obj:destroy()
			end
		end
	end
	scan(char)
end
function MaterializeCharacter(char, b_color, material)
	RemoveClothing(char)
	local b_col = char:FindFirstChild("Body Colors")
	if b_col ~= nil then
		for _, nm in pairs(body_part_names) do
			b_col[nm .. "Color"] = b_color
		end
	end
	
	GetAllParts(char, function(obj)
		for _, v in pairs(obj:GetChildren()) do
			if v:IsA("SpecialMesh") then
				v.TextureId = ""
			end
		end
		obj.BrickColor = b_color
		obj.Material = material
	end)
end
function Freeze(char, hide_name)
	
	local hdv = char:FindFirstChild("Head")
	
	--set up the ragdoll
	local function scan(ch)
		for i = 1, #ch do
			scan(ch[i]:GetChildren())
			if (ch[i]:IsA("Motor6D") or ch[i]:IsA("ForceField") or ch[i].Name == "HumanoidRootPart") or (ch[i]:IsA("Weld") and ch[i].Name ~= "HeadWeld" and ch[i].Name ~= "RadioWeld") then
				ch[i]:destroy()
			end
		end
	end
	scan(char:GetChildren())
	
	local fhum = char:FindFirstChild("Humanoid")
	fhum.PlatformStand = true
	
	local Torso = char:FindFirstChild("Torso")
	if Torso then
		local Head = char:FindFirstChild("Head")
		if Head then
			local Neck = Instance.new("Weld")
			Neck.Name = "Neck"
			Neck.Part0 = Torso
			Neck.Part1 = Head
			Neck.C0 = CFrame.new(0, 1.5, 0)
			Neck.C1 = CFrame.new()
			Neck.Parent = Torso
			
			if hide_name then
				local f_head = Head:clone()
				f_head.Name = "FakeHead"
				local w = Instance.new("Weld")
				w.Part0 = Head
				w.Part1 = f_head
				w.Parent = Head
				f_head.Parent = char
				Head.Transparency = 1
			end

		end
		local Limb = char:FindFirstChild("Right Arm")
		if Limb then
			
			local get_rot = Limb.CFrame * Torso.CFrame:inverse()
			get_rot = get_rot - get_rot.p
			
			local Joint = Instance.new("Weld")
			Joint.Name = "RightShoulder"
			Joint.Part0 = Torso
			Joint.Part1 = Limb
			Joint.C0 = CFrame.new(1.5, 0.5, 0) * get_rot * CFrame.new(0, -0.5, 0)
			Joint.Parent = Torso

			local B = Instance.new("Part")
			B.TopSurface = 0
			B.BottomSurface = 0
			B.formFactor = "Symmetric"
			B.Size = Vector3.new(1, 1, 1)
			B.Transparency = 1
			B.CFrame = Limb.CFrame * CFrame.new(0, -0.5, 0)
			B.Parent = char
			local W = Instance.new("Weld")
			W.Part0 = Limb
			W.Part1 = B
			W.C0 = CFrame.new(0, -0.5, 0)
			W.Parent = Limb

		end
		local Limb = char:FindFirstChild("Left Arm")
		if Limb then
			
			local get_rot = Limb.CFrame * Torso.CFrame:inverse()
			get_rot = get_rot - get_rot.p
			
			local Joint = Instance.new("Weld")
			Joint.Name = "LeftShoulder"
			Joint.Part0 = Torso
			Joint.Part1 = Limb
			Joint.C0 = CFrame.new(-1.5, 0.5, 0) * get_rot * CFrame.new(0, -0.5, 0)
			Joint.Parent = Torso

			local B = Instance.new("Part")
			B.TopSurface = 0
			B.BottomSurface = 0
			B.formFactor = "Symmetric"
			B.Size = Vector3.new(1, 1, 1)
			B.Transparency = 1
			B.CFrame = Limb.CFrame * CFrame.new(0, -0.5, 0)
			B.Parent = char
			local W = Instance.new("Weld")
			W.Part0 = Limb
			W.Part1 = B
			W.C0 = CFrame.new(0, -0.5, 0)
			W.Parent = Limb

		end
		local Limb = char:FindFirstChild("Right Leg")
		if Limb then
			
			local get_rot = Limb.CFrame * Torso.CFrame:inverse()
			get_rot = get_rot - get_rot.p
			
			local Joint = Instance.new("Weld")
			Joint.Name = "RightHip"
			Joint.Part0 = Torso
			Joint.Part1 = Limb
			Joint.C0 = CFrame.new(0.5, -1.5, 0) * get_rot * CFrame.new(0, -0.5, 0)
			Joint.Parent = Torso

			local B = Instance.new("Part")
			B.TopSurface = 0
			B.BottomSurface = 0
			B.formFactor = "Symmetric"
			B.Size = Vector3.new(1, 1, 1)
			B.Transparency = 1
			B.CFrame = Limb.CFrame * CFrame.new(0, -0.5, 0)
			B.Parent = char
			local W = Instance.new("Weld")
			W.Part0 = Limb
			W.Part1 = B
			W.C0 = CFrame.new(0, -0.5, 0)
			W.Parent = Limb

		end
		local Limb = char:FindFirstChild("Left Leg")
		if Limb then
			
			local get_rot = Limb.CFrame * Torso.CFrame:inverse()
			get_rot = get_rot - get_rot.p
			
			local Joint = Instance.new("Weld")
			Joint.Name = "LeftHip"
			Joint.Part0 = Torso
			Joint.Part1 = Limb
			Joint.C0 = CFrame.new(-0.5, -1.5, 0) * get_rot * CFrame.new(0, -0.5, 0)
			Joint.Parent = Torso

			local B = Instance.new("Part")
			B.TopSurface = 0
			B.BottomSurface = 0
			B.formFactor = "Symmetric"
			B.Size = Vector3.new(1, 1, 1)
			B.Transparency = 1
			B.CFrame = Limb.CFrame * CFrame.new(0, -0.5, 0)
			B.Parent = char
			local W = Instance.new("Weld")
			W.Part0 = Limb
			W.Part1 = B
			W.C0 = CFrame.new(0, -0.5, 0)
			W.Parent = Limb

		end

		local Bar = Instance.new("Part")
		Bar.TopSurface = 0
		Bar.BottomSurface = 0
		Bar.formFactor = "Symmetric"
		Bar.Size = Vector3.new(1, 1, 1)
		Bar.Transparency = 1
		Bar.CFrame = Torso.CFrame * CFrame.new(0, 0.5, 0)
		Bar.Parent = char
		local Weld = Instance.new("Weld")
		Weld.Part0 = Torso
		Weld.Part1 = Bar
		Weld.C0 = CFrame.new(0, 0.5, 0)
		Weld.Parent = Torso
	end
	
	fhum.MaxHealth = 100
	fhum.Health = 1
end

function Effect(Character)
	local n=Instance.new("BoolValue",Character.Torso)
	n.Name="058EFFECT"
	Character.Humanoid.Health=1
	--Character.PlatformStand=true
	Freeze(Character,false)
	MaterializeCharacter(Character,BrickColor.new("Really white"),"Grass")
end
	
for i,v in pairs(Body:GetChildren()) do
	v.Touched:connect(function(otherPart)
		if otherPart.Parent:FindFirstChild("Humanoid") then
			if otherPart.Parent:FindFirstChild("Torso") and not otherPart.Parent.Torso:FindFirstChild("058EFFECT") then
			Effect(otherPart.Parent)
			end
		end
	end)
end

while true do
	wait()
	IdealTarget=nil
	closestDist=Range
	for i,v in pairs(game.Players:GetChildren()) do	
		if (Range and v:DistanceFromCharacter(Body.Main.Position) <= Range) and v.Character:FindFirstChild("Head") and v.Character.Humanoid.Health > 0 then
			if not v.Character.Torso:FindFirstChild("058EFFECT") then
				if (v.Character.Torso.Position - Body.Main.Position).magnitude < closestDist then	
					IdealTarget = v
					closestDist= (v.Character.Torso.Position - Body.Main.Position).magnitude 
				end
			end
		end
	end	
	if IdealTarget then
		MyCharacter.Humanoid.WalkToPoint=IdealTarget.Character.Torso.Position
	end	
end
