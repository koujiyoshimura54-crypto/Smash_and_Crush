-- Phase 7.2.4: server-replicated, Training Lobby-only dual dumbbells.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Service = require(game.ServerScriptService.Services:WaitForChild("DumbbellService"))
local AreaService = require(game.ServerScriptService.Services:WaitForChild("TrainingLobbyAreaService"))
local template = ServerStorage.Templates:WaitForChild("DumbbellDisplayTemplate")

local DISPLAY_NAMES = {
 Right = "TrainingDumbbellRight",
 Left = "TrainingDumbbellLeft",
}
local HAND_OFFSETS = {
 Right = CFrame.new(0, -0.15, 0),
 Left = CFrame.new(0, -0.15, 0),
}
local currentState = setmetatable({}, {__mode = "k"})
local elapsed = 0

local function removeVisuals(character)
 for _, name in pairs(DISPLAY_NAMES) do
  local display = character:FindFirstChild(name)
  if display then display:Destroy() end
 end
end

local function prototypeScale(character)
 if not RunService:IsStudio() or game.PlaceId~=126576845524886 then return nil end
 local folder=ServerStorage:FindFirstChild("BodyPrototype_20261114")
 if not folder or folder:GetAttribute("Enabled")~=true or not character:GetAttribute("BodyComparisonActive") then return nil end
 return character:GetAttribute("BodyPrototypeDumbbellScale")
end

local function attachDumbbell(character, side, hand, itemId)
 local display = template:Clone()
 display.Name = DISPLAY_NAMES[side]
 display:SetAttribute("ItemId", itemId)
 local bar = display.PrimaryPart or display:FindFirstChild("Bar")
 if not bar or not bar:IsA("BasePart") then
  display:Destroy()
  warn("DumbbellDisplayTemplate has no usable Bar")
  return false
 end
 display.PrimaryPart = bar
 for _, descendant in ipairs(display:GetDescendants()) do
  if descendant:IsA("BasePart") then
   descendant.Anchored = false
   descendant.CanCollide = false
   descendant.CanTouch = false
   descendant.Massless = true
  end
 end
 local scale=prototypeScale(character)
 local offset=HAND_OFFSETS[side]
 if typeof(scale)=="number" then
  display:ScaleTo(scale)
  offset=CFrame.new(0,-hand.Size.Y*0.12,0)
 end
 display:PivotTo(hand.CFrame * offset)
 display.Parent = character
 local weld = Instance.new("WeldConstraint")
 weld.Name = side .. "HandWeld"
 weld.Part0 = hand
 weld.Part1 = bar
 weld.Parent = bar
 return true
end

local function refreshPlayer(player, force)
 local character = player.Character
 if not character then
  currentState[player] = nil
  player:SetAttribute("InTrainingLobby", false)
  return
 end
 local inLobby = AreaService.IsInTrainingLobby(player)
 player:SetAttribute("InTrainingLobby", inLobby)
 local itemId = inLobby and Service.GetEquippedDumbbell(player) or nil
 local key = itemId or ""
 local scale=prototypeScale(character)
 if scale then key=key..":"..tostring(scale) end
 if RunService:IsStudio() and game.PlaceId==126576845524886 and character:GetAttribute("BodyPrototypeManaged") then
  key=key..":"..tostring(character:GetAttribute("BodyComparisonRevision"))
 end
 if not force and currentState[player] == key then return end

 removeVisuals(character)
 currentState[player] = nil
 if not itemId then
  currentState[player] = ""
  return
 end

 local rightHand = character:FindFirstChild("RightHand")
 local leftHand = character:FindFirstChild("LeftHand")
 if not rightHand or not leftHand then return end

 local rightOk = attachDumbbell(character, "Right", rightHand, itemId)
 local leftOk = attachDumbbell(character, "Left", leftHand, itemId)
 if not rightOk or not leftOk then
  removeVisuals(character)
  return
 end
 currentState[player] = key
end

local function setupPlayer(player)
 player:SetAttribute("InTrainingLobby", false)
 player.CharacterAdded:Connect(function()
  currentState[player] = nil
  task.defer(refreshPlayer, player, true)
 end)
 player:GetAttributeChangedSignal("EquippedDumbbell"):Connect(function()
  task.defer(refreshPlayer, player, true)
 end)
 if player.Character then task.defer(refreshPlayer, player, true) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerRemoving:Connect(function(player) currentState[player] = nil end)

RunService.Heartbeat:Connect(function(dt)
 elapsed += dt
 if elapsed < 0.2 then return end
 elapsed %= 0.2
 for _, player in ipairs(Players:GetPlayers()) do
  refreshPlayer(player, false)
 end
end)
