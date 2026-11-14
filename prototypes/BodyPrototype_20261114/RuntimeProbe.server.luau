assert(game:GetService("RunService"):IsStudio() and game.PlaceId==126576845524886)
assert(game.ReplicatedStorage:FindFirstChild("__BodyPrototypeMemory"))
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Training=require(game.ServerScriptService.Services.TrainingManager)
local Prototype=require(game.ServerStorage.BodyPrototype_20261114.BodyPrototype)
local fn=Instance.new("BindableFunction")
fn.Name="__BodyPrototypeProbe"
fn.Parent=game.ServerStorage
fn.OnInvoke=function(action,value)
 local p=game.Players:GetPlayers()[1]
 local c=p.Character;local h=c.Humanoid;local r=c.HumanoidRootPart
 if action=="level" then
  local curve=Data.Get(p).Data.LevelCurveVersion
  local advance=require(game.ReplicatedStorage.Modules.LevelProgression).Advance
  local low,high=0,1
  while advance(1,0,high,curve)<value do high*=2 end
  while low<high do local mid=math.floor((low+high)/2);if advance(1,0,mid,curve)>=value then high=mid else low=mid+1 end end
  Data.Get(p).Data.SelectedSizeTier=0;p:SetAttribute("SelectedSizeTier",0)
  local ok,err=Data.ApplyStudioStartLevel(p,low,value)
  return {ok=ok,err=err,level=p:GetAttribute("Level"),strength=p:GetAttribute("Strength")}
 elseif action=="reapply" then
  local before=c.UpperTorso.Size
  local assembled=Prototype.Apply(c,c:GetAttribute("BodyPrototypeRatio"))
  p:SetAttribute("SelectedSizeTier",-1);p:SetAttribute("SelectedSizeTier",0)
  return {assembled=assembled,before=tostring(before),after=tostring(c.UpperTorso.Size)}
 elseif action=="equip" then
  local master=require(game.ReplicatedStorage.Config.DumbbellItemMaster)
  local item=master.GetSorted()[1]
  Data.Get(p).Data.OwnedDumbbells[item.ItemId]=1
  return {id=item.ItemId,ok=require(game.ServerScriptService.Services.DumbbellService).EquipDumbbell(p,item.ItemId)}
 elseif action=="treadmills" then
  local cfg=require(game.ReplicatedStorage.Config.TreadmillConfig)
  local out={}
  for _,t in Training.GetTreadmills() do table.insert(out,{path=t:GetFullName(),position=tostring(t.Area.Position),size=tostring(t.Area.Size),allowed=Training.CanUseTreadmill(p,t),config=cfg.GetForModel(t),world=cfg.WorldForModel(t)})end
  return out
 elseif action=="skin" then
  Prototype.Skin(c,value and Color3.fromRGB(value[1],value[2],value[3]) or nil)
 elseif action=="clothes" then
  local f=game.ServerStorage.BodyPrototype_20261114.Clothing
  Prototype.Clothes(c,value~=0 and f[tostring(value)] or nil,f["398633812"])
 elseif action=="ratio" then
  game.ServerStorage.BodyPrototype_20261114:SetAttribute("DefaultRatio",value)
  h.Health=0
  return {deathTriggered=true,nextRatio=value}
 end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={c};params.RespectCanCollide=true
 local out={level=p:GetAttribute("Level"),strength=p:GetAttribute("Strength"),ratio=c:GetAttribute("BodyPrototypeRatio"),hip=h.HipHeight,health=h.Health,root=tostring(r.Position),floor=h.FloorMaterial.Name,stage=c:GetAttribute("MuscleHeightScale"),signature=Prototype.Signature(c),torso=tostring(c.UpperTorso.Size),upperArm=tostring(c.RightUpperArm.Size),skin=tostring(c.UpperTorso.Color),training=p:GetAttribute("IsTraining"),treadmill=p:GetAttribute("TrainingTreadmill"),feet={},grips={},isolationWrites=require(game.ReplicatedStorage.__BodyPrototypeMemory).Writes}
 for _,side in {"Left","Right"} do
  local foot=c[side.."Foot"]
  local cf=foot.CFrame
  local half=(math.abs(cf.RightVector.Y)*foot.Size.X+math.abs(cf.UpVector.Y)*foot.Size.Y+math.abs(cf.LookVector.Y)*foot.Size.Z)/2
  local hit=workspace:Raycast(foot.Position,Vector3.new(0,-10,0),params)
  table.insert(out.feet,{side=side,gap=hit and foot.Position.Y-half-hit.Position.Y,surface=hit and hit.Instance:GetFullName()})
  local dumb=c:FindFirstChild("TrainingDumbbell"..side)
  if dumb then local bar=dumb.PrimaryPart;table.insert(out.grips,{side=side,offset=tostring(c[side.."Hand"].CFrame:PointToObjectSpace(bar.Position)),hand=tostring(c[side.."Hand"].Size),bar=tostring(bar.Size)})end
 end
 out.neckGap=(c.UpperTorso.NeckRigAttachment.WorldPosition-c.Head.NeckRigAttachment.WorldPosition).Magnitude
 out.dataLoaded=Data.Get(p) and Data.Get(p).Loaded
 return out
end
