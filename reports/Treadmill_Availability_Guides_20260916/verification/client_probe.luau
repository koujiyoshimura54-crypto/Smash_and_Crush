local p=game.Players.LocalPlayer
local out={rebirth=p:GetAttribute("RebirthCount"),active=p:GetAttribute("TrainingTreadmill"),training=p:GetAttribute("IsTraining"),guides={},billboards={}}
for _,g in p.PlayerGui.TreadmillGuides:GetChildren() do
 local s=g.Adornee
 out.guides[g.Name]={enabled=g.Enabled,available=p:GetAttribute("TreadmillAvailable_"..g.Name),y=g.Clip.MovingChevrons.Position.Y.Offset,collide=s.CanCollide,touch=s.CanTouch,query=s.CanQuery}
end
for _,g in p.PlayerGui.TreadmillMultiplierBillboards:GetChildren() do out.billboards[g.Name]={enabled=g.Enabled,maxDistance=g.MaxDistance} end
return game.HttpService:JSONEncode(out)
