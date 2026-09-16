-- Server presentation only; ownership and equipment remain in AuraService.
local RS=game:GetService("ReplicatedStorage")
local Aura=require(game.ServerScriptService.Services:WaitForChild("AuraService"))
local Config=require(RS.Config:WaitForChild("AuraConfig"))
local M={}
local bindings={}
local EFFECT_NAME="EquippedAuraVisual"
local function removeVisual(character)
 local folder=character and character:FindFirstChild("AuraEffects")
 if folder then
  for _,child in ipairs(folder:GetChildren()) do
   if child.Name==EFFECT_NAME or child.Name=="PinkAura" then child:Destroy() end
  end
 end
end
function M.Sync(player)
 local character=player.Character
 if not character then return end
 local aura=Config.Get(Aura.GetEquippedAura(player))
 local templateName=aura and aura.VisualTemplate
 local library=RS:FindFirstChild("AuraVisualTemplates")
 local template=typeof(templateName)=="string" and library and library:FindFirstChild(templateName)
 local templateRoot=template and template:IsA("Model") and template:FindFirstChild("Root")
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 if not templateName or (humanoid and humanoid.Health<=0) then removeVisual(character);return end
 if not templateRoot or not templateRoot:IsA("BasePart") then
  removeVisual(character)
  warn("Aura visual template missing or invalid: "..tostring(templateName))
  return
 end
 local attachTo=template:GetAttribute("AttachTo") or "UpperTorso"
 local target=character:FindFirstChild(attachTo) or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
 if not target or not target:IsA("BasePart") then removeVisual(character);return end
 local folder=character:FindFirstChild("AuraEffects")
 local existing=folder and folder:FindFirstChild(EFFECT_NAME)
 local existingRoot=existing and existing:FindFirstChild("Root")
 local existingWeld=existingRoot and existingRoot:FindFirstChild("AuraMount")
 if existing and existing:GetAttribute("VisualTemplate")==templateName and existingWeld
  and existingWeld:IsA("WeldConstraint") and existingWeld.Part0==target and existingWeld.Part1==existingRoot then return end
 removeVisual(character)
 if not folder then folder=Instance.new("Folder");folder.Name="AuraEffects";folder.Parent=character end
 -- The Studio-authored Instances are the visual source of truth. Do not scale emitter properties.
 local effect=template:Clone()
 effect.Name=EFFECT_NAME;effect:SetAttribute("VisualTemplate",templateName)
 local root=effect.Root
 local origin=root.CFrame
 local parts={}
 for _,child in ipairs(effect:GetDescendants()) do
  if child:IsA("BasePart") then table.insert(parts,child) end
 end
 for _,part in ipairs(parts) do
  part.CFrame=target.CFrame*origin:ToObjectSpace(part.CFrame)
  part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
  part.Massless=true
  local weld=Instance.new("WeldConstraint")
  weld.Name="AuraMount";weld.Part0=target;weld.Part1=part;weld.Parent=part
 end
 for _,child in ipairs(effect:GetDescendants()) do
  if child:IsA("Highlight") then child.Adornee=character end
 end
 effect.Parent=folder
end
function M.Unbind(player)
 local binding=bindings[player]
 if not binding then return end
 for _,c in ipairs(binding.player) do c:Disconnect() end
 for _,c in ipairs(binding.character) do c:Disconnect() end
 removeVisual(player.Character)
 bindings[player]=nil
end
function M.Bind(player)
 if bindings[player] then M.Sync(player);return end
 local b={player={},character={}}
 bindings[player]=b
 local function characterAdded(character)
  for _,c in ipairs(b.character) do c:Disconnect() end
  table.clear(b.character)
  local function watchHumanoid(h)
   if h:IsA("Humanoid") then
    table.insert(b.character,h.Died:Connect(function() removeVisual(character) end))
   end
  end
  table.insert(b.character,character.ChildAdded:Connect(function(child)
   watchHumanoid(child)
   if child:IsA("BasePart") or child:IsA("Humanoid") then M.Sync(player) end
  end))
  table.insert(b.character,character.ChildRemoved:Connect(function(child)
   if child:IsA("BasePart") then M.Sync(player) end
  end))
  local h=character:FindFirstChildOfClass("Humanoid")
  if h then watchHumanoid(h) end
  M.Sync(player)
 end
 table.insert(b.player,player:GetAttributeChangedSignal("EquippedAura"):Connect(function() M.Sync(player) end))
 table.insert(b.player,player.CharacterAdded:Connect(characterAdded))
 table.insert(b.player,player.CharacterRemoving:Connect(function(character)
  removeVisual(character)
  for _,c in ipairs(b.character) do c:Disconnect() end
  table.clear(b.character)
 end))
 if player.Character then characterAdded(player.Character) end
end
return M
