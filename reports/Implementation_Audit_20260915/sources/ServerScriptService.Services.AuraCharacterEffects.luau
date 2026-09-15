-- Server presentation only; ownership and equipment remain in AuraService.
local Aura=require(game.ServerScriptService.Services:WaitForChild("AuraService"))
local M={}
local bindings={}
local function removePink(character)
 local folder=character and character:FindFirstChild("AuraEffects")
 if folder then
  for _,child in ipairs(folder:GetChildren()) do
   if child.Name=="PinkAura" then child:Destroy() end
  end
 end
end
function M.Sync(player)
 local character=player.Character
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart")
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 if Aura.GetEquippedAura(player)~="Pink" or not root or not root:IsA("BasePart") or (humanoid and humanoid.Health<=0) then
  removePink(character)
  return
 end
 local folder=character:FindFirstChild("AuraEffects")
 if folder then
  local existing=folder:FindFirstChild("PinkAura")
  local weld=existing and existing:FindFirstChild("RootWeld")
  if existing and weld and weld:IsA("WeldConstraint") and weld.Part0==root and weld.Part1==existing then return end
  removePink(character)
 end
 local pack=workspace:FindFirstChild("vfx pack")
 local library=pack and pack:FindFirstChild("VFX")
 local template=library and library:FindFirstChild("PinkAura2")
 if not template or not template:IsA("BasePart") then
  warn("Pink Aura template missing: Workspace.vfx pack.VFX.PinkAura2")
  return
 end
 if not folder then folder=Instance.new("Folder");folder.Name="AuraEffects";folder.Parent=character end
 -- Preserve the whole Part, its Box Volume, and all Core settings except the display Size scale.
 local effect=template:Clone()
 local core=effect:FindFirstChild("Core")
 if core and core:IsA("ParticleEmitter") then
  local points={}
  for _,point in ipairs(core.Size.Keypoints) do
   points[#points+1]=NumberSequenceKeypoint.new(point.Time,point.Value*0.67,point.Envelope*0.67)
  end
  core.Size=NumberSequence.new(points)
 end
 effect.Name="PinkAura"
 effect.Anchored=false
 effect.CanCollide=false
 effect.CanTouch=false
 effect.CanQuery=false
 effect.Massless=true
 effect.Transparency=1
 effect.CFrame=root.CFrame
 local weld=Instance.new("WeldConstraint")
 weld.Name="RootWeld";weld.Part0=root;weld.Part1=effect;weld.Parent=effect
 effect.Parent=folder
end
function M.Unbind(player)
 local binding=bindings[player]
 if not binding then return end
 for _,c in ipairs(binding.player) do c:Disconnect() end
 for _,c in ipairs(binding.character) do c:Disconnect() end
 removePink(player.Character)
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
    table.insert(b.character,h.Died:Connect(function() removePink(character) end))
   end
  end
  table.insert(b.character,character.ChildAdded:Connect(function(child)
   watchHumanoid(child)
   if child.Name=="HumanoidRootPart" or child:IsA("Humanoid") then M.Sync(player) end
  end))
  table.insert(b.character,character.ChildRemoved:Connect(function(child)
   if child.Name=="HumanoidRootPart" then M.Sync(player) end
  end))
  local h=character:FindFirstChildOfClass("Humanoid")
  if h then watchHumanoid(h) end
  M.Sync(player)
 end
 table.insert(b.player,player:GetAttributeChangedSignal("EquippedAura"):Connect(function() M.Sync(player) end))
 table.insert(b.player,player.CharacterAdded:Connect(characterAdded))
 table.insert(b.player,player.CharacterRemoving:Connect(function(character)
  removePink(character)
  for _,c in ipairs(b.character) do c:Disconnect() end
  table.clear(b.character)
 end))
 if player.Character then characterAdded(player.Character) end
end
return M

