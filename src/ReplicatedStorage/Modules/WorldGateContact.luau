-- One oriented contact test shared by the authority and isolated tests.
-- No Touched latch: the server re-evaluates native character body bounds.
local M={}
function M.Gate(world)
 if world==1 then return workspace:FindFirstChild("World2Gate") end
 local map=workspace:FindFirstChild("World2Map")
 local area=map and map:FindFirstChild("TrainingArea")
 return area and area:FindFirstChild("World1ReturnGate")
end
function M.Wall(world)
 local gate=M.Gate(world)
 return gate and gate:FindFirstChild("WorldSelectionWall")
end
function M.Touching(wall,character,padding)
 if not wall or not wall:IsA("BasePart") or not character then return false end
 local half=wall.Size*.5+Vector3.one*(padding or .25)
 for _,part in character:GetChildren() do
  -- Ignore tools/accessories and gameplay-only attack volumes.
  if part:IsA("BasePart") and (part.Name=="HumanoidRootPart" or part.Name=="Head"
   or part.Name:find("Torso") or part.Name:find("Arm") or part.Name:find("Hand")
   or part.Name:find("Leg") or part.Name:find("Foot")) then
   local cf=wall.CFrame:ToObjectSpace(part.CFrame)
   local r,u,z=cf.RightVector,cf.UpVector,cf.LookVector
   local h=part.Size*.5
   local extent=Vector3.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(z.X)*h.Z,
    math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(z.Y)*h.Z,
    math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(z.Z)*h.Z)
   local p=cf.Position
   if math.abs(p.X)<=half.X+extent.X and math.abs(p.Y)<=half.Y+extent.Y and math.abs(p.Z)<=half.Z+extent.Z then return true end
  end
 end
 return false
end
return M
