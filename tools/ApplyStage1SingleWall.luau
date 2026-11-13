-- Edit-only, explicitly requested Phase 2 map change. No Save or Publish.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857)
assert(not game:GetService('RunService'):IsRunning(),'Edit only')
local stage=workspace.GeneratedMap.BattleCorridor.Stage01
local first=assert(stage['Stage1.1']:FindFirstChild('Wall'))
assert(first:IsA('BasePart') and math.abs(first.Position.Z-97)<.01,'Unexpected first wall; inspect before editing')
local boss=assert(stage:FindFirstChild('Stage1.5'))
assert(boss:FindFirstChild('Floor') and boss:FindFirstChild('EnemySpawn'),'Keep authored boss arena')
local walls={}
for index=2,4 do
 local section=assert(stage:FindFirstChild('Stage1.'..index))
 local wall=section:FindFirstChild('Wall')
 if wall then
  assert(wall:IsA('BasePart') and math.abs(wall.Position.Z-(87+index*10))<.01,'Unexpected removed wall')
  table.insert(walls,wall)
 end
end
local removed={}
for _,wall in walls do table.insert(removed,wall:GetFullName());wall:Destroy() end
-- Empty section Models, all floors/paths/reward pads/boundaries stay untouched.
return {Removed=removed,Retained=first:GetFullName(),Boss=boss:GetFullName()}
