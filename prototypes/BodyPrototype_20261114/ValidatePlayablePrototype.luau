-- Edit-only structural/failure tests. These are not rendered or real-input tests.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==126576845524886)
assert(not game:GetService("RunService"):IsRunning())
local folder=game.ServerStorage.BodyPrototype_20261114
assert(folder:GetAttribute("Enabled")==true)
assert(not folder:FindFirstChild("__PlayableBodyValidation"))
local temporary=Instance.new("Folder");temporary.Name="__PlayableBodyValidation";temporary.Parent=folder
local source=folder.PlayableBodyPrototype.Source
local normalConfig=game.ServerScriptService.Config.MuscleScaleConfig.Source
local passed={}
local function snapshot(model)
 local result={Objects={},Welds={},Count=0}
 for _,v in model:GetDescendants() do
  if v.ClassName=="Status" then continue end -- Engine-created, non-archivable Humanoid bookkeeping.
  result.Count+=1
  if v:IsA("Weld") and v.Name=="AccessoryWeld" then
   table.insert(result.Welds,{Parent=v.Parent,Name=v.Name,Part0=v.Part0,Part1=v.Part1,C0=v.C0,C1=v.C1})
   continue
  end
  local p={Parent=v.Parent,Name=v.Name}
  if v:IsA("BasePart") then p.Size=v.Size;p.CFrame=v.CFrame;p.Color=v.Color;p.Anchored=v.Anchored;p.CanCollide=v.CanCollide;p.RootPriority=v.RootPriority end
  if v:IsA("Motor6D") then p.C0=v.C0;p.C1=v.C1;p.Part0=v.Part0;p.Part1=v.Part1 end
  if v:IsA("Humanoid") then p.HipHeight=v.HipHeight;p.Health=v.Health;p.RequiresNeck=v.RequiresNeck;p.AutomaticScalingEnabled=v.AutomaticScalingEnabled end
  result.Objects[v]=p
 end
 return result
end
local function unchanged(model,before)
 local count=0
 for _,v in model:GetDescendants() do if v.ClassName~="Status" then count+=1 end end
 if count~=before.Count then
  local changes={}
  for _,v in model:GetDescendants() do if not before.Objects[v] then table.insert(changes,"added "..v:GetFullName()..":"..v.ClassName) end end
  for v in before.Objects do if not v:IsDescendantOf(model) then table.insert(changes,"missing "..v.Name..":"..v.ClassName) end end
  error("Unexpected descendants "..before.Count.." -> "..count..": "..table.concat(changes,", "))
 end
 for object,props in before.Objects do for key,value in props do assert(object[key]==value,"Rollback changed "..object.Name.."."..key) end end
 for _,record in before.Welds do
  local weld=assert(record.Parent:FindFirstChild(record.Name),"Missing accessory weld after rollback")
  for _,key in {"Part0","Part1","C0","C1"} do assert(weld[key]==record[key],"Accessory connection not restored") end
 end
end
local function module(text,name)
 local m=Instance.new("ModuleScript");m.Name=name;m.Source=text;m.Parent=folder
 return m
end
local ownedModules={}
local phase="gate tests"
local ok,result=pcall(function()
 -- Run the actual module's early gate under all 8 combinations. The stand-in
 -- game/script only selects the environment; requiring shape data is counted.
 for _,studio in {false,true} do for _,place in {0,126576845524886} do for _,on in {false,true} do
  local prefix=string.format([[
local realRequire=require
local counter=script.Counter
local realFolder=script.Parent
local game={PlaceId=%d,GetService=function()return {IsStudio=function()return %s end}end}
local script={Parent={GetAttribute=function()return %s end,PlayableShapeConfig=realFolder.PlayableShapeConfig}}
local require=function(m)counter.Value+=1;return realRequire(m)end
]],place,tostring(studio),tostring(on))
  local m=module(prefix..source,"__PlayableBodyGate");table.insert(ownedModules,m)
  local counter=Instance.new("IntValue");counter.Name="Counter";counter.Parent=m
  local api=require(m);local active=studio and place==126576845524886 and on
  assert(counter.Value==(active and 1 or 0),"Gate initialized outside its conditions")
  assert((type(api.Apply)=="function")==active,"Unexpected gated API")
  table.insert(passed,"gate "..tostring(studio).."/"..place.."/"..tostring(on))
 end end end
 local fresh=module(source,"__PlayableBodyValidationModule");table.insert(ownedModules,fresh)
 local prototype=require(fresh)
 local c=folder.CurrentAvatarReference:Clone();c.Parent=temporary
 task.wait(0.2) -- Allow normal accessory/constraint initialization before the baseline.
 local before=snapshot(c)
 phase="missing donor preflight"
 local part=folder.PlayableSourceBody.RightHand;part.Parent=nil
 local callOk,applied,why=pcall(prototype.Apply,c,function()return true end)
 part.Parent=folder.PlayableSourceBody
 assert(callOk and not applied and tostring(why):find("Missing body part",1,true))
 unchanged(c,before);table.insert(passed,"missing donor part leaves original character intact")
 local calls=0
 phase="stale character preflight"
 applied=prototype.Apply(c,function()calls+=1;return calls==1 end)
 assert(not applied and calls==2);unchanged(c,before)
 table.insert(passed,"invalidated character cancels before commit")
 local failing,count=source:gsub("resize%(state,0,true%)","resize(state,0,true)\n  error(\"forced commit failure\")",1)
 assert(count==1)
 local broken=module(failing,"__PlayableBodyRollbackModule");table.insert(ownedModules,broken)
 phase="injected commit rollback"
 local failed,reason=require(broken).Apply(c,function()return true end)
 assert(not failed and reason:find("Rolled back",1,true));unchanged(c,before)
 table.insert(passed,"injected failure after replacement rolls back parts/joints/head/root")
 c:Destroy()

 -- Synthetic classic-head case, separate from the owner's actual Dynamic Head.
 c=folder.CurrentAvatarReference:Clone();c.Parent=temporary
 local old=c.Head;local head=Instance.new("Part");head.Name="Head";head.Size=old.Size;head.CFrame=old.CFrame
 for _,a in old:GetChildren() do if a:IsA("Attachment") then a:Clone().Parent=head end end
 old:Destroy();head.Parent=c
 local face=Instance.new("Decal");face.Name="face";face.Texture="rbxasset://textures/face.png";face.Parent=head
 assert(prototype.Apply(c,function()return true end))
 assert(c.Head==head and face.Parent==head and face.Texture=="rbxasset://textures/face.png")
 table.insert(passed,"synthetic classic head and face decal retained")
 local initialCount=#c:GetDescendants()
 for _=1,10 do assert(prototype.Apply(c,function()return true end));assert(prototype.ApplyStage(c,10))end
 assert(#c:GetDescendants()==initialCount and #c.PrototypeShorts:GetChildren()==3)
 prototype.Release(c);assert(not prototype.ApplyStage(c,0))
 table.insert(passed,"idempotent assembly and explicit cache release")
 assert(game.ServerScriptService.Config.MuscleScaleConfig.Source==normalConfig)
 table.insert(passed,"normal growth config unchanged")
 return passed
end)
for _,m in ownedModules do m:Destroy() end
temporary:Destroy()
assert(ok,phase..": "..tostring(result))
return {Passed=#result,Cases=result,Kind="Edit structural and simulated environment tests"}
