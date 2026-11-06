local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local P=require(S.LobbySpawnService)
local B=require(S.RunItemBankService)
local R=require(S.RunInventoryService)
local variants={{"Before",require(game.ServerScriptService.__BeforeTrophy)},{"After",require(game.ServerScriptService.__AfterTrophy)}}
local latency=false
local E=require(game.ServerScriptService.World.EnemyManager)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local results={}
local row
local function stamp(k) if row and not row[k] then row[k]=workspace:GetServerTimeNow()-row.Start end end
for _,entry in {{D,"SetWin","Credit"},{B,"Commit","Bank"},{P,"StreamLobby","Stream"},{P,"MoveToLobby","Move"}} do
 local old=entry[1][entry[2]]
 entry[1][entry[2]]=function(...) stamp(entry[3].."Start") if latency and entry[3]=="Bank" then task.wait(.4) elseif latency and entry[3]=="Stream" then task.wait(.3) end local a=table.pack(old(...)) stamp(entry[3].."End") return table.unpack(a,1,a.n) end
end
local function waitFor(f,t) local stop=os.clock()+(t or 15) repeat if f() then return true end task.wait() until os.clock()>stop return false end
local ok,err=xpcall(function()
 assert(waitFor(function()return D.IsLoaded(p) and p.Character and p.Character:GetAttribute("MuscleScaleReady")end,30),"load timeout")
 D.SetAutoTapEnabled(p,false)
 for _,variant in variants do
 local T=variant[2]
 for _,delayed in {false,true} do latency=delayed
 for _,w in {1,2} do
  E.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p)
  p:SetAttribute("CurrentWorld",w)
  E.ForWorld(w).Activate(p)
  local c=p.Character local root=c.HumanoidRootPart
  root.Anchored=false
  local map=workspace[w==1 and "GeneratedMap" or "World2Map"]
  local trophy=T.ForWorld(w)
  trophy.Initialize(map,game.ReplicatedStorage.Remotes.GameRemotes[w==1 and "CombatState" or "World2CombatState"],function(pl) E.ForWorld(w).InitializePlayer(pl) end,function()return true end)
  if w==1 then
   local id=R.Reset(p,true)
   local master=require(game.ReplicatedStorage.Config.ItemMaster)
   local item=next(master.GetAll())
   assert(R.TryAddDrop(p,id,"qa-item",item))
   assert(R.TryAddOreDrop(p,id,"qa-ore","ORE_001"))
  end
  assert(trophy.Spawn(p,1))
  row={Variant=variant[1],InjectedLatency=latency,World=w,Start=workspace:GetServerTimeNow(),WinBefore=p:GetAttribute("Win")}
  table.insert(results,row)
  local pad=map.BattleCorridor.Stage01.TrophyNormalButton.Handle
  root.CFrame=pad.CFrame*CFrame.new(0,1.5,0)
  stamp("Contact")
  assert(waitFor(function()return row.MoveEnd~=nil end,35),"move timeout")
  assert(waitFor(function()return not root.Anchored end,15),"ack timeout")
  stamp("Controllable") row.WinAfter=p:GetAttribute("Win")
  row.BagCount=p:GetAttribute("RunInventoryCount")
  trophy.Clear(p)
  task.wait(.5)
 end
 end
 end
end,debug.traceback)
script:SetAttribute("Result",game.HttpService:JSONEncode({OK=ok,Error=not ok and err or nil,Rows=results}))
