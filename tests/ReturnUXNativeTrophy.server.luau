local S=game.ServerScriptService.Services local D=require(S.PlayerDataService)
local E=require(game.ServerScriptService.World.EnemyManager) local T=require(S.TrophyRewardService)
local R=require(S.RunInventoryService) local B=require(S.RunItemBankService) local I=require(S.ItemService)
local p=game.Players:GetPlayers()[1] local rows={}
local function waitFor(f,n) local t=os.clock()+n repeat if f() then return true end task.wait() until os.clock()>t return false end
local ok,err=xpcall(function()
 for _,case in {{World=1},{World=2},{World=1,Retry=true}} do
  local w=case.World
  assert(waitFor(function()return p.Character and p.Character.Humanoid.Health>0 and p.Character:GetAttribute("MuscleScaleReady")end,15))
  E.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p) p:SetAttribute("CurrentWorld",w)
  E.ForWorld(w).Activate(p) task.wait(.3) E.ForWorld(w).StartRun(p,1)
  local ps=E.ForWorld(w).GetPlayerState(p)
  local id="GLOVE_EPIC_FIRE" local owned=I.GetItemCount(p,id)
  if w==1 then assert(R.TryAddDrop(p,ps.RunInventoryId,game.HttpService:GenerateGUID(false),id)) assert(R.TryAddOreDrop(p,ps.RunInventoryId,game.HttpService:GenerateGUID(false),"ORE_001")) end
  ps.Defeated[1]=true
  local win=p:GetAttribute("Win") local trophy=T.ForWorld(w)
  assert(trophy.Spawn(p,1))
  local calls=0 local old=B.Commit
  if case.Retry then B.Commit=function(...) calls+=1 if calls==1 then require(game.ReplicatedStorage.__ReturnMemory).FailAfter=1 end return old(...) end end
  local map=workspace[w==1 and "GeneratedMap" or "World2Map"]
  local pad=map.BattleCorridor.Stage01.TrophyNormalButton.Handle
  local root=p.Character.HumanoidRootPart root.Anchored=false root.CFrame=pad.CFrame*CFrame.new(0,1.5,0)
  local start=workspace:GetServerTimeNow()
  assert(waitFor(function()return p:GetAttribute("Win")>win end,15),"credit")
  local credit=workspace:GetServerTimeNow()-start
  assert(waitFor(function()return (root.Position-trophy.GetLobbySpawn().Position).Magnitude<15 and not root.Anchored end,15),"arrival")
  case.Elapsed=workspace:GetServerTimeNow()-start case.Credit=credit case.WinDelta=p:GetAttribute("Win")-win case.ItemDelta=I.GetItemCount(p,id)-owned case.Bag=p:GetAttribute("RunInventoryCount") case.BankAttempts=calls
  B.Commit=old table.insert(rows,case) task.wait(.3)
 end
end,debug.traceback)
script:SetAttribute("Result",game.HttpService:JSONEncode({OK=ok,Error=not ok and err or nil,Rows=rows}))
