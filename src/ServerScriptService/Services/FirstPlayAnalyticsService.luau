-- First-session observations only. This service never owns progression or persistence.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Config=require(script.Parent.Parent.Config.FirstPlayAnalyticsConfig)
local Transport=require(script.Parent.FirstPlayAnalyticsTransport)
local Ore=require(RS.Config.OreConfig)
local Merge=require(RS.Modules.OreMerge)
local Counts=require(RS.Modules.InventoryCounts)
local M={}
local states=setmetatable({},{__mode="k"})
local remote=RS.Remotes:FindFirstChild("FirstPlayAnalytics") or Instance.new("RemoteEvent")
remote.Name="FirstPlayAnalytics";remote.Parent=RS.Remotes
local release="PlaceVersion:"..tostring(game.PlaceVersion)
local names={Entry="MTF_Entry_v1",Combat="MTF_FirstCombat_v1",Ore="MTF_FirstOreMerge_v1"}
local steps={Entry={"ServerJoined","DataLoaded","ClientPlayable"},
 Combat={"Playable","EnteredStage1","ClearedFirstWall","ClearedStage1Walls","DamagedStage1Boss","DefeatedStage1Boss"},
 Ore={"Eligible","OreViewOpened","ValidSelection","MergeRequested","MergeCommitted"}}
local function fields(cohort,detail)
 return {[Enum.AnalyticsCustomFieldKeys.CustomField01.Name]=release,
  [Enum.AnalyticsCustomFieldKeys.CustomField02.Name]=cohort,
  [Enum.AnalyticsCustomFieldKeys.CustomField03.Name]=detail}
end
local function seconds(s) return math.max(0,os.clock()-s.Joined) end
local function custom(p,s,key,detail,entry)
 if s.Seen[key] then return end;s.Seen[key]=true
 Transport.Enqueue(p,s,{Kind="Custom",Name=entry and "MTF_EntrySeconds_v1" or "MTF_FirstActionSeconds_v1",
  Value=seconds(s),Fields=fields(entry and s.Cohort or "NewFirstSession",detail)})
end
local function step(p,s,f,index)
 if s.Broken[f] or index<=s.Progress[f] then return false end
 if index~=s.Progress[f]+1 then
  s.Broken[f]=true
  custom(p,s,"Order:"..f,f.."OutOfOrder",f=="Entry")
  return false
 end
 s.Progress[f]=index
 Transport.Enqueue(p,s,{Kind="Funnel",Name=names[f],Session=s.Id,Step=index,StepName=steps[f][index],
  Fields=fields(f=="Entry" and "AllSessions" or "NewFirstSession","Normal")})
 custom(p,s,"Time:"..f..index,f..":"..steps[f][index],f=="Entry")
 return true
end
local function new(s) return s and s.Loaded and s.Cohort=="New" and not s.Reset end
local function data(p)
 local d=require(script.Parent.PlayerDataService)
 local s=d.Get(p)
 return s and s.Loaded and s or nil,d
end
local function living(p)
 local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
 return c and h and h.Health>0 and r and not r.Anchored and c or nil
end
local function bindCharacter(p,s,c)
 if s.Death then s.Death:Disconnect();s.Death=nil end
 task.spawn(function()
  local h=c:WaitForChild("Humanoid",15)
  if not h or states[p]~=s or p.Character~=c then return end
  s.Death=h.Died:Connect(function()
   if not new(s) then return end
   local phase=s.Progress.Ore>0 and ("Ore:"..steps.Ore[s.Progress.Ore])
    or s.Progress.Combat>0 and ("Combat:"..steps.Combat[s.Progress.Combat]) or "Loading"
   custom(p,s,"FirstDeath","Death:"..phase)
  end)
 end)
end
function M.Join(p)
 if states[p] then return end
 local s={Id=Http:GenerateGUID(false),Joined=os.clock(),Cohort="Unknown",Loaded=false,
  Progress={Entry=0,Combat=0,Ore=0},Broken={},Seen={},Queue={},SendBroken={},Failed=0,Dropped=0,
  Connections={},ClientTokens=8,ClientAt=os.clock(),ClientSequence=0}
 states[p]=s
 p:SetAttribute("MTFSession",s.Id)
 step(p,s,"Entry",1)
 table.insert(s.Connections,p.CharacterAdded:Connect(function(c)bindCharacter(p,s,c)end))
 if p.Character then bindCharacter(p,s,p.Character) end
 for _,key in {"ForgeInventoryRevision","World2Visited","ForgeSavePending"} do
  table.insert(s.Connections,p:GetAttributeChangedSignal(key):Connect(function()
   task.defer(function()M.CheckOre(p)end)
  end))
 end
end
function M.Loaded(p,d,kind)
 local s=states[p];if not s then return end
 if s.Loaded then
  if s.Data~=d then s.Cohort="Existing";s.Reset=true;p:SetAttribute("MTFNewFirstSession",false) end
  return
 end
 s.Loaded=true;s.Data=d
 s.Cohort=kind=="New" and "New" or kind=="Existing" and "Existing" or "Unknown"
 p:SetAttribute("MTFDataLoaded",true)
 p:SetAttribute("MTFNewFirstSession",s.Cohort=="New")
 step(p,s,"Entry",2)
 custom(p,s,"Cohort","Profile:"..s.Cohort,true)
 M.CheckOre(p)
