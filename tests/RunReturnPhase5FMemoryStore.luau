local M={Requests=0,Writes=0}
local function copy(v) if typeof(v)~="table" then return v end local r={} for k,x in pairs(v) do r[k]=copy(x) end return r end
function M.Reset()
 M.Data={OwnedItems={PROTEIN_COMMON_FIRE=10},EquippedItems={Protein="",Glove="",TrainingBelt=""},ResetToken="qa"}
 M.Meta={Keep="unchanged"} M.Requests=0 M.Writes=0 M.FailBefore=nil M.FailAfter=nil M.After=nil M.Before=nil M.Repeat=false
end
function M:GetAsync() return copy(self.Data) end
function M:UpdateAsync(_,fn)
 self.Requests+=1 local request=self.Requests
 if self.Before then self.Before(self,request) end
 if self.FailBefore==request then error("injected failure",0) end
 local function info() local meta=copy(self.Meta) return {GetMetadata=function()return copy(meta)end,GetUserIds=function()return {}end} end
 if self.Repeat then fn(copy(self.Data),info()) end
 local value,_,meta=fn(copy(self.Data),info())
 if not value then return nil end
 self.Data=copy(value) self.Meta=copy(meta or {}) self.Writes+=1
 if self.After then self.After(self,request) end
 if self.FailAfter==request then error("injected response loss",0) end
 return copy(self.Data),info()
end
M.Reset()
return M
