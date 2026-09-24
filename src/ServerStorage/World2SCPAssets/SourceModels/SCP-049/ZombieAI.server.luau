
local CanSee = false
local Pathing = false

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


function FindClosestTarget()
	local Character = nil
	local playerhumanoid = nil
	local playerhumanoidrootpart = nil
	local SearchDistance = 200
	local Players = game:GetService("Players")
	local GetChildren = workspace:GetChildren()
	for i, Child in pairs (GetChildren) do
		if Child  and Child:FindFirstChildWhichIsA("Humanoid") and Child:FindFirstChild("HumanoidRootPart") and not Child:FindFirstChild("SCPDetection")  and Child ~= script.Parent  and not NotTargets[Child.Name] then
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











	function raycast(Spos,vec,currentdist)
local hit2,pos2=game.Workspace:FindPartOnRay(Ray.new(Spos+(vec*.05),vec*currentdist),script.Parent)
if hit2~=nil and pos2 then
if hit2.Name=="Handle" and not hit2.CanCollide or string.sub(hit2.Name,1,6)=="Effect"and not hit2.CanCollide then
local currentdist=currentdist-(pos2-Spos).magnitude;
return raycast(pos2,vec,currentdist);
end;
end;
return hit2,pos2;
end;
function RayCast(Position,Direction,MaxDistance,IgnoreList)
return game:GetService("Workspace"):FindPartOnRayWithIgnoreList(Ray.new(Position,Direction.unit*(MaxDistance or 999.999)),IgnoreList);
end;		
	
	
script.Parent:FindFirstChildWhichIsA("Humanoid").Died:Connect(function()
	script.Parent:Destroy()
end)




while wait(0) do
	


	
	local GetTarget, PlayerHumanoid, PlayerHumanoidRootPart = FindClosestTarget()

if GetTarget   and script.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
	
	local TargetTorso = GetTarget:FindFirstChild("HumanoidRootPart")
		local PlayerHumanoidRootPart = GetTarget:FindFirstChild("HumanoidRootPart")
		local TargetHumanoid = GetTarget:FindFirstChildWhichIsA("Humanoid")
		
		local mag = (script.Parent.HumanoidRootPart.Position - TargetTorso.Position).Magnitude 
		
			if mag < 5 then
				
			TargetHumanoid:TakeDamage(25)
			script.Parent.HumanoidRootPart.Hit1:Play()
			wait(0.3)

			end
			local hit,pos=raycast(script.Parent.HumanoidRootPart.Position,(PlayerHumanoidRootPart.Position-script.Parent.HumanoidRootPart.Position).unit,500)
if hit and hit.Parent and hit.Parent.ClassName=="Model"and hit.Parent:FindFirstChild("HumanoidRootPart")and hit.Parent:FindFirstChild("Head")then
CanSee=true;
else
CanSee=false;
end;
			
			
	if CanSee then
script.Parent:FindFirstChildWhichIsA("Humanoid"):MoveTo(PlayerHumanoidRootPart.Position+(PlayerHumanoidRootPart.Position-script.Parent.HumanoidRootPart.Position).unit*2,game:GetService("Workspace"):FindFirstChild("Terrain"));
end;
if not CanSee and not Pathing then

Pathing=true;
local RenderedPath=game:GetService("PathfindingService"):ComputeRawPathAsync(script.Parent.HumanoidRootPart.Position,PlayerHumanoidRootPart.Position,500);
local RenderedPathCoordinates=RenderedPath:GetPointCoordinates();
for _=1,#RenderedPathCoordinates do
if not CanSee then
local Point=RenderedPathCoordinates[_];
local PathTimer=0;
repeat wait(0);
script.Parent:FindFirstChildWhichIsA("Humanoid"):MoveTo(Point);PathTimer=PathTimer+1;
if PathTimer>15 or CanSee then 
break;
end;
until(script.Parent.HumanoidRootPart.Position-Point).Magnitude<5 or PathTimer>15 or CanSee;
if PathTimer>15 or CanSee then 
break;
end;
end;
end;
Pathing=false;

end;		
		
		
		
		
	end	

end