end
function M.LoadFailed(p)
 local s=states[p];if s and not s.Loaded then custom(p,s,"LoadFailed","LoadFailed",true) end
end
function M.Reset(p)
 local s=states[p];if not s then return end
 if new(s) then custom(p,s,"Reset","DebugReset") end
 s.Reset=true;s.Cohort="Reset";s.Broken.Combat=true;s.Broken.Ore=true
 p:SetAttribute("MTFNewFirstSession",false)
end
function M.Placed(p,c,revision)
 local s=states[p];if not s then return end
 s.PlacementCharacter=c;s.PlacementRevision=revision
 if new(s) and s.Return and s.Return.Character==c and revision>s.Return.Revision then
  custom(p,s,"ReturnArrived","ReturnLobbyArrived")
 end
end
function M.Playable(p,c,revision)
 local s=states[p]
 if not s or not s.Loaded or s.Progress.Entry>=3 or c~=living(p) or c~=s.PlacementCharacter
  or revision~=s.PlacementRevision or revision~=c:GetAttribute("SpawnPlacementRevision")
  or not c:GetAttribute("SpawnEngineReady") or not c:GetAttribute("MuscleScaleReady")
  or not c:GetAttribute("LobbySpawnPlaced") then return false end
 step(p,s,"Entry",3)
 if new(s) then step(p,s,"Combat",1) end
 return true
end
local floorCache,mapCache
function M.StagePresence(p,worldId,root)
 local s=states[p]
 if worldId~=1 or not new(s) or s.Progress.Combat>=2 or s.Broken.Combat or not root then return end
 local map=workspace:FindFirstChild("GeneratedMap")
 if mapCache~=map then floorCache=nil;mapCache=map end
 if not floorCache then
  local corridor=map and map:FindFirstChild("BattleCorridor");local stage=corridor and corridor:FindFirstChild("Stage01")
  if not stage then return end
  floorCache={}
  for _,o in stage:GetDescendants() do if o:IsA("BasePart") and o.Name=="Floor" then table.insert(floorCache,o) end end
 end
 for _,floor in floorCache do
  if floor.Parent then
   local v=floor.CFrame:PointToObjectSpace(root.Position);local h=floor.Size/2
   if math.abs(v.X)<=h.X and math.abs(v.Z)<=h.Z and v.Y>=h.Y-2 and v.Y<=h.Y+35 then
    M.Combat(p,worldId,1,2);return
   end
  end
 end
end
function M.Combat(p,worldId,stage,index)
 local s=states[p]
 if worldId~=1 or stage~=1 or not new(s) or index<2 or index>6 then return end
 if s.Skip or s.Broken.Combat then custom(p,s,"ObservedCombat"..index,"Observed:"..steps.Combat[index])
 else step(p,s,"Combat",index) end
end
function M.Skipped(p)
 local s=states[p];if not new(s) then return end
 s.Skip=true;s.Broken.Combat=true;custom(p,s,"StageSkip","StageSkip")
end
function M.Strength(p,route)
 local s=states[p];if not new(s) then return end
 if route~="Manual" and route~="AutoWalking" and route~="Treadmill" then route="Other" end
 custom(p,s,"FirstStrength","Strength:"..route)
end
function M.AutoOn(p)
 local s=states[p];if new(s) then custom(p,s,"AutoOn","UserAutoOn") end
end
function M.Equipped(p,id)
 local s=states[p];if new(s) and type(id)=="string" and id~="" then custom(p,s,"Equipped","DumbbellEquipped") end
end
function M.ReturnAccepted(p,id)
 local s=states[p];if not new(s) or s.Return then return end
 local c=p.Character
 s.Return={Id=id,Character=c,Revision=c and c:GetAttribute("SpawnPlacementRevision") or 0}
 custom(p,s,"ReturnAccepted","ReturnAccepted")
end
function M.ReturnCommitted(p,id,empty)
 local s=states[p];if not new(s) or not s.Return or s.Return.Id~=id then return end
 custom(p,s,"ReturnCommitted",empty and "ReturnEmptyNoSave" or "ReturnLootSaved")
end
local function selection(owned,unlocked)
 -- Pick a candidate from owned counts, then let the ordinary evaluator decide.
 local materials={};local count=0
 for _,ore in Ore.GetAvailable() do
  local n=math.min(Merge.Minimum-count,Counts.Count(owned[ore.Id or ore.OreId]) or 0)
  if n>0 then materials[ore.Id or ore.OreId]=n;count+=n end
  if count>=Merge.Minimum then break end
 end
 if count<Merge.Minimum then return nil end
 return Merge.Evaluate(materials,owned,unlocked)
