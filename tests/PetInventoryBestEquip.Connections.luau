-- Temporary callback observation only; never installed in the shipped place.
local M={Callbacks=setmetatable({},{__mode="k"})}
function M.Connect(obj,event,fn)
 local c=obj[event]:Connect(fn)
 local row=M.Callbacks[obj] or {};M.Callbacks[obj]=row
 row[event]=row[event] or {};table.insert(row[event],{Connection=c,Callback=fn})
 return c
end
function M.Fire(obj,event)
 local count=0
 for _,entry in ipairs(M.Callbacks[obj] and M.Callbacks[obj][event] or {}) do
  if entry.Connection.Connected then count+=1;entry.Callback() end
 end
 return count
end
return M
