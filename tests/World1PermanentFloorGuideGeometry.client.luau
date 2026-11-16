-- Native client geometry/streaming fixtures; restores the real map even on failure.
local QA=assert(_G.__FloorRouteQA)
local oldMap=workspace.GeneratedMap
local base=oldMap.TrainingArea.SpawnLocation.Position+Vector3.new(0,0,-3000)
local fixture,blocker,peer
local results={}
local function check(ok,name) table.insert(results,{Name=name,Passed=not not ok});assert(ok,name) end
local function part(parent,name,size,position)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=position;p.Parent=parent;return p
end
local function model(parent,name)
 local m=Instance.new("Model");m.Name=name;m.Parent=parent;return m
end
local ok,err=xpcall(function()
 oldMap.Parent=nil;task.wait(.4)
 check(QA.Sample().Visible==0,"Missing map hides all arrows")
 fixture=model(workspace,"GeneratedMap")
 local lobby=model(fixture,"TrainingArea")
 local floor=part(lobby,"Floor",Vector3.new(20,8,100),Vector3.new(base.X,0,base.Z+30))
 local spawn=part(lobby,"SpawnLocation",Vector3.one,Vector3.new(base.X,4,base.Z));spawn.Transparency=1;spawn.CanQuery=false;spawn.CanCollide=false
 local corridor=model(fixture,"BattleCorridor");local stage=model(corridor,"Stage01");local section=model(stage,"Stage1.1")
 local wall=part(section,"Wall",Vector3.new(20,20,1.2),Vector3.new(base.X,14,base.Z+60));wall.Transparency=1
 task.wait(.6)
 local a=QA.Sample();check(a.Visible>0,"Replacement map uses new anchors and floors")
 local folder=workspace.World1PermanentFloorGuide
 local arm=folder.Chevron3_Left
 local position=arm.CFrame:PointToWorldSpace(Vector3.new(0,0,arm.Size.Z*.3))
 check(math.abs(position.X-base.X)>1.2,"Blocker fixture lies beyond old arrow width")
 blocker=part(workspace,"__FloorRouteThinBlocker",Vector3.new(.04,.3,.04),Vector3.new(position.X,4.16,position.Z))
 blocker.CanQuery=false;blocker.CanCollide=false
 task.wait(.4)
 check(folder.Chevron3_Left.Transparency==1 and folder.Chevron3_Right.Transparency==1,"Thin non-query obstacle on widened arm hides pair")
 blocker:Destroy();blocker=nil;task.wait(.4)
 check(QA.Sample().Visible==a.Visible,"Removed obstacle restores arrows")
 floor.Size=Vector3.new(6,8,100);task.wait(.4)
 check(QA.Sample().Visible==0,"Supported centers with unsupported widened tips hide pairs")
 floor.Size=Vector3.new(20,8,100);task.wait(.4)
 check(QA.Sample().Visible==a.Visible,"Restored wide floor redraws arrows")
 floor.CanQuery=false;task.wait(.4);check(QA.Sample().Visible==0,"Unavailable floor does not leave floating arrows")
 floor.CanQuery=true;task.wait(.4);check(QA.Sample().Visible==a.Visible,"Streamed floor returns")
 local endpoint=QA.Sample().Destination;wall:Destroy();task.wait(.4)
 check(QA.Sample().Destination==endpoint and QA.Sample().Visible==a.Visible,"Removed first wall retains direction and measured endpoint")
 wall=part(section,"Wall",Vector3.new(20,20,1.2),Vector3.new(base.X,14,base.Z+70));wall.Transparency=1;task.wait(.4)
 check(math.abs(QA.Sample().Destination.Z-endpoint.Z-10)<.01,"Replacement wall updates endpoint from actual geometry")
 peer=require(game.ReplicatedStorage.Modules.FloorGuideRenderer).new({Name="__FloorRoutePeer"})
 a=QA.Sample();peer:Show("IndividualGuide",a.Origin,a.Destination);task.wait(.4)
 check(QA.Sample().Visible==a.Visible,"Individual guide is not a permanent-route obstacle")
 local pv=0;for _,x in peer:GetFolder():GetChildren() do if x.Transparency<1 then pv+=1 end end
 check(pv>0,"Permanent route is not an individual-guide obstacle")
 for _=1,5 do
  fixture.Parent=nil;task.wait(.25);fixture.Parent=workspace;task.wait(.4)
 end
 local count=0;for _,x in workspace:GetChildren() do if x.Name=="World1PermanentFloorGuide" then count+=1 end end
 check(count==1 and QA.Sample().Visible==a.Visible,"Five map stream cycles keep one route with no orphaned visible arrows")
 check(peer:GetFolder().Parent==workspace,"Permanent map refresh preserves individual pool")
end,debug.traceback)
if peer then peer:Destroy() end
if blocker then blocker:Destroy() end
if fixture then fixture:Destroy() end
oldMap.Parent=workspace;task.wait(.7)
check(QA.Sample().Visible==46,"Real map restored with 23 permanent chevrons")
if not ok then table.insert(results,{Name="Fixture error",Passed=false,Error=err}) end
return results
