local p=game.Players:GetPlayers()[1];local c=p.Character;local t=workspace.Treadmills.Normal01
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={t};params.RespectCanCollide=true
local hit=workspace:Raycast(t.Area.CFrame:PointToWorldSpace(Vector3.new(0,20,3)),Vector3.new(0,-50,0),params);assert(hit)
local before=p:GetAttribute("Strength");local start=os.clock()
c:PivotTo(CFrame.new(hit.Position+Vector3.new(0,c.Humanoid.HipHeight+c.HumanoidRootPart.Size.Y/2+.15,0))*c.HumanoidRootPart.CFrame.Rotation)
local samples={}
for i=1,8 do task.wait(.5);table.insert(samples,{seconds=os.clock()-start,strength=p:GetAttribute("Strength"),training=p:GetAttribute("IsTraining"),level=p:GetAttribute("Level")})end
local out={before=before,samples=samples,ratio=c:GetAttribute("BodyPrototypeRatio"),after=p:GetAttribute("Strength")}
c:PivotTo(CFrame.new(287.86,9,13))
script:SetAttribute("Result",game.HttpService:JSONEncode(out))
