local player=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local Requirements=require(RS.Config:WaitForChild("LevelRequirements"))
local Format=require(RS.Modules:WaitForChild("NumberFormat"))
local gui=script.Parent
local hud=gui:WaitForChild("StrengthLevelHUD")
local panel=hud.LevelPanel
local clip=panel.ProgressBackground.ProgressClip
local fill=clip.Fill
local old=gui:FindFirstChild("StrengthLabel")
if old then old.Visible=false end
local progress=0
local function layout()
 require(RS.Modules.HUDLayout).Mount(gui).Refresh()
end
local function update()
 local strength=math.max(0,tonumber(player:GetAttribute("Strength")) or 0)
 local level=tonumber(player:GetAttribute("Level")) or Requirements.CalculateLevel(strength)
 local start=Requirements.GetRequiredStrength(level)
 local nextValue=Requirements.GetRequiredStrength(level+1)
 progress=nextValue>start and math.clamp((strength-start)/(nextValue-start),0,1) or 0
 hud.Strength.Text=Format.Format(strength).." Strength"
 panel.Level.Text="Lv."..tostring(level)
 panel.ProgressText.Text=Format.Format(strength).." / "..Format.Format(nextValue)
 clip.Size=UDim2.fromScale(progress,1)
 clip.Visible=progress>0
 layout()
end
player:GetAttributeChangedSignal("Strength"):Connect(update)
player:GetAttributeChangedSignal("Level"):Connect(update)
player.CharacterAdded:Connect(update)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
update()

