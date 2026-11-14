assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local hook=assert(game.ServerStorage:FindFirstChild("__BodyPrototypeRuntimePatch"))
assert(hook.Target.Value.Source==hook.After.Value,"Runtime hook changed since installation")
hook.Target.Value.Source=hook.Before.Value
assert(hook.Target.Value.Source==hook.Before.Value)
hook:Destroy()
local backup=assert(game.ServerStorage:FindFirstChild("__BodyPrototypeBackup"))
for _,entry in backup:GetChildren() do
 assert(entry.Target.Value and entry.Target.Value.Source==entry.After.Value,"Isolation source changed since installation")
end
local count=0
for _,entry in backup:GetChildren() do entry.Target.Value.Source=entry.Before.Value;assert(entry.Target.Value.Source==entry.Before.Value);count+=1 end
backup:Destroy()
game.ReplicatedStorage.__BodyPrototypeMemory:Destroy()
return {sourcesRestored=count,hookRemoved=true}
