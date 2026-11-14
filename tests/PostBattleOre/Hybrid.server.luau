-- HYBRID test: actual native Forge/ownership/persistence, explicitly synthetic display observations.
assert(game:GetService('RunService'):IsStudio()and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local q=game.ReplicatedStorage.__PostOreQA
local S=game.ServerScriptService.Services
local A=require(S.FirstPlayAnalyticsService);local F=require(S.ForgeService)
local D=require(S.PlayerDataService);local T=require(S.FirstPlayAnalyticsTransport)
local sequence=100;local op
local call=Instance.new('BindableFunction');call.Name='Hybrid';call.Parent=q
call.OnInvoke=function(action)
 local p=game.Players:GetPlayers()[1];local c=p.Character;local r=c.HumanoidRootPart
 if action=='Prefix' then
  assert(not r.Anchored and c.Humanoid.Health>0,'Await actual respawn placement acknowledgement')
  local area=workspace.RestockShop.Area
  c:PivotTo(CFrame.new(area.Position.X,r.Position.Y,area.Position.Z));r.AssemblyLinearVelocity=Vector3.zero
  local s=F.State(p);sequence+=1
  local payload={Session=p:GetAttribute('MTFSession'),PostBattleToken=p:GetAttribute('MTFPostBattleToken'),Character=c,Revision=c:GetAttribute('SpawnPlacementRevision'),
   Token=s.Token,Generation=s.Generation,Sequence=sequence,ViewRevision=100,Rendered=true,Ready=true,HUDReady=true,ControlsReady=true,LoadingGone=true,
   GuideShown=true,Open=true,Tab='Ore',Selling=false,Materials={ORE_001=2}}
  A.OreView(p,payload)
  op={Action='MergeOre',Id=game.HttpService:GenerateGUID(false),Materials={ORE_001=2},Token=s.Token,Generation=s.Generation,Sequence=s.Sequence+1,AnalyticsContext=payload}
 elseif action=='Merge' then return F.Request(p,assert(op))
 elseif action=='Resolve'then return D.ResolveItemMutation(p)
 elseif action=='FailAnalytics'then T.StudioFailNext(1)
 else error('Unknown hybrid action')end
 return 'Synthetic display prefix only; not rendered UI evidence'
end
