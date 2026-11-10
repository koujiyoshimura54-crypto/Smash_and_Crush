-- Run in Edit after the scoped Source update. Reuses the authored World1 artwork.
-- Each World2 station carries its own template, so distant World1 streaming is irrelevant.
assert(game.PlaceId==126576845524886)
local Config=require(game.ReplicatedStorage.Config.TreadmillConfig)
local Heading=require(game.ReplicatedStorage.Modules.TreadmillStationHeading)
local folder=workspace.World2Map.TrainingArea.TreadmillDisplays
local changed={}
for _,model in ipairs(folder:GetChildren()) do
 local entry=Config.GetForModel(model)
 local board=model:FindFirstChild("StationBillboard")
 if entry and board and (entry.RequiresPremium or (entry.RequiredRebirth or 0)>0) and not board:FindFirstChild("Rebirth") then
  local donor=workspace.Treadmills[entry.RequiresPremium and "Diamond01" or "Iron01"].BillboardGui
  local group=donor.Rebirth:Clone()
  group.Parent=board
  changed[#changed+1]=group:GetFullName()
 end
end
-- The same module owns both the Edit templates and the client refresh.
for _,root in ipairs({workspace.Treadmills,folder}) do
 for _,model in ipairs(root:GetChildren()) do
  local entry=Config.GetForModel(model)
  local board=model:FindFirstChild("BillboardGui") or model:FindFirstChild("StationBillboard")
  if entry and board then
   Heading.Apply(board,entry,Config.WorldForModel(model))
   changed[#changed+1]=board:GetFullName()
  end
 end
end
return changed
