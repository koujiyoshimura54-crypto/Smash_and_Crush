-- Host-side launcher. Run in canonical Edit only, after baseline Source was copied.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
assert(game.ServerStorage:FindFirstChild("__W1BalanceBackup"),"Memory isolation required")
assert(not game.ServerStorage:FindFirstChild("__W1BalanceAfterQueue"))
local queue=Instance.new("Folder");queue.Name="__W1BalanceAfterQueue";queue.Parent=game.ServerStorage
task.spawn(function()
 local before=game.ServerStorage:FindFirstChild("__W1BalanceBeforeQueue")
 while before and not before:GetAttribute("Finished")do task.wait(1)end
 for _,cohort in {{Label="1",Repetition=1,Players=3},{Label="2_3",Repetition=2,Players=6},{Label="4",Repetition=4,Players=3,Activity=true}}do
  local q=game.ReplicatedStorage.__W1BalanceRoute
  q:SetAttribute("Variant","After");q:SetAttribute("Repetition",cohort.Repetition)
  q:SetAttribute("ReportRepetition",nil);q:SetAttribute("ExpectedPlayers",cohort.Players)
  q:SetAttribute("TrackActivity",cohort.Activity==true);q:SetAttribute("HoldOnComplete",false)
  local folder=Instance.new("Folder");folder.Name="__W1BalanceResultAfter"..cohort.Label;folder.Parent=game.ServerStorage
  queue:SetAttribute("Active",cohort.Label)
  local ok,result=pcall(function()return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(3,{})end)
  folder:SetAttribute("OK",ok)
  if ok and type(result)=="table"and type(result.Chunks)=="table"then
   for i,chunk in result.Chunks do local v=Instance.new("StringValue");v.Name="Chunk"..i;v.Value=chunk;v.Parent=folder end
   folder:SetAttribute("Chunks",#result.Chunks)
  else
   local v=Instance.new("StringValue");v.Name="Failure";v.Value=tostring(result);v.Parent=folder
  end
  folder:SetAttribute("Finished",true)
  if not ok then queue:SetAttribute("Error",tostring(result));break end
 end
 queue:SetAttribute("Finished",true)
end)
return "After queue scheduled; no Save/Publish"
