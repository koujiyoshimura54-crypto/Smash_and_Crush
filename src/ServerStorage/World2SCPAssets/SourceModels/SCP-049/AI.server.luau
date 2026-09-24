local heartbeat = game:GetService("RunService").Heartbeat
local NotTargets = {
	["SCP-173"] = true, 
	["SCP-023"] = true, 
	["SCP-457"] = true, 
	["SCP-096"] = true, 
	["SCP-106"] = true,
	["SCP-049-2"] = true,
	["SCP-049"] = true,
	["SCP-280"] = true
}    -- Add more non targeted names here if you want

local CanSee = false
local Pathing = false
local talking = script.Parent.Talking.Value
local radnum = math.random(1,10000)
math.randomseed(radnum)
local Arm = script.Parent.Humanoid:LoadAnimation(script.Parent.ArmOut)
Arm.Looped = true
function FindClosestTarget()
	local Character = nil
	local playerhumanoid = nil
	local playerhumanoidrootpart = nil
	local SearchDistance = 200
	local Players = game:GetService("Players")
	local GetChildren = workspace:GetChildren()
	for i, Child in pairs (GetChildren) do
		if Child  and Child:FindFirstChildWhichIsA("Humanoid") and not Child:FindFirstChild("SCPDetection") and Child:FindFirstChild("HumanoidRootPart") and Child ~= script.Parent  and not NotTargets[Child.Name] then
			local PlayerHumanoid = Child:FindFirstChildWhichIsA("Humanoid")
			local PlayerHumanoidRootPart = Child:FindFirstChild("HumanoidRootPart")
			if  PlayerHumanoid  and PlayerHumanoidRootPart   and PlayerHumanoid.Health > 0 and (script.Parent.HumanoidRootPart.Position - PlayerHumanoidRootPart.Position).Magnitude <= SearchDistance then
				Character = Child
				playerhumanoidrootpart = PlayerHumanoidRootPart
				playerhumanoid = PlayerHumanoid
				SearchDistance = (script.Parent.HumanoidRootPart.Position - PlayerHumanoidRootPart.Position).Magnitude
			end
		end
	end
	return Character, playerhumanoid,playerhumanoidrootpart
end

function canSee(subject,viewer)
if (not subject) or (not viewer) then return false end
local sh = subject:findFirstChild("Head")
local vh = viewer:findFirstChild("Head")
if (not sh) or (not vh) then return false end
local vec = sh.Position - vh.Position


local ray = Ray.new(vh.Position,vec.unit*200)
local por = workspace.FindPartOnRay(workspace,ray,viewer,false)
return (por == nil) or (por:IsDescendantOf(subject))


end


function wander(positione)
	while wait(0) do
		CanSee = false
			local GetTarget, PlayerHumanoid, PlayerHumanoidRootPart = FindClosestTarget()
			if Arm.IsPlaying == true then Arm:Stop()  end
	local pfs = game:GetService("PathfindingService")
		local HumanoidRootPart=script.Parent.HumanoidRootPart
		local Humanoid = script.Parent.Humanoid
	path = pfs:FindPathAsync(HumanoidRootPart.Position, positione)
		waypoint = path:GetWaypoints()
		oldpoints = waypoint
		local connection;
		local function checkw(t)
			local ci = 3
			if ci > #t then
				ci = 3
			end
			if t[ci] == nil and ci < #t then
				repeat
					ci = ci + 1
					wait()
				until t[ci] ~= nil
				return Vector3.new(1, 0, 0) + t[ci]
			else
				ci = 3
				return t[ci]
			end
		end
		
	 local magn = (HumanoidRootPart.Position-positione).Magnitude
	
		local direct = Vector3.FromNormalId(Enum.NormalId.Front)
		local ncf = HumanoidRootPart.CFrame * CFrame.new(direct)
		direct = ncf.p.unit
		local rootr = Ray.new(HumanoidRootPart.Position, direct)
		local phit, ppos = game.Workspace:FindPartOnRay(rootr, HumanoidRootPart)
		
		if path and waypoint or checkw(waypoint) then
			if checkw(waypoint) ~= nil and checkw(waypoint).Action == Enum.PathWaypointAction.Walk then
				Humanoid:MoveTo( checkw(waypoint).Position )
				Humanoid.Jump = false
				
			end
			if magn < 5 or path.Status == Enum.PathStatus.NoPath then
			local desgx, desgz = script.Parent.HumanoidRootPart.Position.X + math.random(-50, 50), script.Parent.HumanoidRootPart.Position.Z + math.random(-50, 50)
			 pos = Vector3.new(desgx, 0, desgz)
			wander(pos)
		break
	elseif GetTarget then
		break
		
			end
		else
		local desgx, desgz = script.Parent.HumanoidRootPart.Position.X + math.random(-50, 50), script.Parent.HumanoidRootPart.Position.Z + math.random(-50, 50)
			 pos = Vector3.new(desgx, 0, desgz)
			wander(pos)
		break
		end
		
		end
end




function talk(state)
	if state == "wandering" and talking == false then
			script.Parent.HumanoidRootPart["Wander" .. math.random(1,2)]:Play()
		talking = true
	elseif state == "detected" and talking == false then
		script.Parent.UpperTorso["Notice" .. math.random(1,6)]:Play()
		talking = true
		elseif state == "kil" and talking == false then
		script.Parent.HumanoidRootPart.DeathTalk1:Play()
		talking = true 
	end
