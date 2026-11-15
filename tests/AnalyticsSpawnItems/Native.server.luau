assert(game.PlaceId==126576845524886 and game.GameId==10765181857 and game:GetService("RunService"):IsStudio())
local RS=game.ReplicatedStorage;assert(RS:FindFirstChild("__ThreeFixMemory"))
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService);local L=require(S.LobbySpawnService);local T=require(S.FirstPlayAnalyticsTransport)
local I=require(S.ItemService);local Master=require(RS.Config.ItemMaster);local Mem=require(RS.__ThreeFixMemory)
local q=RS.__ThreeFixQA;local events={}
local function watch(p)
 p.CharacterAdded:Connect(function(c)
  table.insert(events,{Event="CharacterAdded",At=os.clock()})
  for _,key in {"SpawnEngineReady","MuscleScaleReady","LobbySpawnPlaced"}do
   c:GetAttributeChangedSignal(key):Connect(function()table.insert(events,{Event=key,Value=c:GetAttribute(key),At=os.clock()})end)
  end
 end)
end
game.Players.PlayerAdded:Connect(watch);for _,p in game.Players:GetPlayers()do watch(p)end
local call=Instance.new("BindableFunction");call.Name="Server";call.Parent=q
call.OnInvoke=function(action,value)
 local p=game.Players:GetPlayers()[1];local s=p and D.Get(p)
 if action=="SeedItems"then
  assert(s and s.Loaded)
  local deltas={};for id in Master.GetAll()do deltas[id]=4 end
  assert(D.ChangeItemCounts(p,deltas))
  D.SetWin(p,100000);D.MarkWorld1Cleared(p);D.UnlockWorld(p,2);D.MarkWorld2Reached(p)
 elseif action=="Die"then p.Character.Humanoid.Health=0
 elseif action=="World"then
  assert(value==1 or value==2);p:SetAttribute("CurrentWorld",value)
  return {Loaded=L.LoadCharacter(p),World=value}
 elseif action=="Equip"then return {Result=table.pack(I.EquipItem(p,value))}
 elseif action=="KickDuringLoad"then
  task.spawn(function()q:SetAttribute("KickLoadResult",L.LoadCharacter(p))end)
  task.delay(.03,function()p:Kick("Isolated QA departure during character loading")end)
 elseif action~="Inspect"then error("Unknown action")end
 local c=p and p.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
 local rows=T.StudioRecords();local invalid={}
 for _,e in rows do for k,v in e.Fields do if #v>50 then table.insert(invalid,{Name=e.Name,Field=k,Bytes=#v})end end end
 return {Loaded=s and s.Loaded,World=p and p:GetAttribute("CurrentWorld"),Health=c and c:FindFirstChildOfClass("Humanoid")and c.Humanoid.Health,
  Position=root and tostring(root.Position),Anchored=root and root.Anchored,Engine=c and c:GetAttribute("SpawnEngineReady"),
  Scale=c and c:GetAttribute("MuscleScaleReady"),Placed=c and c:GetAttribute("LobbySpawnPlaced"),Events=events,Rows=rows,
  InvalidFields=invalid,MemoryWrites=Mem.Writes,Owned=s and s.Data.OwnedItems,Equipped=s and s.Data.EquippedItems,Win=p and p:GetAttribute("Win")}
end
