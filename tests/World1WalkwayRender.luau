-- Native geometry + deterministic-clock simulation. NOT a Play/real-input test.
-- Temporary renderer copy only; production Sources remain unchanged.
local source=game.ReplicatedStorage.Modules.FloorGuideRenderer.Source
source="local qaTime=0\n"..source
source=source:gsub("os.clock%(%)%*flowSpeed","qaTime*flowSpeed")
source=source:gsub('if not flowConnection then flowConnection=game:GetService%("RunService"%).RenderStepped:Connect%(animate%) end','')
source=source:gsub('function self:Show%(key,start,target%)','function self:SetTime(t) qaTime=t;animate() end\n function self:Show(key,start,target)')
local lifecycle=assert(source:find("task.spawn(function()",1,true))
source=source:sub(1,lifecycle-1).."return M"
local M=assert(loadstring(source,"WalkwayRenderQA"))()
local C=require(game.ReplicatedStorage.Config.World1WalkwayConfig)
local G=require(game.ReplicatedStorage.Modules.World1WalkwayGeometry)
local route=assert(G.new()())
local renderer=M.new({Name="__WalkwayRenderQA",Fixed=true,WidthMultiplier=C.WidthMultiplier,
 Transparency=C.Transparency,FlowSpeed=C.ArrowSpeed,SurfaceSampleStep=C.SurfaceSampleStep,Spacing=C.ArrowSpacing})
local results={}
local function check(ok,name,detail)
 table.insert(results,{Name=name,Passed=not not ok,Detail=detail})
 assert(ok,name)
end
local obstacle
local ok,err=xpcall(function()
 local start=os.clock()
 renderer:Show("QA",route.Origin,route.Origin+route.Direction*(route.WallDistance-C.VisualWallClearance))
 local folder=renderer:GetFolder()
 local count=folder:GetAttribute("ChevronCount")
 local span=folder:GetAttribute("FlowSpan")
 local period=span/C.ArrowSpeed
 local function sample(t)
  renderer:SetTime(t)
  local out={}
  for i=1,count do
   local a,b=folder["Chevron"..i.."_Left"],folder["Chevron"..i.."_Right"]
   out[i]={Left=a.Position,Right=b.Position,Visible=a.Transparency==.5 and b.Transparency==.5}
  end
  return out
 end
 local a,b=sample(0),sample(.1)
 local moving,visible,pairs=0,0,0
 for i=1,count do
  local dl,dr=b[i].Left-a[i].Left,b[i].Right-a[i].Right
  if math.abs(dl:Dot(route.Direction)-C.ArrowSpeed*.1)<.002 then moving+=1 end
  if a[i].Visible and b[i].Visible then visible+=1 end
  if (dl-dr).Magnitude<.002 then pairs+=1 end
 end
 check(moving==count,"Every arrow actually translates",{Moved=moving,Count=count})
 check(pairs==count,"Two arms move together")
 check(visible==count,"All arrows retain Transparency 0.5 on current route",{Visible=visible})
 local wrapped=sample(period)
 for i=1,count do check((wrapped[i].Left-a[i].Left).Magnitude<.002,"Cycle returns arrow "..i) end
 local nodes=#folder:GetChildren();local revision=folder:GetAttribute("RenderRevision")
 for i=1,300 do renderer:SetTime(i/60) end
 check(nodes==#folder:GetChildren() and revision==folder:GetAttribute("RenderRevision"),"Frame updates reuse pool and surface cache",{Parts=nodes})
 local function dimensions()
  local min,max=math.huge,-math.huge
  for _,name in {"Chevron1_Left","Chevron1_Right"} do local p=folder[name]
   for _,x in {-1,1} do for _,z in {-1,1} do
    local v=p.CFrame:PointToWorldSpace(Vector3.new(x*p.Size.X/2,0,z*p.Size.Z/2)):Dot(route.Side)
    min=math.min(min,v);max=math.max(max,v)
   end end
  end
  return max-min
 end
 check(math.abs(dimensions()-7.093475)<.002,"Existing triple width preserved",{Width=dimensions()})
 renderer:Hide();renderer:SetTime(5)
 local hidden=true
 for _,part in folder:GetChildren() do hidden=hidden and part.Transparency==1 end
 check(hidden,"Hide suspends animation")
 -- A thin non-query equipment obstacle must still hide arms that cross it.
 obstacle=Instance.new("Part");obstacle.Name="__WalkwayObstacleQA"
 obstacle.Anchored=true;obstacle.CanCollide=false;obstacle.CanQuery=false;obstacle.CanTouch=false
 obstacle.Size=Vector3.new(8,2,.04)
 obstacle.CFrame=CFrame.new(route.Origin+route.Direction*40+Vector3.new(0,1.5,0))
 obstacle.Parent=workspace
 task.wait()
 renderer:Show("QA",route.Origin,route.Origin+route.Direction*(route.WallDistance-C.VisualWallClearance))
 local first=(route.WallDistance-C.VisualWallClearance-span)/2
 renderer:SetTime((40-first)/C.ArrowSpeed)
 check(folder.Chevron1_Left.Transparency==1 and folder.Chevron1_Right.Transparency==1,"Thin non-query obstacle masks moving pair")
 obstacle:Destroy();obstacle=nil;task.wait()
 renderer:Show("QA",route.Origin,route.Origin+route.Direction*(route.WallDistance-C.VisualWallClearance))
 renderer:SetTime((40-first)/C.ArrowSpeed)
 check(folder.Chevron1_Left.Transparency==.5 and folder.Chevron1_Right.Transparency==.5,"Removed obstacle restores cached flow")
 results.BuildAndSimulationSeconds=os.clock()-start
end,debug.traceback)
renderer:Destroy()
if obstacle then obstacle:Destroy() end
assert(not workspace:FindFirstChild("__WalkwayRenderQA"))
if not ok then error(err) end
return results
