local out={surfaces={},guis={}}
local count=0
for _,s in workspace.PersonalCombatVisuals:GetChildren() do if s.Name=="BossDisplaySurface" then
 if s.Transparency<1 then count+=1 end
 assert(s.Anchored and not s.CanCollide and not s.CanTouch and not s.CanQuery)
 local n=s:GetAttribute("BossStage")
 local e=workspace.Enemies:FindFirstChild(("Stage%02d_Enemy"):format(n))
 local g=e and e:FindFirstChild("PersonalGauge",true)
 local wall=n<10 and workspace.GeneratedMap.BattleCorridor:FindFirstChild(("Stage%02d"):format(n+1)):FindFirstChild(("Stage%d.1"):format(n+1)).Wall or workspace.GeneratedMap.BattleCorridor.Stage10.Stage10BoundaryWall
 local name=g and g.BossName
 local uiWorldCenter=g and s.Position.Y+s.Size.Y/2-(g.HPBar.Position.Y.Scale+g.HPBar.Size.Y.Scale/2)*s.Size.Y
 table.insert(out.surfaces,{stage=n,transparency=s.Transparency,size={s.Size.X,s.Size.Y,s.Size.Z},position={s.Position.X,s.Position.Y,s.Position.Z},wallPosition={wall.Position.X,wall.Position.Y,wall.Position.Z},wallSize={wall.Size.X,wall.Size.Y,wall.Size.Z},bossHeight=e:GetAttribute("BossDisplayHeight"),bossBase=e:GetAttribute("BossDisplayBaseY"),uiCenterY=uiWorldCenter,enabled=g and g.Enabled,hp=g and g.HPLabel.Text,bossName=name and name.Text,stageText=g and g.StageNumber.Text,nameTopScale=name and name.Position.Y.Scale})
end end
out.visibleCount=count
out.events=game.Players.LocalPlayer.PlayerGui.BossDisplayQAClient:GetAttribute("Events")
out.fighting=game.Players.LocalPlayer:GetAttribute("IsFighting")
return game:GetService("HttpService"):JSONEncode(out)
