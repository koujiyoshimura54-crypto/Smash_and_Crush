-- Equipped regular-item effects. Values share the gameplay config; no balance table.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remotes = RS:WaitForChild("Remotes")
local master = require(RS.Config:WaitForChild("ItemMaster"))
local effects = require(RS.Config:WaitForChild("ItemMultiplierConfig"))
local elementSetBonus = require(RS.Modules:WaitForChild("ElementSetBonus"))
local gui = player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui")
local hud = gui:WaitForChild("StrengthLevelHUD")
local row = Instance.new("Frame")
row.Name = "ItemEffectHUD"
row.BackgroundTransparency = 1
row.AnchorPoint = Vector2.new(.5, 1)
row.Visible = false
row.Parent = hud
local definitions = {
 {Kind = "Protein", Asset = master.Get("PROTEIN_COMMON_FIRE").Image, Get = effects.GetProteinBonus, Suffix = " STR"},
 {Kind = "Glove", Asset = master.Get("GLOVE_COMMON_FIRE").Image, Get = effects.GetGloveBossDamageBonus, Factor = 100, Suffix = "% DMG"},
 {Kind = "TrainingBelt", Asset = master.Get("TRAININGBELT_COMMON_FIRE").Image, Get = effects.GetBeltTreadmillBonus, Suffix = " Tier"},
}
local entries = {}
for _, definition in ipairs(definitions) do
 local frame = Instance.new("Frame")
 frame.Name = definition.Kind
 frame.BackgroundTransparency = 1
 frame.Visible = false
 frame.Parent = row
 local holder = Instance.new("Frame")
 holder.Name = "IconSlot"
 holder.BackgroundTransparency = 1
 holder.Parent = frame
 local icon = Instance.new("ImageLabel")
 icon.Name = "Icon"
 icon.BackgroundTransparency = 1
 icon.BorderSizePixel = 0
 icon.ImageTransparency = 0
 icon.Image = definition.Asset
 icon.ScaleType = Enum.ScaleType.Fit
 icon.Size = UDim2.fromScale(1, 1)
 icon.Parent = holder
 local label = Instance.new("TextLabel")
 label.Name = "Effect"
 label.BackgroundTransparency = 1
 label.FontFace = hud.LevelPanel.Level.FontFace
 label.TextColor3 = Color3.new(1, 1, 1)
 label.TextStrokeColor3 = Color3.fromRGB(24, 21, 35)
 label.TextStrokeTransparency = .15
 label.TextXAlignment = Enum.TextXAlignment.Left
 label.TextScaled = false
 label.Parent = frame
 entries[definition.Kind] = {Frame = frame, Holder = holder, Icon = icon, Label = label}
end
local setBadge = Instance.new("TextLabel")
setBadge.Name = "ElementSetBonus"
setBadge.BackgroundTransparency = .12
setBadge.BackgroundColor3 = Color3.fromRGB(242,103,114)
setBadge.FontFace = hud.LevelPanel.Level.FontFace
setBadge.TextColor3 = Color3.new(1,1,1)
setBadge.TextStrokeColor3 = Color3.fromRGB(24,21,35)
setBadge.TextStrokeTransparency = .1
setBadge.TextScaled = false
setBadge.AutoLocalize = true
setBadge.Visible = false
setBadge.ZIndex = row.ZIndex + 1
setBadge.Parent = hud
local setCorner = Instance.new("UICorner")
setCorner.CornerRadius = UDim.new(0,8)
setCorner.Parent = setBadge
local setStroke = Instance.new("UIStroke")
setStroke.Color = Color3.fromRGB(43,13,65)
setStroke.Thickness = 2
setStroke.Parent = setBadge
local elementColors = {
 Fire = Color3.fromRGB(242,103,114),
 Ice = Color3.fromRGB(77,190,240),
 Electric = Color3.fromRGB(255,194,62),
}
local elementLabels = {Fire="FIRE SET ×1.5",Ice="ICE SET ×1.5",Electric="ELECTRIC SET ×1.5"}

local gloveTween, gloveReturn, beltTween
local gloveGeneration = 0
local lastAttackId = 0
local alive = false
local function stopGlove()
 gloveGeneration += 1
 if gloveTween then gloveTween:Cancel(); gloveTween = nil end
 if gloveReturn then gloveReturn:Cancel(); gloveReturn = nil end
 entries.Glove.Icon.Position = UDim2.new()
