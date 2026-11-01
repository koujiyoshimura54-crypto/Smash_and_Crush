local player=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local Requirements=require(RS.Config:WaitForChild("LevelRequirements"))
local Presentation=require(RS.Modules:WaitForChild("StrengthHUDPresentation"))
local gui=script.Parent
require(RS.Modules.StrengthRewardUI).Build(gui)
local hud=gui:WaitForChild("StrengthLevelHUD")
local panel=hud:WaitForChild("LevelPanel")
local bar=panel:WaitForChild("StrengthProgressBar")
local levelLabel=bar:WaitForChild("Level")
local amountLabel=bar:WaitForChild("Exp")

levelLabel.AutoLocalize=false
amountLabel.AutoLocalize=false
-- Keep the parent containers and style references used by Auto Tap and item effects.
local totalContainer=hud:WaitForChild("StrengthValueContainer")
local totalLabel=totalContainer:WaitForChild("Strength")
totalContainer.Visible=true
totalLabel.AutoLocalize=false
panel:WaitForChild("Level").Visible=false
panel:WaitForChild("ProgressText").Visible=false
panel:WaitForChild("ProgressBackground").Visible=false
local legacy=gui:FindFirstChild("StrengthLabel")
if legacy then legacy.Visible=false end
local function layout()
 require(RS.Modules:WaitForChild("HUDLayout")).Mount(gui).Refresh()
end
local function update()
 local strength=math.max(0,tonumber(player:GetAttribute("Strength")) or 0)
 totalLabel.Text=Presentation.Number(strength)
 local level=tonumber(player:GetAttribute("Level")) or 1
 local levelProgress=math.max(0,tonumber(player:GetAttribute("LevelProgress")) or 0)
 local required=Requirements.GetRequiredStrength(level)
 local atMax=level>=Requirements.MaxLevel
 local progress=atMax and 1 or (required>0 and math.clamp(levelProgress/required,0,1) or 0)
 levelLabel.Text="Lv."..tostring(level)
 amountLabel.Text=Presentation.Number(levelProgress).." / "..(atMax and "MAX" or Presentation.Number(required))
 Presentation.SetFill(bar,progress)

end
-- Read the related replicated attributes together after the current signal batch.
local updateQueued=false
local function queueUpdate()
 if updateQueued then return end
 updateQueued=true
 task.defer(function()
  updateQueued=false
  if script.Parent then update() end
 end)
end
player:GetAttributeChangedSignal("Strength"):Connect(queueUpdate)
player:GetAttributeChangedSignal("Level"):Connect(queueUpdate)
player:GetAttributeChangedSignal("LevelProgress"):Connect(queueUpdate)
player.CharacterAdded:Connect(queueUpdate)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
update()