end
function M.CheckOre(p)
 local s=states[p];if not new(s) or s.Progress.Ore>0 or s.Reset then return end
 local ds,d=data(p);if not ds or ds.StudioStartOverride then return end
 if selection(ds.Data.OwnedOres,d.HasReachedWorld2(p)) then
  step(p,s,"Ore",1)
  if p.Parent==Players then remote:FireClient(p,"RefreshOre",s.Id) end
 end
end
local function atMerge(p)
 local c=living(p);if not c then return false end
 local model=workspace:FindFirstChild("RestockShop")
 if p:GetAttribute("CurrentWorld")==2 then
  local map=workspace:FindFirstChild("World2Map");local area=map and map:FindFirstChild("TrainingArea")
  local displays=area and area:FindFirstChild("FacilityDisplays");model=displays and displays:FindFirstChild("MergeDisplay")
 end
 local area=model and model:FindFirstChild("Area")
 if not area or not area:IsA("BasePart") then return false end
 local v=area.CFrame:PointToObjectSpace(c.HumanoidRootPart.Position);local h=area.Size/2+Vector3.new(1,1,1)
 if area:IsA("Part") and area.Shape==Enum.PartType.Cylinder then return math.abs(v.X)<=h.X and v.Y*v.Y+v.Z*v.Z<=math.min(h.Y,h.Z)^2 end
 return math.abs(v.X)<=h.X and math.abs(v.Y)<=h.Y and math.abs(v.Z)<=h.Z
end
function M.OreView(p,payload,requestMaterials)
 local s=states[p]
 if not new(s) or type(payload)~="table" or payload.Session~=s.Id or payload.Character~=p.Character
  or type(payload.Sequence)~="number" or payload.Sequence%1~=0 or payload.Sequence<1 or payload.Sequence>1000000
  or (not requestMaterials and payload.Sequence<s.ClientSequence) or type(payload.Open)~="boolean" then return false end
 local ds,d=data(p)
 if not ds or payload.Token~=ds.ForgeToken or payload.Generation~=(ds.PetViewGeneration or 0) then return false end
 s.ClientSequence=math.max(s.ClientSequence,payload.Sequence)
 if not payload.Open then return false end
 if not atMerge(p) then return false end
 M.CheckOre(p)
 if s.Progress.Ore==0 then custom(p,s,"OreEarlyView","OreViewBeforeEligible");return false end
 if s.Progress.Ore==1 then step(p,s,"Ore",2) end
 local materials=payload.Materials
 if type(materials)~="table" then return true end
 local count=0;for id,n in materials do count+=1;if count>32 or type(id)~="string" or #id>64 or type(n)~="number" then return false end end
 local preview=Merge.Evaluate(materials,ds.Data.OwnedOres,d.HasReachedWorld2(p))
 if requestMaterials and Merge.Signature("MergeOre",materials)~=Merge.Signature("MergeOre",requestMaterials) then return false end
 if preview and s.Progress.Ore==2 then step(p,s,"Ore",3) end
 return preview~=nil
end
function M.OreRequested(p,op)
 local s=states[p];if not new(s) or op.Action~="MergeOre" then return end
 if s.MergeId or s.Broken.Ore then return end -- Keep the first accepted operation across duplicate observations.
 M.CheckOre(p)
 local valid=M.OreView(p,op.AnalyticsContext,op.Materials)
 if s.Progress.Ore==3 and valid then
  s.MergeId=op.Id;step(p,s,"Ore",4)
 else
  s.Broken.Ore=true
  custom(p,s,"ObservedMergeRequest","MergeRequestAccepted")
  custom(p,s,"OreNoView","OreRequestWithoutValidatedView")
 end
end
function M.OreCommitted(p,op)
 local s=states[p];if not new(s) or op.Action~="MergeOre" then return end
 if s.MergeFinished then return end;s.MergeFinished=true
 if s.MergeId==op.Id and not s.Broken.Ore then step(p,s,"Ore",5)
 else custom(p,s,"ObservedMergeCommit","MergeSaved") end
 p:SetAttribute("MTFOreFinished",true)
end
function M.Leaving(p)
 local s=states[p];if not s then return end
 for _,c in s.Connections do c:Disconnect() end
 if s.Death then s.Death:Disconnect() end
 states[p]=nil
end
-- All instrumentation entry points fail closed without affecting game success.
for key,fn in M do
 M[key]=function(...)
  local ok,value=pcall(fn,...)
  if not ok then return false end
  return value
 end
end
remote.OnServerEvent:Connect(function(p,action,payload,...)
 local s=states[p]
 if not s or select("#",...)~=0 or type(payload)~="table" or payload.Session~=s.Id then return end
 local now=os.clock();s.ClientTokens=math.min(8,s.ClientTokens+(now-s.ClientAt)*4);s.ClientAt=now
 if s.ClientTokens<1 then return end;s.ClientTokens-=1
 if action=="Playable" and payload.HUDReady==true and payload.ControlsReady==true and payload.LoadingGone==true then
  M.Playable(p,payload.Character,payload.Revision)
  remote:FireClient(p,"PlayableAck",s.Id,s.Progress.Entry>=3)
 elseif action=="OreView" then M.OreView(p,payload) end
end)
return M