end
local function stopBelt()
 if beltTween then beltTween:Cancel(); beltTween = nil end
 entries.TrainingBelt.Icon.Position = UDim2.new()
end
local function updateTraining()
 local active = alive and entries.TrainingBelt.Frame.Visible
  and player:GetAttribute("IsTraining") == true
  and typeof(player:GetAttribute("TrainingTreadmill")) == "string"
 if active then
  if not beltTween then
   beltTween = TweenService:Create(entries.TrainingBelt.Icon,
    TweenInfo.new(.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Position = UDim2.fromOffset(0, -4)})
   beltTween:Play()
  end
 else
  stopBelt()
 end
end
local function punch()
 if not alive or not entries.Glove.Frame.Visible then return end
 stopGlove()
 local generation = gloveGeneration
 gloveTween = TweenService:Create(entries.Glove.Icon,
  TweenInfo.new(.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
  {Position = UDim2.fromOffset(0, -5)})
 gloveTween.Completed:Once(function(state)
  if generation ~= gloveGeneration or state ~= Enum.PlaybackState.Completed then return end
  gloveTween = nil
  gloveReturn = TweenService:Create(entries.Glove.Icon,
   TweenInfo.new(.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
   {Position = UDim2.new()})
  gloveReturn:Play()
 end)
 gloveTween:Play()
end

local function intersects(a, b)
 return a.X < b.X + b.W and a.X + a.W > b.X
  and a.Y < b.Y + b.H and a.Y + a.H > b.Y
end
local function layout()
 if not row.Visible then return end
 local compact = gui.AbsoluteSize.Y < 500
 local iconSize, textSize, gap = compact and 28 or 32, compact and 18 or 20, compact and 12 or 18
 local height = iconSize + 4
 local width, count = 0, 0
 for _, definition in ipairs(definitions) do
  local entry = entries[definition.Kind]
  if entry.Frame.Visible then
   if entry.MeasuredText ~= entry.Label.Text or entry.MeasuredSize ~= textSize then
    entry.MeasuredText, entry.MeasuredSize = entry.Label.Text, textSize
    entry.TextWidth = math.ceil(TextService:GetTextSize(entry.Label.Text, textSize,
     entry.Label.Font, Vector2.new(1000, height)).X) + 3
   end
   local textWidth = entry.TextWidth
   if count > 0 then width += gap end
   entry.Frame.Position = UDim2.fromOffset(width, 0)
   entry.Frame.Size = UDim2.fromOffset(iconSize + 5 + textWidth, height)
   entry.Holder.Position = UDim2.fromOffset(0, 2)
   entry.Holder.Size = UDim2.fromOffset(iconSize, iconSize)
   entry.Label.Position = UDim2.fromOffset(iconSize + 5, 0)
   entry.Label.Size = UDim2.fromOffset(textWidth, height)
   entry.Label.TextSize = textSize
   width += iconSize + 5 + textWidth
   count += 1
  end
 end
 row.Size = UDim2.fromOffset(width, height)
 -- Keep the row above the gauge and any active potion status occupying that lane.
 local badgeHeight = setBadge.Visible and (compact and 24 or 28) or 0
 local badgeGap = setBadge.Visible and 5 or 0
 local top = hud.AbsolutePosition.Y - height - badgeHeight - badgeGap - 8
 local left = hud.AbsolutePosition.X + (hud.AbsoluteSize.X - width) / 2
 local potion = gui:FindFirstChild("PotionStatus")
 if potion and potion.Visible then
  local p, s = potion.AbsolutePosition, potion.AbsoluteSize
  if intersects({X=left,Y=top-5,W=width,H=height+badgeHeight+badgeGap+5}, {X=p.X,Y=p.Y,W=s.X,H=s.Y}) then
   top = p.Y - height - badgeHeight - badgeGap - 8
  end
 end
 row.Position = UDim2.new(.5, 0, 0, top + badgeHeight + badgeGap + height - hud.AbsolutePosition.Y)
 if setBadge.Visible then
  local textSize = compact and 17 or 19
  local badgeWidth = math.ceil(TextService:GetTextSize(setBadge.Text,textSize,setBadge.Font,Vector2.new(1000,badgeHeight)).X)+20
  setBadge.TextSize = textSize
  setBadge.Size = UDim2.fromOffset(badgeWidth,badgeHeight)
  setBadge.AnchorPoint = Vector2.new(.5,0)
  setBadge.Position = UDim2.new(.5,0,0,top-hud.AbsolutePosition.Y)
 end
end
local revision = 0
local loaded = false
local function applyState(state)
 if typeof(state) ~= "table" or state.Loaded ~= true
  or typeof(state.OwnedItems) ~= "table" or typeof(state.EquippedItems) ~= "table" then return end
 revision += 1
 loaded = true
 local count = 0
 for _, definition in ipairs(definitions) do
  local entry = entries[definition.Kind]
  local id = state.EquippedItems[definition.Kind]
  local item = typeof(id) == "string" and master.Get(id)
  local owned = typeof(id) == "string" and tonumber(state.OwnedItems[id]) or 0
  local equipped = item and item.ItemType == definition.Kind and owned and owned > 0
  if entry.ItemId ~= (equipped and id or nil) then
   if definition.Kind == "Glove" then stopGlove()
   elseif definition.Kind == "TrainingBelt" then stopBelt() end
  end
  entry.ItemId = equipped and id or nil
  entry.Frame.Visible = equipped == true
  if equipped then
   local value = definition.Get(item.Rarity) * (definition.Factor or 1)
   entry.Label.Text = "+" .. string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "") .. definition.Suffix
   count += 1
  end
 end
 local element = elementSetBonus.GetMatchingElement(state.OwnedItems,state.EquippedItems)
 setBadge.Visible = element ~= nil
 if element then
  setBadge.Text = elementLabels[element]
  setBadge.BackgroundColor3 = elementColors[element]
 end
 row.Visible = count > 0
 updateTraining()
 layout()
end
local stateRemote = remotes:WaitForChild("ItemInventoryState")
local refreshing, refreshAgain = false, false
local function refresh()
 if refreshing then refreshAgain = true; return end
 refreshing = true
 repeat
  refreshAgain = false
  local before = revision
  local ok, state = pcall(function() return stateRemote:InvokeServer() end)
  -- An equip reply arriving while this request yields is newer than this snapshot.
  if ok and before == revision then applyState(state) end
 until not refreshAgain
 refreshing = false
end
for _, name in ipairs({"ItemEquipRequest", "ItemPurchaseRequest", "ItemRobuxPurchaseRequest", "ItemMergeRequest"}) do
 remotes:WaitForChild(name).OnClientEvent:Connect(function(result)
  if typeof(result) == "table" then applyState(result.State) end
 end)
end
local gameRemotes = remotes:WaitForChild("GameRemotes")
gameRemotes:WaitForChild("CombatState").OnClientEvent:Connect(function(event)
 if typeof(event) ~= "table" then return end
 if event.Type == "Initialize" then
  lastAttackId = 0
  stopGlove()
 elseif event.Type == "BossGauge" and event.GloveApplied == true
  and typeof(event.AttackId) == "number" and event.AttackId > lastAttackId then
  lastAttackId = event.AttackId
  punch()
 elseif (event.Type == "Fighting" and event.Active == false)
  or event.Type == "BossResult" then
  stopGlove()
 end
end)
player:GetAttributeChangedSignal("IsTraining"):Connect(updateTraining)
player:GetAttributeChangedSignal("TrainingTreadmill"):Connect(updateTraining)
local deathConnection
local function resetCharacter()
 alive = false
 stopGlove()
 stopBelt()
 if deathConnection then deathConnection:Disconnect(); deathConnection = nil end
end
local function characterAdded(character)
 resetCharacter()
 local humanoid = character:WaitForChild("Humanoid", 10)
 if player.Character ~= character or not humanoid then return end
 alive = humanoid.Health > 0
 deathConnection = humanoid.Died:Connect(resetCharacter)
 updateTraining()
 task.spawn(refresh)
end
player.CharacterRemoving:Connect(resetCharacter)
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded, player.Character) end
-- Initial data loading can complete after the first inventory response.
task.spawn(function()
 while not loaded and script.Parent do refresh(); if not loaded then task.wait(1) end end
end)
-- HUDLayout moves the status lane in response to device and potion changes.
local layoutConnection = RunService.RenderStepped:Connect(layout)
script.Destroying:Connect(function()
 resetCharacter()
 layoutConnection:Disconnect()
 setBadge:Destroy()
 row:Destroy()
end)
