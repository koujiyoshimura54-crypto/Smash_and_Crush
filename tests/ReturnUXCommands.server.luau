local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService) local R=require(S.RunInventoryService) local B=require(S.RunItemBankService)
local P=require(S.LobbySpawnService) local E=require(game.ServerScriptService.World.EnemyManager)
local Items=require(S.ItemService) local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
repeat task.wait() until D.IsLoaded(p) and p.Character and p.Character:GetAttribute("MuscleScaleReady")
D.SetAutoTapEnabled(p,false)
local ids={} for id,item in Master.GetAll() do if (item.WorldId or 1)==1 then table.insert(ids,id) end end table.sort(ids)
local run,item,character
local qa=Instance.new("BindableFunction") qa.Name="Command" qa.Parent=script
qa.OnInvoke=function(action,arg)
 if action=="Setup" then
  E.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p)
  p:SetAttribute("CurrentWorld",1) E.ForWorld(1).StartRun(p,1)
  character=p.Character character.HumanoidRootPart.Anchored=false
  local pad=workspace.GeneratedMap.BattleCorridor.Stage01.TrophyNormalButton.Handle
  character.HumanoidRootPart.CFrame=pad.CFrame*CFrame.new(0,4,-12)
  run=R.Reset(p,true) item=ids[arg or 1]
  assert(R.TryAddDrop(p,run,game.HttpService:GenerateGUID(false),item))
  assert(R.TryAddOreDrop(p,run,game.HttpService:GenerateGUID(false),"ORE_001"))
  game.ReplicatedStorage.Remotes.EnemyDropGachaResult:FireClient(p,{Id=game.HttpService:GenerateGUID(false),OwnerUserId=p.UserId,Outcome="ITEM",ItemId=item,WorldId=1,RunId=run,Stage=1})
  return {Item=item,Bag=p:GetAttribute("RunInventoryCount"),Owned=Items.GetItemCount(p,item)}
 elseif action=="Bank" then
  local ok,reason=B.Commit(p,run) return {OK=ok,Reason=reason,Owned=Items.GetItemCount(p,item),Bag=p:GetAttribute("RunInventoryCount")}
 elseif action=="Return" then
  local q=P.StreamLobby(p,p.Character,1) assert(q)
  return P.MoveToLobby(p,p.Character,1)
 elseif action=="Direct" then
  local id=ids[arg or 9] assert(Items.AddItem(p,id,1))
  game.ReplicatedStorage.Remotes.ItemPurchaseRequest:FireClient(p,{Success=true,Code="Purchased",ItemId=id,State={Loaded=true,OwnedItems=Items.GetOwnedItems(p)}})
  return id
 elseif action=="Die" then
  character=p.Character character.Humanoid.Health=0
  task.wait(.2)
  return {Lost=character:GetAttribute("BattleBagLostCount"),Resolved=character:GetAttribute("BattleBagDeathResolved"),Bag=p:GetAttribute("RunInventoryCount")}
 elseif action=="Empty" then R.Reset(p,true) return true
 elseif action=="World" then
  E.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p)
  p:SetAttribute("CurrentWorld",arg) E.ForWorld(arg).Activate(p)
  local q=P.StreamLobby(p,p.Character,arg) assert(q) return P.MoveToLobby(p,p.Character,arg)
 elseif action=="Fault" then
  local mem=require(game.ReplicatedStorage.__ReturnMemory)
  local originals={} local calls=0
  for _,store in pairs(mem.Stores) do
   originals[store]=store.UpdateAsync
   store.UpdateAsync=function(self,...)
    calls+=1
    if calls==arg then mem.FailAfter=1 end
    return originals[self](self,...)
   end
  end
  local ok,why=B.Commit(p,run)
  for store,fn in pairs(originals) do store.UpdateAsync=fn end
  return {OK=ok,Reason=why,Calls=calls,Owned=Items.GetItemCount(p,item),Bag=p:GetAttribute("RunInventoryCount")}
 elseif action=="Replay" then
  local state={Loaded=true,OwnedItems=Items.GetOwnedItems(p)}
  game.ReplicatedStorage.Remotes.RunLootBanked:FireClient(p,state)
  game.ReplicatedStorage.Remotes.RunLootBanked:FireClient(p,state)
  return true
 elseif action=="Trophy" then
  local w=arg E.ForWorld(w).StartRun(p,1)
  local ps=E.ForWorld(w).GetPlayerState(p) ps.Defeated[1]=true
  local t=require(S.TrophyRewardService).ForWorld(w)
  local win=p:GetAttribute("Win") assert(t.Spawn(p,1))
  local pad=workspace[w==1 and "GeneratedMap" or "World2Map"].BattleCorridor.Stage01.TrophyNormalButton.Handle
  p.Character.HumanoidRootPart.CFrame=pad.CFrame*CFrame.new(0,1.5,0)
  local stop=os.clock()+12 repeat task.wait() until p:GetAttribute("Win")>win or os.clock()>stop
  task.wait(1)
  return {Before=win,After=p:GetAttribute("Win"),Anchored=p.Character.HumanoidRootPart.Anchored,Root=tostring(p.Character.HumanoidRootPart.Position)}
 end
end
script:SetAttribute("Ready",true)
