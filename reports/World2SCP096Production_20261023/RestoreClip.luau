-- Recovery helper only; not installed in the game. Pass decoded BodyClips/*.json.
-- Existing clips are never overwritten. Original imported source clips remain intact.
return function(parent,data)
 assert(not game:GetService('RunService'):IsRunning(),'Edit only')
 assert(not parent:FindFirstChild(data.Name),'Clip already exists; inspect it instead of overwriting')
 local sequence=Instance.new('KeyframeSequence')
 sequence.Name=data.Name;sequence.Loop=data.Loop;sequence.Priority=Enum.AnimationPriority[data.Priority]
 for name,value in data.Attributes do sequence:SetAttribute(name,value) end
 local function pose(row)
  local p=Instance.new('Pose');p.Name=row.Name;p.Weight=row.Weight
  p.CFrame=row.CFrame and CFrame.new(table.unpack(row.CFrame)) or CFrame.identity
  p.EasingStyle=Enum.PoseEasingStyle[row.EasingStyle];p.EasingDirection=Enum.PoseEasingDirection[row.EasingDirection]
  for _,child in row.Children do p:AddSubPose(pose(child)) end
  return p
 end
 for _,row in data.Frames do
  local frame=Instance.new('Keyframe');frame.Name=row.Name;frame.Time=row.Time
  for _,p in row.Poses do frame:AddPose(pose(p)) end
  for _,m in row.Markers do
   local marker=Instance.new('KeyframeMarker');marker.Name=m.Name;marker.Value=m.Value;frame:AddMarker(marker)
  end
  sequence:AddKeyframe(frame)
 end
 sequence.Parent=parent
 return sequence
end
