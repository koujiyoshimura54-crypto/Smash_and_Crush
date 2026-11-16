-- Edit structural/simulated tests. Not a substitute for rendered Play/input checks.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==126576845524886)
assert(not game:GetService("RunService"):IsRunning())
local folder=game.ServerStorage.BodyPrototype_20261114
assert(folder:GetAttribute("Enabled")==true)
local owned,characters,prepared={},{},{}
local cases={};local checks=0
local normalSource=game.ServerScriptService.Config.MuscleScaleConfig.Source
local function check(value,message)assert(value,message);checks+=1 end
local function module(source)
 local m=Instance.new("ModuleScript");m.Name="__ComparisonValidation"
 m.Source=source:gsub("require%(folder.PlayableShapeConfig%)","require(script.Shape)")
 local shape=folder.PlayableShapeConfig:Clone();shape.Name="Shape";shape.Parent=m
 m.Parent=folder;table.insert(owned,m);return m
end
local function avatar()
 local c=folder.CurrentAvatarReference:Clone();c.Name="__ComparisonAvatar";c.Parent=folder
 table.insert(characters,c);return c
end
local function options(body,h,t)return {Active=true,Body=body,Mode="Manual",Stage=10,Height=h,Thickness=t}end
local function bodySizes(c)
 local sizes={}
 for _,v in c:GetChildren()do if v:IsA("BasePart")then sizes[v.Name]=v.Size end end
 return sizes
end
local function halfY(part)
 local cf=part.CFrame
 return(math.abs(cf.RightVector.Y)*part.Size.X+math.abs(cf.UpVector.Y)*part.Size.Y+math.abs(cf.LookVector.Y)*part.Size.Z)/2
end
local function actualHeight(c)
 return c.Head.Position.Y+halfY(c.Head)-math.min(c.LeftFoot.Position.Y-halfY(c.LeftFoot),c.RightFoot.Position.Y-halfY(c.RightFoot))
