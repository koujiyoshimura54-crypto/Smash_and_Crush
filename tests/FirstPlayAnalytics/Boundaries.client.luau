-- Temporary native-client driver. Actual UI callbacks; no OS input.
local p=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local q=RS:WaitForChild('__EarlyQARoute')
local Forge=require(RS.Modules.ForgeClient)
local Telemetry=require(RS.Modules.FirstPlayAnalyticsClient)
q.Call.OnClientInvoke=function(action)
 local ok,value=xpcall(function()
  if action=='Open' then
   local root=p.Character.HumanoidRootPart;local hum=p.Character.Humanoid
   local at=workspace.RestockShop.Area.Position;local deadline=os.clock()+20
   while (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(at.X,0,at.Z)).Magnitude>2 do
    assert(os.clock()<deadline,'Merge walk timeout');hum:MoveTo(Vector3.new(at.X,root.Position.Y,at.Z));task.wait(.1)
   end
   hum:MoveTo(root.Position)
   repeat task.wait(.1)until _G.__FirstAnalyticsMergeView and _G.__FirstAnalyticsMergeView.Root.Visible or os.clock()>deadline
   local v=assert(_G.__FirstAnalyticsMergeView);assert(v.Root.Visible);v:SelectTab('Ore');Forge.Refresh();task.wait(.5)
   return Telemetry.Snapshot()
  elseif action=='Select' then
   Forge.Refresh();local v=_G.__FirstAnalyticsMergeView;v:SelectTab('Ore');task.wait(.3)
   v:ActivateMaterial('ORE_001');v:ActivateMaterial('ORE_001');task.wait(.4);return Telemetry.Snapshot()
  elseif action=='Submit' then _G.__FirstAnalyticsMergeView:SubmitItem();return true
  elseif action=='Duplicates' then
   local snap=Telemetry.Snapshot()
   for _=1,30 do RS.Remotes.FirstPlayAnalytics:FireServer('OreView',snap)end
   RS.Remotes.FirstPlayAnalytics:FireServer('Forbidden',snap)
   snap.Session='invalid';RS.Remotes.FirstPlayAnalytics:FireServer('OreView',snap)
   return true
  elseif action=='Tap' then RS.Remotes.AutoTapRequest:FireServer('Tap');return true
  elseif action=='Status' then return {New=p:GetAttribute('MTFNewFirstSession'),Loaded=p:GetAttribute('MTFDataLoaded'),Auto=p:GetAttribute('AutoTapEnabled'),Strength=p:GetAttribute('Strength')}end
 end,debug.traceback)
 return {OK=ok,Value=ok and value or nil,Error=not ok and value or nil}
end