end





while wait(0) do
	


	
	local GetTarget, PlayerHumanoid, PlayerHumanoidRootPart = FindClosestTarget()

if GetTarget   and script.Parent.Humanoid.Health > 0 then

	local TargetTorso = GetTarget:FindFirstChild("HumanoidRootPart")
		local PlayerHumanoidRootPart = GetTarget:FindFirstChild("HumanoidRootPart")
		local TargetHumanoid = GetTarget:FindFirstChildWhichIsA("Humanoid")
		
		local mag = (script.Parent.HumanoidRootPart.Position - TargetTorso.Position).Magnitude 
		
			if mag <5   then
				Arm:Stop()
				GetTarget.Archivable = true
				if script.Parent.Talking.Value == false then
					script.Parent.HumanoidRootPart.DeathTalk1:Play()
				end
				script.Parent.HumanoidRootPart.Kill:Play()
				talk("kil")
				local zombie = GetTarget:Clone()
				for _,parts in pairs(zombie:GetDescendants()) do
					if parts:IsA("Script")  or parts:IsA("Tool") then parts:Destroy() end
				end
				local AI = script.Parent.ZombieAI:Clone()
				GetTarget:FindFirstChildWhichIsA("Humanoid").PlatformStand = true
				wait(3)
				for _,parts in pairs(GetTarget:GetDescendants()) do
					if parts:IsA("Part") then parts.Transparency = 1 end
				end
				AI.Disabled = false
				AI.Parent = zombie
				if zombie:FindFirstChild("Animate") then zombie:FindFirstChild("Animate"):Destroy() end
				if zombie:FindFirstChild("Head") then
				for _,decals in pairs (zombie.Head:GetChildren()) do
					if decals and decals:IsA("Decal") then
						decals:Destroy()
					end
				end
				local NewFace = Instance.new("Decal",zombie.Head)
				NewFace.Texture = "http://www.roblox.com/asset/?id=133667125"
				NewFace.Face  = "Front"
				end
				TargetHumanoid:TakeDamage(TargetHumanoid.Health)
				local  breth = script.Parent.Breathing:Clone()
				breth:Play()
				zombie:FindFirstChildWhichIsA("Humanoid").WalkSpeed = 9
				breth.Parent = zombie.Head
				breth.Name = "Breathing"
				local hit1 =   script.Parent.Hit1:Clone()
				hit1.Parent = zombie.HumanoidRootPart
		
				local hit2 =   script.Parent.Hit2:Clone()
				hit2.Parent = zombie.HumanoidRootPart
				if zombie:FindFirstChildWhichIsA("Humanoid").RigType == Enum.HumanoidRigType.R15 then
					local anim = script.Parent.R15Animate:Clone()
					anim.Disabled = false anim.Parent = zombie
				elseif zombie:FindFirstChildWhichIsA("Humanoid").RigType == Enum.HumanoidRigType.R6 then
					local anim = script.Parent.R6Animate:Clone()
					anim.Disabled = false anim.Parent = zombie
				end
             zombie.Parent = workspace
				zombie.Name = "SCP-049-2"
			end
			
	
				if mag < 29 and TargetHumanoid.PlatformStand == false and TargetHumanoid.Health > 0 then
			if Arm.IsPlaying == false then Arm:Play()  end
		else
			if Arm.IsPlaying == true then Arm:Stop()  end
		end
		
				
				
		
			local function checkw(t)
			local ci = 3
			if ci > #t then
				ci = 3
			end
			if t[ci] == nil and ci < #t then
				repeat
					ci = ci + 1
					wait()
				until t[ci] ~= nil
				return Vector3.new(1, 0, 0) + t[ci]
			else
				ci = 3
				return t[ci]
			end
		end
		
		local pfs = game:GetService("PathfindingService")
		local HumanoidRootPart=script.Parent.HumanoidRootPart
		local Humanoid = script.Parent.Humanoid
		path = pfs:FindPathAsync(HumanoidRootPart.Position, PlayerHumanoidRootPart.Position)
		waypoint = path:GetWaypoints()
		oldpoints = waypoint
		local connection;
		
		local direct = Vector3.FromNormalId(Enum.NormalId.Front)
		local ncf = HumanoidRootPart.CFrame * CFrame.new(direct)
		direct = ncf.p.unit
		local rootr = Ray.new(HumanoidRootPart.Position, direct)
		local phit, ppos = game.Workspace:FindPartOnRay(rootr, HumanoidRootPart)
		
				if canSee(script.Parent,GetTarget) and CanSee == false and mag < 90 and script.Parent.Talking.Value == false then
					CanSee = true
					script.Parent.UpperTorso["Notice"..math.random(1,6)]:Play()
				end
				
		if path and waypoint or checkw(waypoint) then
			if checkw(waypoint) ~= nil and checkw(waypoint).Action == Enum.PathWaypointAction.Walk then
				Humanoid:MoveTo( checkw(waypoint).Position )
				Humanoid.Jump = false
			
				
			end
		end
		
			
			
			

		else
				local desgx, desgz = script.Parent.HumanoidRootPart.Position.X + math.random(-100, 100), script.Parent.HumanoidRootPart.Position.Z + math.random(-100, 100)
			 pos = Vector3.new(desgx, 0, desgz)
			wander(pos)
		if Arm.IsPlaying == true then Arm:Stop()  end
	end	

end
