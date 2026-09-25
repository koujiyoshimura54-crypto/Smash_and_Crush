local Players=game:GetService("Players")
local Config=require(game.ServerScriptService.Config:WaitForChild("MuscleScaleConfig"))
local bases=setmetatable({}, {__mode="k"})
local appliedStage=setmetatable({}, {__mode="k"})
local PART_NAMES={}
for name in pairs(Config.PART_SCALE_KEYS) do PART_NAMES[#PART_NAMES+1]=name end
local function scalePosition(cf,scale) return CFrame.new(cf.Position*scale)*cf.Rotation end
local function prepare(player,character)
 local humanoid=character:WaitForChild("Humanoid",10)
 if not humanoid then return end
 if humanoid.RigType~=Enum.HumanoidRigType.R15 then warn("MuscleCharacterService skipped non-R15 character for "..player.Name);return end
 local partData={}
 for _,name in ipairs(PART_NAMES) do
  local part=character:WaitForChild(name,10)
  if not part or not part:IsA("BasePart") then warn("MuscleCharacterService missing "..name.." for "..player.Name);return end
  local attachments={}
  for _,child in ipairs(part:GetChildren()) do if child:IsA("Attachment") then attachments[child]=child.Position end end
  partData[name]={Part=part,Size=part.Size,Attachments=attachments}
 end
 local motorData={}
 for _,descendant in ipairs(character:GetDescendants()) do if descendant:IsA("Motor6D") then
  local p0,p1=descendant.Part0,descendant.Part1
  if (p0 and Config.PART_SCALE_KEYS[p0.Name]) or (p1 and Config.PART_SCALE_KEYS[p1.Name]) then motorData[descendant]={C0=descendant.C0,C1=descendant.C1,Part0Name=p0 and p0.Name,Part1Name=p1 and p1.Name} end
 end end
 bases[character]={Humanoid=humanoid,Parts=partData,Motors=motorData,HipHeight=humanoid.HipHeight};appliedStage[character]=nil
end
local function apply(player)
 local character=player.Character;local base=character and bases[character]
 if not base then return end
 local selected=player:GetAttribute("SelectedSizeTier")
 local stage=typeof(selected)=="number" and selected>=1 and selected<=10 and selected or Config.GetMuscleStage(player:GetAttribute("Strength"))
 if appliedStage[character]==stage then return end
 appliedStage[character]=stage
 local scaleHeight=Config.GetHeightScale(stage);base.Humanoid.HipHeight=base.HipHeight*scaleHeight
 for name,data in pairs(base.Parts) do local scale=Config.GetPartScale(name,stage);data.Part.Size=data.Size*scale
  for attachment,position in pairs(data.Attachments) do if attachment.Parent==data.Part then attachment.Position=position*scale end end
 end
 for motor,data in pairs(base.Motors) do if motor.Parent then motor.C0=scalePosition(data.C0,Config.GetPartScale(data.Part0Name,stage));motor.C1=scalePosition(data.C1,Config.GetPartScale(data.Part1Name,stage)) end end
end
local function setup(player)
 local function onCharacter(character) task.spawn(function() prepare(player,character);if player.Character==character then apply(player) end end) end
 player.CharacterAdded:Connect(onCharacter)
 player:GetAttributeChangedSignal("Strength"):Connect(function() apply(player) end)
 player:GetAttributeChangedSignal("SelectedSizeTier"):Connect(function() local character=player.Character;if character then appliedStage[character]=nil end;apply(player) end)
 if player.Character then onCharacter(player.Character) end
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player) local character=player.Character;if character then bases[character]=nil;appliedStage[character]=nil end end)
for _,player in ipairs(Players:GetPlayers()) do setup(player) end
