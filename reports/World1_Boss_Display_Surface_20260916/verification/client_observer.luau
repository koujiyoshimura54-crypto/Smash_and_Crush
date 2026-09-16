-- Temporary Play observer; UI/HP evidence only, no user data.
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local P=game.Players.LocalPlayer
local config=require(RS.Config.BossDisplayConfig)
local probe=Instance.new("Folder");probe.Name="BossDisplayQAClient";probe.Parent=P.PlayerGui
local events={}
local function snapshot(d)
 local n=d.Stage or d.MajorStage or P:GetAttribute("CurrentStage") or 1
 local e=workspace.Enemies:FindFirstChild(("Stage%02d_Enemy"):format(n))
 local g=e and e:FindFirstChild("PersonalGauge",true)
 local surface=g and g.Adornee
 local nextWall=n<10 and workspace.GeneratedMap.BattleCorridor:FindFirstChild(("Stage%02d"):format(n+1))
 local w=nextWall and nextWall:FindFirstChild(("Stage%d.1"):format(n+1))
 local ws=w and w.Wall.StageSurface
 return {type=d.Type,stage=n,current=d.Current,max=d.Max,enabled=g and g.Enabled,uiHP=g and g.HPLabel.Text,surfaceTransparency=surface and surface.Transparency,nextWallEnabled=ws and ws.Enabled}
end
RS.Remotes.GameRemotes.CombatState.OnClientEvent:Connect(function(d)
 if d.Type=="BossGauge" or d.Type=="BossInitialize" or d.Type=="BossRecommendation" or d.Type=="EnemyDefeated" or d.Type=="StageCleared" or d.Type=="WallCleared" then
  task.defer(function()
   table.insert(events,snapshot(d))
   probe:SetAttribute("Events",Http:JSONEncode(events))
  end)
 end
end)
probe:GetAttributeChangedSignal("Action"):Connect(function()
 local action=probe:GetAttribute("Action")
 if action=="offset" then config.VerticalOffset=2
 elseif action=="ratio" then config.HeightRatio=.7
 elseif action=="gap" then config.SurfaceOffset=1
 elseif action=="alpha" then config.Transparency=.6
 elseif action=="override" then config.StageOverrides[1]={VerticalOffset=3}
 elseif action=="restore" then
  config.VerticalOffset=0;config.HeightRatio=.6;config.SurfaceOffset=.5;config.Transparency=.5;config.StageOverrides[1]=nil
 end
end)
