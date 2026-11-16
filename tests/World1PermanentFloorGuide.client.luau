local p=game.Players.LocalPlayer
local g=assert(workspace:FindFirstChild("World1PermanentFloorGuide"))
local function sample()
 local folder=workspace:FindFirstChild("World1PermanentFloorGuide")
 local visible,parts=0,0
 if folder then for _,x in folder:GetChildren() do if x:IsA("BasePart") then parts+=1;if x.Transparency<1 then visible+=1 end end end end
 return {Folder=folder,Origin=folder and folder:GetAttribute("Origin"),Destination=folder and folder:GetAttribute("Destination"),
  Visible=visible,Parts=parts,Revision=folder and folder:GetAttribute("RenderRevision")}
end
local function dimensions(folder)
 local a=folder:GetAttribute("Origin");local b=folder:GetAttribute("Destination")
 local forward=Vector3.new(b.X-a.X,0,b.Z-a.Z).Unit;local side=forward:Cross(Vector3.yAxis)
 local x0,x1,z0,z1=math.huge,-math.huge,math.huge,-math.huge
 for _,part in folder:GetChildren() do
  if part.Name=="Chevron1_Left" or part.Name=="Chevron1_Right" then
   for _,x in {-1,1} do for _,z in {-1,1} do
    local point=part.CFrame:PointToWorldSpace(Vector3.new(x*part.Size.X/2,0,z*part.Size.Z/2))
    local sx,sz=point:Dot(side),point:Dot(forward)
    x0=math.min(x0,sx);x1=math.max(x1,sx);z0=math.min(z0,sz);z1=math.max(z1,sz)
   end end
  end
 end
 return {Width=x1-x0,Depth=z1-z0}
end
local results={}
local function check(ok,name,detail) table.insert(results,{Name=name,Passed=not not ok,Detail=detail});assert(ok,name) end
local a=sample();check(a.Visible==46,"Fresh LV1 route")
_G.__FloorRouteQA={Sample=sample,Results=results,Initial=a,Dimensions=dimensions}
local r=require(game.ReplicatedStorage.Modules.FloorGuideRenderer).new({Name="__FloorRouteOldStyle"})
r:Show("OldStyle",a.Origin,a.Destination)
local old=dimensions(r:GetFolder());local new=dimensions(g)
check(math.abs(new.Width/old.Width-3)<.001 and math.abs(new.Depth-old.Depth)<.001,"3x full width; unchanged front/back extent",{Old=old,New=new})
check(g.Chevron1_Left.Size.X==r:GetFolder().Chevron1_Left.Size.X and g.Chevron1_Left.Size.Y==r:GetFolder().Chevron1_Left.Size.Y,"Unchanged stroke and vertical thickness")
r:Destroy();task.wait(.4)
local created=0;local c=workspace.DescendantAdded:Connect(function(v) if v.Parent==g then created+=1 end end)
local start=sample();task.wait(2);local stop=sample();c:Disconnect()
check(created==0 and start.Revision==stop.Revision,"Idle reuses Parts and skips redraw",{Created=created,RevisionBefore=start.Revision,RevisionAfter=stop.Revision})
local root=p.Character.HumanoidRootPart;local oldCF=root.CFrame
root.CFrame=oldCF+Vector3.new(8,0,10);task.wait(.5)
local moved=sample();check(moved.Origin==a.Origin and moved.Destination==a.Destination and moved.Visible==46,"Movement keeps fixed endpoints")
root.CFrame=oldCF
local complete=p:GetAttribute("TutorialCompleted");p:SetAttribute("TutorialCompleted",true);task.wait(.4)
check(sample().Visible==46,"Completed tutorial still shows route")
p:SetAttribute("TutorialCompleted",complete)
local current=p:GetAttribute("CurrentWorld");p:SetAttribute("CurrentWorld",2);task.wait(.4);check(sample().Visible==0,"World2 hidden")
p:SetAttribute("CurrentWorld",current);task.wait(.5);check(sample().Visible==46,"World1 restored")
local mod=p.PlayerScripts.Tutorial.World1FloorRouteClient
local saved=mod:Clone();mod:Destroy();task.wait(.7)
check(not workspace:FindFirstChild("World1PermanentFloorGuide"),"Destroy removes owned route")
saved.Parent=p.PlayerScripts.Tutorial;task.wait(.6)
local count=0;for _,x in workspace:GetChildren() do if x.Name=="World1PermanentFloorGuide" then count+=1 end end
check(count==1 and sample().Visible==46,"Script reinitialization creates one route")
return results
