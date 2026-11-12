assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local backup=game.ServerStorage:FindFirstChild("__W1BalanceBackup")
assert(backup,"Missing exact isolation backup")
for _,entry in backup:GetChildren()do
 local target=entry.Target.Value
 assert(target and target.Source==entry.After.Value,"Changed since installed: "..tostring(target))
end
local restored=0
for _,entry in backup:GetChildren()do entry.Target.Value.Source=entry.Before.Value;restored+=1 end
backup:Destroy()
game.ReplicatedStorage.__W1BalanceMemory:Destroy()
return {Restored=restored}
