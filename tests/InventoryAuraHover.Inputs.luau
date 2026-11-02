local M={InputType=Enum.UserInputType.MouseMovement}
local rows=setmetatable({},{__mode="k"})
function M.Connect(button,event,fn)
 local r=rows[button] or {};rows[button]=r;r[event]=r[event] or {};table.insert(r[event],fn)
 return button[event]:Connect(fn)
end
function M.Fire(button,event)
 local r=rows[button];local callbacks=r and r[event] or {}
 for _,fn in ipairs(table.clone(callbacks))do fn()end
 return #callbacks
end
function M.Count(button,event)return #(rows[button] and rows[button][event] or {})end
return M
