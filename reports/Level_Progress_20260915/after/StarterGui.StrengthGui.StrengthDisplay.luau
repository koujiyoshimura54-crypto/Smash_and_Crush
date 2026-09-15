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
 local level=tonumber(player:GetAttribute("Level")) or 1
 local levelProgress=math.max(0,tonumber(player:GetAttribute("LevelProgress")) or 0)
 local required=Requirements.GetRequiredStrength(level)
 progress=level>=Requirements.MaxLevel and 1 or (required>0 and math.clamp(levelProgress/required,0,1) or 0)
 hud.Strength.Text=Format.Format(strength).." Strength"
 panel.Level.Text="Lv."..tostring(level)
 panel.ProgressText.Text=Format.Format(levelProgress).." / "..Format.Format(required)
 clip.Size=UDim2.fromScale(progress,1)
 clip.Visible=progress>0
 layout()
end
player:GetAttributeChangedSignal("Strength"):Connect(update)
player:GetAttributeChangedSignal("Level"):Connect(update)
player:GetAttributeChangedSignal("LevelProgress"):Connect(update)
player.CharacterAdded:Connect(update)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
update()