end
local ok,result=pcall(function()
 local source=folder.PlayableBodyPrototype.Source
 for _,studio in {false,true}do for _,place in {0,126576845524886}do for _,on in {false,true}do
  local prefix=string.format([[
local realGame,realRequire,realScript=game,require,script
local game={PlaceId=%d,ServerScriptService=realGame.ServerScriptService,GetService=function()return {IsStudio=function()return %s end}end}
local script={Parent={GetAttribute=function()return %s end},Shape=realScript.Shape}
local require=function(m)realScript.Counter.Value+=1;return realRequire(m)end
]],place,tostring(studio),tostring(on))
  local m=module(prefix..source);local counter=Instance.new("IntValue");counter.Name="Counter";counter.Parent=m
  local api=require(m);local active=studio and place==126576845524886 and on
  check(counter.Value==(active and 2 or 0),"Gate initialized dependencies")
  check((type(api.Apply)=="function")==active,"Unexpected gated API")
  table.insert(cases,"gate "..tostring(studio).."/"..place.."/"..tostring(on))
  local servicePrefix=prefix:gsub("return realRequire%(m%)end","return {Manual={MinHeight=1,MaxHeight=10,MinThickness=1,MaxThickness=10}}end")
  local service=module(servicePrefix..folder.PlayableComparisonService.Source)
  local serviceCounter=Instance.new("IntValue");serviceCounter.Name="Counter";serviceCounter.Parent=service
  local comparison=require(service)
  check(serviceCounter.Value==(active and 3 or 0),"Comparison service initialized outside gate")
  check((type(comparison.Handle)=="function")==active,"Comparison service gate")
  if active then
   local good=options("Normal",1.234,9.876);local rounded=comparison.Validate(good)
   check(rounded.Height==1.23 and rounded.Thickness==9.88,"Decimal validation")
   for key,badValues in {Height={0,10.01,math.huge,0/0,"2"},Thickness={0,10.01,math.huge,0/0},Stage={-1,11,.5},Body={"Other"},Mode={"Other"}}do
    for _,badValue in badValues do local invalid=table.clone(good);invalid[key]=badValue;check(not comparison.Validate(invalid),"Invalid request accepted")end
   end
   check(not comparison.Validate(false),"Invalid packet accepted")
  end
  table.insert(cases,"service gate "..tostring(studio).."/"..place.."/"..tostring(on))
 end end end
 local p=require(module(source));local c=avatar();local head=c.Head
 local original={};for _,v in c:GetChildren()do if v:IsA("BasePart")then original[v.Name]={Part=v,Size=v.Size}end end
 local shirt=c:FindFirstChildOfClass("Shirt");local pants=c:FindFirstChildOfClass("Pants")
 local shirtId=shirt and shirt.ShirtTemplate;local pantsId=pants and pants.PantsTemplate
 local graphic=Instance.new("ShirtGraphic");graphic.Graphic="rbxasset://textures/face.png";graphic.Parent=c
 local clothes={}for _,v in c:GetChildren()do if v:IsA("Accessory")then clothes[v]=v.Handle.Transparency end end
 check(p.Apply(c,function()return true end),"Prepare failed");table.insert(prepared,{p,c})
 for _,body in {"Normal","Muscle"}do
  check(p.ApplyStage(c,0,options(body,1,1)),"Base failed")
  local base=bodySizes(c);local standing=actualHeight(c)
  for _,spec in {{1.25,3.75},{5,10},{10,10},{1,10},{5,1},{1,1}}do
   check(p.ApplyStage(c,10,options(body,spec[1],spec[2])),"Manual failed")
   check(math.abs(actualHeight(c)/standing-spec[1])<.0001,"Feet-to-head ratio")
   for name,size in bodySizes(c)do if name~="Head"and name~="HumanoidRootPart"then
    check(math.abs(size.X/base[name].X-spec[2])<.0001 and math.abs(size.Z/base[name].Z-spec[2])<.0001,"Absolute thickness "..name)
   end end
   check(c.Head==head and c.Head.Size==original.Head.Size,"Head changed")
   check(not c:FindFirstChild("PrototypeShorts"),"Forced shorts")
   check(graphic.Parent==c and graphic.Graphic=="rbxasset://textures/face.png","Classic T-shirt lost")
   check(not pants or pants.PantsTemplate==pantsId,"Classic pants changed")
   check(not shirt or shirt.ShirtTemplate=="","Other classic shirt still displayed")
   for acc in clothes do check(acc.Parent==c,"Accessory deleted")end
  end
  for stage=0,10 do check(p.ApplyStage(c,0,{Active=true,Body=body,Mode="Growth",Stage=stage,Height=10,Thickness=10}),"Growth failed")end
 end
 table.insert(cases,"both bodies: independent manual dimensions, growth stages and wardrobe retention")
 check(p.ApplyStage(c,0,{Active=false}),"Clear failed")
 for name,entry in original do check(c[name]==entry.Part and c[name].Size==entry.Size,"Original body not restored "..name)end
 for acc,transparency in clothes do check(acc.Handle.Transparency==transparency,"Clothes visibility not restored")end
 check(not shirt or shirt.ShirtTemplate==shirtId,"Shirt template not restored")
 table.insert(cases,"clear restores original parts and clothing")
 local count=#c:GetDescendants()
 for _=1,10 do check(p.Apply(c,function()return true end));check(p.ApplyStage(c,0,{Active=false}))end
 check(#c:GetDescendants()==count,"Reapply accumulated objects");p.Release(c)
 check(not p.ApplyStage(c,0,{Active=false}),"Released state reused")
 table.insert(cases,"idempotence and cache release")
 local missing=module(source:gsub('folder:FindFirstChild%("PlayableSourceBody"%)',"script.Donor"))
 local donor=folder.PlayableSourceBody:Clone();donor.Name="Donor";donor.RightHand:Destroy();donor.Parent=missing
 c=avatar();head=c.Head;local torso=c.UpperTorso
 local applied=require(missing).Apply(c,function()return true end)
 check(not applied and c.Head==head and c.UpperTorso==torso,"Preflight mutated original")
 table.insert(cases,"missing donor part does not exchange any body")
 p=require(module(source));local calls=0
 applied=p.Apply(c,function()calls+=1;return calls==1 end)
 check(not applied and c.Head==head and c.UpperTorso==torso,"Stale preparation mutated original")
 table.insert(cases,"stale request before commit")
 local failing=source:gsub("wardrobe%(s,active%)","wardrobe(s,active)\n if active and not injected then injected=true;error('injected body failure')end",1)
 p=require(module("local injected=false\n"..failing));check(p.Apply(c,function()return true end));table.insert(prepared,{p,c});check(p.ApplyStage(c,0,{Active=false}))
 local before=bodySizes(c)
 applied=p.ApplyStage(c,10,options("Muscle",5,10))
 check(not applied and c.Head==head and c.UpperTorso==torso,"Rollback changed identity")
 for name,size in before do check(c[name].Size==size,"Rollback changed size")end
 check(not c.HumanoidRootPart.Anchored and c.Humanoid.Health>0,"Rollback left unusable character")
 p.Release(c);table.insert(cases,"injected post-swap failure restores normal body")
 check(game.ServerScriptService.Config.MuscleScaleConfig.Source==normalSource,"Normal config mutated")
 table.insert(cases,"normal growth config unchanged")
 return {Cases=cases,CaseCount=#cases,Checks=checks,Kind="Edit structural and simulated conditions"}
end)
for _,entry in prepared do pcall(entry[1].Release,entry[2])end
for _,c in characters do c:Destroy()end
for _,m in owned do m:Destroy()end
-- Release owned state even if an assertion fails.
assert(ok,result)
return result
