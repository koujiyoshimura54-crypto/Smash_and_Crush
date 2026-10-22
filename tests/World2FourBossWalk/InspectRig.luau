-- Unsaved Edit preparation/export; records actual engine-built anatomical joints.
local H=game:GetService("HttpService")
local all={}
for stage,number in {[2]="023",[4]="058",[6]="173",[7]="939"} do
 local model=game.ServerStorage.EnemyTemplates.World2SCPDisplays["SCP"..number.."_Display"]
 local parts,ids,before,joints={},{},{},{}
 for _,x in model:GetDescendants() do
  if x:IsA("BasePart") then
   local id=#parts+1;ids[x]=id
   table.insert(parts,{Id=id,Name=x.Name,Position={x.Position.X,x.Position.Y,x.Position.Z},Size={x.Size.X,x.Size.Y,x.Size.Z}})
   before[x]={CFrame=x.CFrame,Size=x.Size,Color=x.Color,Transparency=x.Transparency}
  elseif x:IsA("JointInstance") or x:IsA("WeldConstraint") then
   joints[x]={Part0=x.Part0,Part1=x.Part1,Parent=x.Parent,Name=x.Name,Class=x.ClassName}
   if x:IsA("JointInstance") then joints[x].C0=x.C0;joints[x].C1=x.C1 end
  end
 end
 if savedMode then assert(model:GetAttribute("GaitRigVersion")==1,"Saved rig missing "..number) end
 require(game.ReplicatedStorage.Modules.World2BossGaitRig).Build(model,stage)
 local rows={Stage=stage,Number=number,Parts=parts,Joints={},Removed={},RestUnchanged=true}
 for p,b in before do assert(p.CFrame==b.CFrame and p.Size==b.Size and p.Color==b.Color and p.Transparency==b.Transparency,"Authored shape changed") end
 for _,x in model:GetDescendants() do
  if not (x:IsA("JointInstance") or x:IsA("WeldConstraint")) then continue end
  local old=joints[x]
  local row={Class=x.ClassName,Name=x.Name,Part0=ids[x.Part0],Part1=ids[x.Part1],Parent=ids[x.Parent],Existed=old~=nil}
  if old then row.Original={Class=old.Class,Name=old.Name,Part0=ids[old.Part0],Part1=ids[old.Part1],Parent=ids[old.Parent]};row.FramesChanged=old.C0 and (old.C0~=x.C0 or old.C1~=x.C1) or false end
  if x:IsA("JointInstance") then row.C0={x.C0:GetComponents()};row.C1={x.C1:GetComponents()} end
  table.insert(rows.Joints,row)
 end
 for j,old in joints do if not j.Parent then table.insert(rows.Removed,{Class=old.Class,Name=old.Name,Part0=ids[old.Part0],Part1=ids[old.Part1],Parent=ids[old.Parent]}) end end
 local compiled=require(game.ReplicatedStorage.Modules.World2BossGait).Compile(model,stage)
 rows.CompiledMotors=#compiled.Joints;rows.VisibleContactParts=#compiled.Feet
 table.insert(all,rows)
end
print("FOUR_RIG "..H:JSONEncode(all))
