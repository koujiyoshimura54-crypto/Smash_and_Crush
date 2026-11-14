-- Native UI observers/control fixtures; normal UI clicks are sent by the Studio input tool.
local RS=game.ReplicatedStorage;local q=RS:WaitForChild('__PostOreQA')
local p=game.Players.LocalPlayer
local Forge=require(RS.Modules.ForgeClient)
local Coordinator=require(RS.Modules.TutorialPresentationCoordinator)
local competition={}
local frames=0;game:GetService('RunService').RenderStepped:Connect(function()frames+=1 end)
local call=Instance.new('BindableFunction');call.Name='Client';call.Parent=q
call.OnInvoke=function(action)
 local pg=p.PlayerGui
 if action=='MoveShop' then
  local c=p.Character;local r=c.HumanoidRootPart;local a=workspace.RestockShop.Area
  c.Humanoid:MoveTo(Vector3.new(a.Position.X,r.Position.Y,a.Position.Z))
 elseif action=='Menu'then pg.StrengthGui.InventoryPanel.Visible=true
 elseif action=='CloseMenu'then pg.StrengthGui.InventoryPanel.Visible=false
 elseif action=='Competition'then Coordinator.Acquire(competition)
 elseif action=='ReleaseCompetition'then Coordinator.Release(competition)
 elseif action=='EarlyMerge'then Forge.Refresh();task.wait(.2);return Forge.Request('MergeOre',{Materials={ORE_001=2}})
 elseif action~='Inspect'then error('Unknown action')end
 local overlay=pg:FindFirstChild('OreMergeTutorialGui')
 local line=overlay and overlay.Canvas.Notification.Stack:FindFirstChild('PinnedLine')
 return {Frames=frames,Viewport=tostring(workspace.CurrentCamera.ViewportSize),Step=overlay and overlay:GetAttribute('Step'),
  Line=line and line.Message.Text,Alpha=line and line.Message.TextTransparency,Size=line and tostring(line.Message.AbsoluteSize),
  Shop=pg.MergeShopGui.MergeShopPanel.Visible,Snapshot=require(RS.Modules.FirstPlayAnalyticsClient).Snapshot()}
end
