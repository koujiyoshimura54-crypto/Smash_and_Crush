-- Read-only native Client UI evidence; use alongside inspected screenshots.
local p=game.Players.LocalPlayer
local gui=p.PlayerGui.StrengthGui
local function visible(v)
 local n=v
 while n and n~=game do
  if n:IsA("GuiObject")and not n.Visible then return false end
  if n:IsA("LayerCollector")and not n.Enabled then return false end
  n=n.Parent
 end
 return true
end
local function row(v)
 local a,b=v.AbsolutePosition,v.AbsoluteSize
 local r={Path=v:GetFullName(),Visible=visible(v),X=a.X,Y=a.Y,W=b.X,H=b.Y}
 if v:IsA("TextLabel")or v:IsA("TextButton")then
  r.Text=v.Text;r.TextWidth=v.TextBounds.X;r.TextHeight=v.TextBounds.Y
 end
 if v:IsA("GuiButton")then r.Active=v.Active end
 return r
end
local rows={}
for _,name in {"StrengthLevelHUD","RebirthPanel","LeftMenu","HUD"}do
 local folder=gui:FindFirstChild(name)
 if folder then for _,v in folder:GetDescendants()do
  if v:IsA("TextLabel")or v:IsA("TextButton")or v:IsA("ImageButton")then table.insert(rows,row(v))end
 end end
end
local recommended=workspace.GeneratedMap.BattleCorridor.Stage02["Stage2.5"].Floor:FindFirstChild("BossRecommendedLevel")
local worldTexts={}
if recommended then for _,v in recommended:GetDescendants()do if v:IsA("TextLabel")then table.insert(worldTexts,{Path=v:GetFullName(),Text=v.Text})end end end
local enemies=workspace:FindFirstChild("Enemies")
local owner=enemies and enemies:FindFirstChild("Owner_"..p.UserId)
local boss=owner and owner:FindFirstChild("Stage02_Enemy")
if boss then for _,v in boss:GetDescendants()do if v:IsA("TextLabel")then
 table.insert(worldTexts,{Path=v:GetFullName(),Text=v.Text,Visible=visible(v)})
end end end
local viewport=workspace.CurrentCamera.ViewportSize
local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
return {Viewport={viewport.X,viewport.Y},Orientation=tostring(p.PlayerGui.CurrentScreenOrientation),
 StarterOrientation=tostring(game.StarterGui.ScreenOrientation),TouchEnabled=game.UserInputService.TouchEnabled,
 State={LV=p:GetAttribute("Level"),Progress=p:GetAttribute("LevelProgress"),Curve=p:GetAttribute("LevelCurveVersion"),Strength=p:GetAttribute("Strength"),Rebirth=p:GetAttribute("RebirthCount"),Auto=p:GetAttribute("AutoTapEnabled"),Health=h and h.Health},
 ScreenGui={IgnoreGuiInset=gui.IgnoreGuiInset,ScreenInsets=tostring(gui.ScreenInsets),ClipToDeviceSafeArea=gui.ClipToDeviceSafeArea},
 Controls=rows,WorldTexts=worldTexts}
