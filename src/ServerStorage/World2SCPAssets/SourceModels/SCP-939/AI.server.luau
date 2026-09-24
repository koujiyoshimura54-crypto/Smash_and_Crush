--DuruTeru
wait(1)
--[[

____________________________________________________________________________________________________________________
																					i smell leik beef
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-	
____________________________________________________________________________________________________________________
                      ___       ___                                            
                     (   )     (   )      .-.                                  
    .--.      .--.    | |_      | |_     ( __)  ___ .-.     .--.       .--.    
  /  _  \    /    \  (   __)   (   __)   (''") (   )   \   /    \    /  _  \   
 . .' `. ;  |  .-. ;  | |       | |       | |   |  .-. .  ;  ,-. '  . .' `. ;  
 | '   | |  |  | | |  | | ___   | | ___   | |   | |  | |  | |  | |  | '   | |  
 _\_`.(___) |  |/  |  | |(   )  | |(   )  | |   | |  | |  | |  | |  _\_`.(___) 
(   ). '.   |  ' _.'  | | | |   | | | |   | |   | |  | |  | |  | | (   ). '.   
 | |  `\ |  |  .'.-.  | ' | |   | ' | |   | |   | |  | |  | '  | |  | |  `\ |  
 ; '._,' '  '  `-' /  ' `-' ;   ' `-' ;   | |   | |  | |  '  `-' |  ; '._,' '  
  '.___.'    `.__.'    `.__.     `.__.   (___) (___)(___)  `.__. |   '.___.'   
                                                           ( `-' ;             
                                                            `.__.              
____________________________________________________________________________________________________________________

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-	
____________________________________________________________________________________________________________________

--]]	
	
	
local SearchDistance = 	100 	-- How far a player can be before it detects you

local ZombieDamage = 	25		-- How much damage the Zombie inficts towards the player
local DamageWait = 		2		-- How many seconds to wait before it can damage the player again

local WanderX, WanderZ = 30, 30
-- 	How many studs the zombie can wander on the x and z axis in studs ; 0, 0 to stay still

--[[	
____________________________________________________________________________________________________________________
 
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-	
____________________________________________________________________________________________________________________

--]]


function getHumanoid(model)
	for _, v in pairs(model:GetChildren())do
		if v:IsA'Humanoid' then
			return v
		end
	end
end


local zombie = script.Parent
local human = getHumanoid(zombie)
local hroot = zombie.HumanoidRootPart
local zspeed = hroot.Velocity.magnitude
local head = zombie:FindFirstChild'Head'
local vars = script.vars

local pfs = game:GetService("PathfindingService")
local players = game:GetService('Players')

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local path
local waypoint

local chaseName = nil

function GetTorso(part)
	local chars = game.Workspace:GetChildren()
	local chaseRoot = nil
	local chaseTorso = nil
	local chasePlr = nil
	local chaseHuman = nil
	local mag = SearchDistance
	for i = 1, #chars do
		chasePlr = chars[i]
		if chasePlr:IsA'Model' and chasePlr ~= zombie then
			chaseHuman = getHumanoid(chasePlr)
			chaseRoot = chasePlr:FindFirstChild'HumanoidRootPart'
			if chaseRoot ~= nil and chaseHuman ~= nil and chaseHuman.Health > 0 and chaseHuman.Name ~= "Zombie" then
				if (chaseRoot.Position - part).magnitude < mag then
					chaseName = chasePlr.Name
					chaseTorso = chaseRoot
					mag = (chaseRoot.Position - part).magnitude
				end
			end
		end
	end
	return chaseTorso
end

function GetPlayersBodyParts(t)
	local torso = t
	if torso then
		local figure = torso.Parent
		for _, v in pairs(figure:GetChildren())do
			if v:IsA'Part' then
				return v.Name
			end
		end
	else
		return "HumanoidRootPart"
	end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local damagetime
local damagedb = false

for _, zambieparts in pairs(zombie:GetChildren())do
	if zambieparts:IsA'Part' and human.Health > 0 then
		zambieparts.Touched:connect(function(p)
			if p.Parent.Name == chaseName and p.Parent.Name ~= zombie.Name and not damagedb then -- damage
				damagedb = true
				damagetime = time()
				local enemy = p.Parent
				local enemyhuman = getHumanoid(enemy)
				vars.Attacking.Value = true
				enemyhuman:TakeDamage(ZombieDamage)
				vars.Attacking.Value = false
				while wait() do
					if damagetime ~= nil and time() >= (damagetime + DamageWait) then
						damagedb = false
						damagetime = nil
					end
				end
			end
		end)
	end
end

-- wandering 
spawn(function()
	while vars.Wandering.Value == false and human.Health > 0 do	
		vars.Chasing.Value = false	
		vars.Wandering.Value = true
		local desgx, desgz = hroot.Position.x+math.random(-WanderX,WanderX), hroot.Position.z+math.random(-WanderZ,WanderZ)
		local function checkw(t)
			local ci = 3
			if ci > #t then
				ci = 3
			end
			if t[ci] == nil and ci < #t then
				repeat ci = ci + 1 wait() until t[ci] ~= nil
				return Vector3.new(1,0,0) + t[ci]
			else
				ci = 3
				return t[ci]
			end
		end
		
		path = pfs:FindPathAsync(hroot.Position, Vector3.new(desgx, 0, desgz))
		waypoint = path:GetWaypoints()
		local connection;
		
		local direct = Vector3.FromNormalId(Enum.NormalId.Front)
		local ncf = hroot.CFrame * CFrame.new(direct)
		direct = ncf.p.unit
		local rootr = Ray.new(hroot.Position, direct)
		local phit, ppos = game.Workspace:FindPartOnRay(rootr, hroot)
		
		if path and waypoint or checkw(waypoint) then
			if checkw(waypoint) ~= nil and checkw(waypoint).Action == Enum.PathWaypointAction.Walk then
				human:MoveTo( checkw(waypoint).Position )
				human.Jump = false
			end
			
			if checkw(waypoint) ~= nil and checkw(waypoint).Action == Enum.PathWaypointAction.Jump then
				connection = human.Changed:connect(function()
					human.Jump = true
				end)
				human:MoveTo( waypoint[4].Position )
			else
				human.Jump = false
			end
			
			if connection then
				connection:Disconnect()
			end
			
		else
			for i = 3, #waypoint do
				human:MoveTo( waypoint[i].Position )	
			end
		end
		wait(math.random(4,6))
		vars.Wandering.Value = false
	end
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

while wait() do
	local nrstt = GetTorso(hroot.Position)
	if nrstt ~= nil and human.Health > 0 then -- if player detected	
		vars.Wandering.Value = false
		vars.Chasing.Value = true
		local function checkw(t)
			local ci = 3
			if ci > #t then
				ci = 3
			end
			if t[ci] == nil and ci < #t then
				repeat ci = ci + 1 wait() until t[ci] ~= nil
				return Vector3.new(1,0,0) + t[ci]
			else
				ci = 3
				return t[ci]
			end
		end
		
		path = pfs:FindPathAsync(hroot.Position, nrstt.Position)
		waypoint = path:GetWaypoints()
		local connection;
		
		local direct = Vector3.FromNormalId(Enum.NormalId.Front)
		local ncf = hroot.CFrame * CFrame.new(direct)
		direct = ncf.p.unit
		local rootr = Ray.new(hroot.Position, direct)
		local phit, ppos = game.Workspace:FindPartOnRay(rootr, hroot)
		
		if path and waypoint or checkw(waypoint) then
			if checkw(waypoint) ~= nil and checkw(waypoint).Action == Enum.PathWaypointAction.Walk then
				human:MoveTo( checkw(waypoint).Position )
				human.Jump = false
			end
			
			if checkw(waypoint) ~= nil and checkw(waypoint).Action == Enum.PathWaypointAction.Jump then
				connection = human.Changed:connect(function()
					human.Jump = true
				end)
				human:MoveTo( waypoint[4].Position )
			else
				human.Jump = false
			end
			
			hroot.Touched:connect(function(p)
				local bodypartnames = GetPlayersBodyParts(nrstt)
				if p:IsA'Part' and not p.Name == bodypartnames and phit and phit.Name ~= bodypartnames and phit:IsA'Part' and rootr:Distance(phit.Position) < 5 then
					connection = human.Changed:connect(function()
						human.Jump = true
					end)
				else
					human.Jump = false
				end
			end)
			
			if connection then
				connection:Disconnect()
			end
			
		else
			for i = 3, #waypoint do
				human:MoveTo( waypoint[i].Position )	
			end
		end
		path = nil
		waypoint = nil
	elseif nrstt == nil then -- if player not detected
		vars.Wandering.Value = false
		vars.Chasing.Value = false
		CchaseName = nil
		path = nil
		waypoint = nil
		human.MoveToFinished:Wait()
	end
end

-- Base script for NPC enemy movement,
-- still a work in progress