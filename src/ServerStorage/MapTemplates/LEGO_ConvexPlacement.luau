local Placement = {}

local function isConvexPart(instance)
	return instance:IsA("BasePart")
		and instance.Name ~= "WallBody"
		and instance.Name ~= "TopEdge"
end

function Placement.GetConvexTemplates(template)
	local result = {}
	if not template then
		return result
	end
	for _, instance in ipairs(template:GetDescendants()) do
		if isConvexPart(instance) then
			table.insert(result, instance)
		end
	end
	return result
end

function Placement.CloneConvexPart(templatePart, parent, targetCFrame, name)
	assert(isConvexPart(templatePart), "templatePart must be a convex BasePart")
	local clone = templatePart:Clone()
	clone.Name = name or templatePart.Name
	clone.CFrame = targetCFrame or templatePart.CFrame
	-- Preserve the source shape and Size; only placement is changed.
	clone.Size = templatePart.Size
	clone.Anchored = true
	clone.CanCollide = false
	clone.CanTouch = false
	clone.CanQuery = false
	clone.Parent = parent
	return clone
end

function Placement.PlaceWallConvex(templatePart, parent, targetCFrame, name)
	return Placement.CloneConvexPart(templatePart, parent, targetCFrame, name)
end

function Placement.PlaceFloorConvex(templatePart, parent, targetCFrame, name)
	return Placement.CloneConvexPart(templatePart, parent, targetCFrame, name)
end

function Placement.PlaceWallGrid(templatePart, parent, wall, name, axis, normal, angle, pitch)
	assert(axis == "X" or axis == "Z", "axis must be X or Z")
	pitch = pitch or 1.85
	local size = templatePart.Size.X
	local protrude = templatePart.Size.Z
	local length = axis == "X" and wall.Size.X or wall.Size.Z
	local columns = math.floor((length - size) / pitch) + 1
	local rows = math.floor((wall.Size.Y - templatePart.Size.Y) / pitch) + 1
	local columnSpan = (columns - 1) * pitch + size
	local rowSpan = (rows - 1) * pitch + templatePart.Size.Y
	local count = 0

	for row = 0, rows - 1 do
		local y = -rowSpan / 2 + row * pitch + templatePart.Size.Y / 2
		for column = 0, columns - 1 do
			local along = -columnSpan / 2 + column * pitch + size / 2
			local offset = axis == "X"
				and Vector3.new(along, y, normal * (wall.Size.Z / 2 + protrude / 2))
				or Vector3.new(normal * (wall.Size.X / 2 + protrude / 2), y, along)
			local targetCFrame = wall.CFrame * CFrame.new(offset) * CFrame.Angles(0, angle, 0)
			Placement.CloneConvexPart(templatePart, parent, targetCFrame, name .. "_" .. row .. "_" .. column)
			count += 1
		end
	end

	return count, columns, rows
end

return Placement