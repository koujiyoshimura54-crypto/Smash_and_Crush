-- Temporary native Studio QA. Install only with every datastore/payment/badge dependency mocked.
local Players=game:GetService('Players')
local RS=game.ReplicatedStorage
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Items=require(game.ServerScriptService.Services.ItemMergeService)
local Forge=require(game.ServerScriptService.Services.ForgeService)
local Pet=require(RS.Modules.Pet)
local Http=game:GetService('HttpService')
local memory=require(RS.__MergeY01Memory)
local bridge=Instance.new('BindableFunction');bridge.Name='__MergeY01Server';bridge.Parent=game.ServerScriptService
local function player() return assert(Players:GetPlayers()[1]) end
local function state()
 local p=player();local s=Data.Get(p)
 return {Items=Items.GetState(p),Pets=Data.GetPetState(p),Forge=Forge.State(p),World=p:GetAttribute('CurrentWorld'),
  SavedArrival=s.Data.World2Visited,EffectiveArrival=Data.HasReachedWorld2(p),SessionArrival=s.World2VisitedThisPlay,
  Override=s.StudioStartOverride~=nil,Writes=memory.Writes,Win=p:GetAttribute('Win'),
  ArrivalReset=require(game.ServerScriptService.Config.DataStoreConfig).ResetWorld2ArrivalOnStudioPlay}
end
bridge.OnInvoke=function(action,arg)
 if action=='Ready' then return bridge:GetAttribute('Ready')==true end
 local p=player();local s=Data.Get(p)
 if action=='State' then return state() end
 if action=='Gate' then
  local gate=arg=='ToWorld2' and workspace:FindFirstChild(require(RS.Config.WorldGateConfig).GateName)
   or workspace.World2Map.TrainingArea.World1ReturnGate
  local root=p.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=gate.WorldGateTrigger.CFrame
  return true
 end
 if action=='MergeArea' then local root=p.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=workspace.RestockShop.Area.CFrame+Vector3.new(0,3,0);return true end
 if action=='RejectLocked' then
  local before=Items.GetState(p);local ok,why=Items.MergeItem(p,{RequestId=Http:GenerateGUID(false),SessionToken=before.SessionToken,Sequence=before.NextSequence,Materials={W2_GLOVE_RARE_FIRE=3}})
  assert(not ok and why=='WorldNotReached',why);assert(Items.GetState(p).OwnedItems.W2_GLOVE_RARE_FIRE==before.OwnedItems.W2_GLOVE_RARE_FIRE)
  return {Success=ok,Code=why,Unchanged=true}
 end
 if action=='SavedArrivalReset' then
  -- Test the already-saved flag under the existing per-Play reset, without disabling it.
  s.Data.World2Visited=true;assert(not Data.HasReachedWorld2(p));return state()
 end
 if action=='Protection' then
  local pets=Data.GetPetState(p);local PM=require(RS.Modules.PetMerge)
  local failures={}
  for _,case in {{'Duplicate',{'dog-eligible-1','dog-eligible-1'},'InvalidPetMaterials'},
   {'Unowned',{'not-owned','dog-eligible-1'},'PetNotMergeable'},
   {'Protected',{'dog-protected','dog-eligible-1'},'PetProtected'},
   {'Equipped',{'dog-equipped','dog-eligible-1'},'PetEquipped'}} do
   local value,why=PM.Evaluate(pets,case[2]);assert(not value and why==case[3],tostring(why));failures[case[1]]=why
  end
  return failures
 end
 if action=='Save' then return Data.Save(p) end
 error('Unknown QA action '..action)
end
local control=Instance.new('RemoteFunction');control.Name='__MergeY01Control';control.Parent=RS
control.OnServerInvoke=function(_,...)return bridge:Invoke(...)end
local function prepare(p)
 while not Data.IsLoaded(p) or not p.Character or not p.Character:FindFirstChild('HumanoidRootPart') do task.wait(.1) end
 task.wait(3);assert(Data.WaitForSave(p,10))
 local s=Data.Get(p);assert(not s.PendingItemMutation)
 -- Fixture only. Keep the configured StudioStartOverride and its restore source untouched.
 local owned={}
 local Master=require(RS.Config.ItemMaster)
 for id,item in pairs(Master.GetAll()) do if item.Element=='Fire' then owned[id]=8 end end
 s.Data.OwnedItems=owned
 s.Data.Pets={Version=1,Revision=0,LastRequestId='',Owned={['dog-equipped']='Dog',['dog-protected']='Dog',
  ['dog-eligible-1']='Dog',['dog-eligible-2']='Dog',['dog-eligible-3']='Dog',
  ['cat-1']='Grey Cat',['cat-2']='Grey Cat',['cat-3']='Grey Cat',
  ['bear-1']='Bear',['bear-2']='Bear',['slime-1']='Slime',['camel-1']='Camel',
  ['cow-1']='Cow',['cow-2']='Cow',['giraffe-1']='Giraffe'},
  Equipped={'dog-equipped'},Protected={['dog-protected']=true},LastResults={}}
 local variant='W2 Dog'
 if Pet.model(variant) then s.Data.Pets.Owned['performance-variant']=variant end
 local normalized,why=Pet.NormalizeState(s.Data.Pets);assert(normalized,why);s.Data.Pets=normalized
 if s.StudioStartOverride then s.StudioPetPreview=normalized end
 Pet.Publish(p,normalized)
 s.Data.OwnedOres={};for _,ore in ipairs(require(RS.Config.OreConfig).GetAvailable()) do s.Data.OwnedOres[ore.Id]=12 end
 Data.SetWin(p,100000);Data.SetAutoTapEnabled(p,false);Data.CompleteTutorial(p);Data.UnlockWorld(p,2)
 assert(not Data.HasReachedWorld2(p),'Fixture must start with arrival locked')
 Data.Save(p)
 -- Ordinary Save deliberately preserves transaction-owned fields. Seed those fields in
 -- the isolated store too, retaining the real session-ownership metadata.
 local storeName=require(game.ServerScriptService.Config.DataStoreConfig).GetName('PlayerData_v1')
 memory.DataStoreService:GetDataStore(storeName):UpdateAsync('Player_'..p.UserId,function(old,info)
  for _,key in {'OwnedItems','OwnedOres','Pets'} do old[key]=s.Data[key] end
  return old,info:GetUserIds(),info:GetMetadata()
 end)
 local root=p.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=workspace.RestockShop.Area.CFrame+Vector3.new(0,3,0)
 bridge:SetAttribute('Ready',true)
end
Players.PlayerAdded:Connect(function(p)task.spawn(prepare,p)end)
for _,p in Players:GetPlayers() do task.spawn(prepare,p) end
