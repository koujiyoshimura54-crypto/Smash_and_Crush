-- Focused native Edit checks; no gameplay or natural-streaming claim.
assert(not game.RunService:IsRunning())
local M=require(game.ReplicatedStorage.Modules.Stage03GroundContact)
local count=0
local function check(ok,why)count+=1;assert(ok,why)end
for i=0,19 do
 local cf=CFrame.new(2,8,3)*CFrame.Angles(i*.13,i*.29,-i*.09);local size=Vector3.new(1.7,1.06,3.07)
 local low=math.huge
 for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do low=math.min(low,cf:PointToWorldSpace(size*Vector3.new(x,y,z)/2).Y)end end end
 check(math.abs(M.Bottom(cf,size)-low)<1e-5,"Oriented foot lower bound")
end
local e=Instance.new("Model");e:SetAttribute("WorldId",1);e:SetAttribute("StageNumber",3)
local r=game.ServerStorage.EnemyTemplates.Stage03Boss.TungTungSahurRig:Clone();r.Parent=e
local original=r.LowerTorso.Root.C0
local remove,valid=M.Mount(r);check(remove~=nil and valid(),"Actual R15 chain accepted")
r.LowerTorso.Root.C0=original+Vector3.new(0,2,0);remove();remove()
check(r.LowerTorso.Root.C0==original,"Idempotent cleanup restores original C0")
check(not valid(),"Disposed connection invalid")
e:SetAttribute("WorldId",2);check(M.Mount(r)==nil,"World2 excluded")
e:SetAttribute("WorldId",1);e:SetAttribute("StageNumber",2);check(M.Mount(r)==nil,"Stage2 excluded")
e:SetAttribute("StageNumber",3);r.Name="Other";check(M.Mount(r)==nil,"Other rig excluded");r.Name="TungTungSahurRig"
local ankle=r.RightFoot.RightAnkle;local parent=ankle.Parent;ankle.Parent=nil
check(M.Mount(r)==nil,"Missing ankle waits")
ankle.Parent=parent;remove,valid=M.Mount(r);check(remove~=nil and valid(),"Ankle arrival accepted")
ankle.Parent=nil;check(not valid(),"Removed ankle invalidates current mount");remove();ankle.Parent=parent
check(r.LowerTorso.Root.C0==original,"Partial cleanup restores original")
e:Destroy()
return {Passed=true,Assertions=count,Kind="Native Edit geometry/scope/lifecycle only"}
