assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local b=game.ServerStorage:FindFirstChild("__EarlyQABackup");local restored=0
if b then
 for _,v in b:GetChildren() do assert(v.Target.Value and v.Target.Value.Source==v.After.Value,"Unexpected edit: "..v.Name) end
 for _,v in b:GetChildren() do v.Target.Value.Source=v.Before.Value;restored+=1 end
 b:Destroy()
end
local mem=game.ReplicatedStorage:FindFirstChild("__EarlyQAMemory");if mem then mem:Destroy() end
local leftovers={}
for _,v in game:GetDescendants() do if v.Name:find("__EarlyQA",1,true) then table.insert(leftovers,v:GetFullName()) end end
return {Restored=restored,Leftovers=leftovers}
