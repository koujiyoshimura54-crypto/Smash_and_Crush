local RS=game:GetService("ReplicatedStorage")
local P=game.Players.LocalPlayer
local out={checks=0,cases={}}
local oldStrength,oldLevel
local changed=false
local function eq(a,b,label) assert(a==b,label..": "..tostring(a).." != "..tostring(b));out.checks+=1 end
local ok,err=pcall(function()
 local r=RS:WaitForChild("LevelCurveAuditResult",30) assert(r,"server probe timeout")
 local gui=P:WaitForChild("PlayerGui",30):WaitForChild("StrengthGui",30)
 local hud=gui:WaitForChild("StrengthLevelHUD",30)
 local L=require(RS.Config.LevelRequirements) local F=require(RS.Modules.NumberFormat)
 task.wait(2)
 oldStrength=P:GetAttribute("Strength");oldLevel=P:GetAttribute("Level");changed=true
 for _,level in ipairs({50,51,60,75,90,105,120,140,155,170,185,200,201,9999,10000}) do
  for _,fraction in ipairs({0,0.5}) do
   local t=L.GetRequiredStrength(level) local n=L.GetRequiredStrength(level+1)
   local strength=t+(n-t)*fraction
   P:SetAttribute("Strength",strength);P:SetAttribute("Level",L.CalculateLevel(strength))
   task.wait(0.12)
   eq(P:GetAttribute("Strength"),strength,"threshold calculation does not alter Strength")
   eq(hud.LevelPanel.Level.Text,"Lv."..level,"HUD level")
   eq(hud.Strength.Text,F.Format(strength).." Strength","HUD Strength")
   eq(hud.LevelPanel.ProgressText.Text,F.Format(strength).." / "..F.Format(n),"HUD progress text")
   local want=level==10000 and 1 or fraction
   assert(math.abs(hud.LevelPanel.ProgressBackground.ProgressClip.Size.X.Scale-want)<0.00001,"HUD progress fill");out.checks+=1
   table.insert(out.cases,{level=level,strength=strength,text=hud.Strength.Text,progressText=hud.LevelPanel.ProgressText.Text,fill=hud.LevelPanel.ProgressBackground.ProgressClip.Size.X.Scale})
  end
 end
end)
if changed then P:SetAttribute("Strength",oldStrength);P:SetAttribute("Level",oldLevel) end
out.ok=ok out.error=not ok and tostring(err) or nil
out.restored=not changed or (P:GetAttribute("Strength")==oldStrength and P:GetAttribute("Level")==oldLevel)
local v=Instance.new("StringValue")v.Name="LevelCurveAuditClientResult"v.Value=game:GetService("HttpService"):JSONEncode(out)v.Parent=RS
