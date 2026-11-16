-- Temporary getter inserted into a COPY of the final renderer, in native Client.
local source=game.ReplicatedStorage.Modules.FloorGuideRenderer.Source
local stats=[[
 function self:Stats()
  local n=0;for _ in records do n+=1 end
  return {Records=n,CacheConnections=#cacheConnections,Pairs=#pool,Alive=not destroyed}
 end
 function self:Show]]
source=source:gsub(" function self:Show",stats,1)
local module=Instance.new("ModuleScript");module.Name="__FloorRouteResourceProbe";module.Source=source;module.Parent=game.ReplicatedStorage
local m=require(module)
local g=workspace.World1PermanentFloorGuide
local a,b=g:GetAttribute("Origin"),g:GetAttribute("Destination")
local r=m.new({Name="__FloorRouteResourceGuide",Fixed=true,WidthMultiplier=3,Transparency=.3})
local rows={}
local ok,err=xpcall(function()
 for i=1,5 do
  r:Show("QA",a,b);table.insert(rows,r:Stats())
  r:Hide();r:StopCache()
  local stopped=r:Stats();assert(stopped.Records==0 and stopped.CacheConnections==0,"Cache did not release")
 end
 for _,row in rows do assert(row.Records==rows[1].Records and row.CacheConnections==2 and row.Pairs==23,"Resource growth") end
 r:Destroy()
 local final=r:Stats();assert(final.Records==0 and final.CacheConnections==0 and final.Pairs==0 and not final.Alive,"Destroy did not release")
 table.insert(rows,final)
end,debug.traceback)
r:Destroy();module:Destroy()
return {Passed=ok,Error=not ok and err or nil,Rows=rows,Kind="Final renderer Source copy plus read-only closure counters; native client"}
