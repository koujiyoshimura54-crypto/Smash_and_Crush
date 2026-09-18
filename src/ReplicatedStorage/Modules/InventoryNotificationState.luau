local RS=game:GetService("ReplicatedStorage")
local remote=RS:WaitForChild("Remotes"):WaitForChild("InventoryNotificationState")
local M={}
local seen={Dumbbells={},DumbbellBuy={},Items={},Aura={},Speed={}}
local loaded=false
local changed=Instance.new("BindableEvent")
M.Changed=changed.Event
local function apply(value)
 if typeof(value)~="table" then return false end
 for _,tab in ipairs({"Dumbbells","DumbbellBuy","Items","Aura","Speed"}) do
  -- Seen is monotonic. Concurrent stage acknowledgements may return older snapshots.
  if typeof(value[tab])=="table" then
   for id,valueSeen in pairs(value[tab]) do if valueSeen==true then seen[tab][id]=true end end
  end
 end
 loaded=true
 changed:Fire()
 return true
end
function M.Load()
 if loaded then return true end
 local ok,result=pcall(function() return remote:InvokeServer("Get") end)
 return ok and typeof(result)=="table" and result.Success==true and apply(result.Seen)
end
function M.IsSeen(tab,id)
 return loaded and seen[tab] and seen[tab][id]==true
end
function M.MarkSeen(tab,ids)
 if not loaded and not M.Load() then return false end
 local pending={}
 for _,id in ipairs(ids) do
  if typeof(id)=="string" and id~="" and not M.IsSeen(tab,id) then table.insert(pending,id) end
 end
 if #pending==0 then return true end
 for _,id in ipairs(pending) do seen[tab][id]=true end
 changed:Fire()
 task.spawn(function()
  local ok,result=pcall(function() return remote:InvokeServer("MarkSeen",tab,pending) end)
  if ok and typeof(result)=="table" and result.Success==true then apply(result.Seen) end
 end)
 return true
end
function M.IsLoaded() return loaded end
return M
