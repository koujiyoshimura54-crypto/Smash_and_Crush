-- Run in the native client VM after __OreVisualQA:Invoke("Narrow").
-- Uses the temporary owner-style values described in the implementation record.
local p=game.Players.LocalPlayer;local q=p.PlayerGui.__OreVisualQA
local v=q:Invoke("View");local o=p.PlayerGui.OreMergeTutorialGui;local h=o.Canvas.Highlight
v:Clear();task.wait(.3)
assert((h.AbsolutePosition-(v.List.AbsolutePosition-Vector2.new(10,8))).Magnitude<2)
v:ActivateMaterial("ORE_001");v:ActivateMaterial("ORE_001");task.wait(.3)
assert(o:GetAttribute("Step")=="Merge",o:GetAttribute("Step"))
assert((h.AbsolutePosition-(v.Merge.AbsolutePosition-Vector2.new(10,8))).Magnitude<2)
v:RemoveMaterial("ORE_001:2");task.wait(.3);assert(o:GetAttribute("Step")=="AddOres")
q:Invoke("Resize");task.wait(.3)
assert((h.AbsolutePosition-(v.List.AbsolutePosition-Vector2.new(10,8))).Magnitude<2)
v:ActivateMaterial("ORE_001");task.wait(.3)
assert((h.AbsolutePosition-(v.Merge.AbsolutePosition-Vector2.new(10,8))).Magnitude<2)
assert(h.Outline.Thickness==5 and h.Corner.CornerRadius.Offset==12)
local m=o.Canvas.Message
assert(m.AbsolutePosition.Y>=o.Canvas.AbsolutePosition.Y)
assert(m.AbsolutePosition.X+m.AbsoluteSize.X<v.Root.Top.Close.AbsolutePosition.X+2)
p:SetAttribute("__OreNarrowPassed",true);print("[OreTutorial QA] 460x560 and 400x520 native selection/resize/focus passed")
