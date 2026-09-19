local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local W=game:GetService("Workspace")
local Stage=require(game.ServerScriptService.World.StageManager)
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local Wall=require(game.ServerScriptService.World.Stage1WallManager)
local Boss=require(game.ServerScriptService.World.BossCombatService)
local Trophy=require(game.ServerScriptService.Services.TrophyRewardService)
local ItemDrops=require(game.ServerScriptService.Services.EnemyDropGachaService)
local PlayerData=require(game.ServerScriptService.Services.PlayerDataService)
local Badges=require(game.ServerScriptService.Services.BadgeAwardService)
local watched=setmetatable({}, {__mode="k"})
local lossRespawns=setmetatable({}, {__mode="k"})
local M={} local map,folder,remote,remoteConnection local enemies={} local states=setmetatable({},{__mode="k"}) local sessions=setmetatable({},{__mode="k"}) local token=0
local AutoTapConfig=require(RS.Config:WaitForChild("AutoTapConfig"))
local lastManualAttack=setmetatable({}, {__mode="k"})
local LOSS_DEATH_DISPLAY_DURATION=0.8
local WALL_TRIGGER_SIZE=Vector3.new(4.5,5.5,4)
local WALL_TRIGGER_FORWARD_OFFSET=3
local WALL_DAMAGE_DELAY=0.18
local MINIBOSS_DAMAGE_DELAY=0.50

local function ensureWallCombatTrigger(character)
 local root=character:WaitForChild("HumanoidRootPart",10)
 if not root or character:FindFirstChild("WallCombatTrigger") then return end
 local trigger=Instance.new("Part")
 trigger.Name="WallCombatTrigger"
 trigger.Size=WALL_TRIGGER_SIZE
 trigger.CFrame=root.CFrame*CFrame.new(0,0,-WALL_TRIGGER_FORWARD_OFFSET)
 trigger.Transparency=1
 trigger.Anchored=false
 trigger.CanCollide=false
 trigger.CanTouch=false
 trigger.CanQuery=false
 trigger.Massless=true
 trigger.Parent=character
 local weld=Instance.new("WeldConstraint")
 weld.Name="WallCombatTriggerWeld"
 weld.Part0=root
 weld.Part1=trigger
 weld.Parent=trigger
end

local function boxesOverlap(a,b)
 local relative=b.CFrame:ToObjectSpace(a.CFrame)
 local half=a.Size/2
 local right,up,look=relative.RightVector,relative.UpVector,relative.LookVector
 local projected=Vector3.new(
  math.abs(right.X)*half.X+math.abs(up.X)*half.Y+math.abs(look.X)*half.Z,
  math.abs(right.Y)*half.X+math.abs(up.Y)*half.Y+math.abs(look.Y)*half.Z,
  math.abs(right.Z)*half.X+math.abs(up.Z)*half.Y+math.abs(look.Z)*half.Z
 )
 local targetHalf=b.Size/2
 local p=relative.Position
 return math.abs(p.X)<=targetHalf.X+projected.X
  and math.abs(p.Y)<=targetHalf.Y+projected.Y
  and math.abs(p.Z)<=targetHalf.Z+projected.Z
end
local function state(p)local s=states[p]if not s then s={Gauges={},Defeated={}}for i=1,10 do s.Gauges[i]=Boss.GetStageConfig(i).MaxHP end states[p]=s end return s end
local function send(p,d)remote:FireClient(p,d)end
function M.SendState(p)local st=Stage.GetState(p)local ps=state(p)local g={}for i=1,10 do g[i]=ps.Gauges[i]end send(p,{Type="Initialize",CurrentStage=st.CurrentStage,Cleared=ps.Defeated,Skipped=ps.Skipped,WorldComplete=st.WorldComplete,Gauges=g}) for major in pairs(Wall.Config) do send(p,{Type="WallInitialize",State=Wall.GetSnapshotForStage(p,major)}) end end
function M.InitializePlayer(p,targetStage)
 targetStage=targetStage or 1
 Trophy.Clear(p)
 Trophy.InitializePlayer(p)
 Boss.Reset(p)
 sessions[p]=nil
 Stage.InitializePlayer(p,targetStage)
 Wall.InitializePlayer(p,targetStage)
 states[p]=nil
 local ps=state(p)
 ps.Skipped={}
 for major=1,targetStage-1 do ps.Skipped[major]=true end
 p:SetAttribute("IsFighting",false)
 send(p,{Type="Fighting",Active=false})
 M.SendState(p)
 p.RespawnLocation=Trophy.GetLobbySpawn()
 if not watched[p] then
  watched[p]=true
  local function characterAdded(character,reset)
   if lossRespawns[p] then
    -- Keep the planned-loss guard through the old character reset. It is
    -- cleared only by the CharacterAdded raised by our explicit LoadCharacter.
    if reset~=false then lossRespawns[p]=nil end
   elseif reset~=false then
    M.InitializePlayer(p)
   end
   task.spawn(function()
    ensureWallCombatTrigger(character)
    local hum=character:WaitForChild("Humanoid",10)
    if hum and p.Character==character then
     hum.Died:Once(function()
     if p.Character==character and not lossRespawns[p] then M.InitializePlayer(p) end
    end)
    end
   end)
  end
  p.CharacterAdded:Connect(characterAdded)
  if p.Character then characterAdded(p.Character,false) end
 end
end
local function returnToLobbyAfterLoss(p)
 if lossRespawns[p] then return end
 lossRespawns[p]=true
 local character=p.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if humanoid and humanoid.Health>0 then humanoid.Health=0 end
 task.delay(LOSS_DEATH_DISPLAY_DURATION,function()
  if p.Parent~=Players then lossRespawns[p]=nil return end
  -- Reset once, immediately before the explicit direct respawn.
  M.InitializePlayer(p)
  local ok,err=pcall(function() p:LoadCharacter() end)
  if not ok then
   lossRespawns[p]=nil
   warn("Direct loss respawn failed for "..p.Name..": "..tostring(err))
   local current=p.Character
   local currentHumanoid=current and current:FindFirstChildOfClass("Humanoid")
   if currentHumanoid and currentHumanoid.Health>0 then currentHumanoid.Health=0 end
  end
 end)
end
local shisaAppearances={
 [2]={Color=Color3.fromRGB(190,45,35),Material=Enum.Material.SmoothPlastic},
 [3]={Color=Color3.fromRGB(45,105,210),Material=Enum.Material.SmoothPlastic},
 [4]={Color=Color3.fromRGB(125,125,125),Material=Enum.Material.Slate},
 [5]={Color=Color3.fromRGB(212,168,45),Material=Enum.Material.Metal},
}
local shisaScaleMultipliers={[1]=0.60,[2]=0.80,[3]=1.00,[4]=1.25,[5]=1.50}
local function attachShisaVisual(e)
 local stageNumber=e:GetAttribute("StageNumber")
 if typeof(stageNumber)~="number"or stageNumber<1 or stageNumber>5 or stageNumber==1 or stageNumber==2 or stageNumber==3 or stageNumber==4 or stageNumber==5 then return end
 local source=SS.EnemyTemplates:FindFirstChild("Shisa_Simple2")
 if not source then warn("Shisa_Simple2 visual template is missing")return end
 local visual=source:Clone()visual.Name="Shisa_Simple2"visual.Parent=e
 local appearance=shisaAppearances[stageNumber]
 if appearance then
  for _,d in visual:GetDescendants()do
   if d:IsA("BasePart")then d.Color=appearance.Color d.Material=appearance.Material
   elseif d:IsA("SurfaceAppearance")then d.Color=appearance.Color end
  end
 end
 visual:ScaleTo(source:GetScale()*shisaScaleMultipliers[stageNumber])
 local root=e.HumanoidRootPart
 local stage=map.BattleCorridor[("Stage%02d"):format(stageNumber)]
 local floor=stage.Floor
 local playerSide=root.Position+Vector3.new(0,0,-1)
 visual:PivotTo(CFrame.lookAt(root.Position,playerSide)*CFrame.Angles(math.rad(90),0,0))
 local box,size=visual:GetBoundingBox()
 local floorTop=floor.Position.Y+floor.Size.Y/2
 local bottom=box.Position.Y-size.Y/2
 visual:PivotTo(visual:GetPivot()+Vector3.new(0,floorTop-bottom,0))
 for _,d in visual:GetDescendants()do
  if d:IsA("BasePart")then
   d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
   local weld=Instance.new("WeldConstraint")weld.Name="EnemyVisualWeld"weld.Part0=root weld.Part1=d weld.Parent=d
  end
 end
 local controller=visual:FindFirstChildOfClass("AnimationController")or Instance.new("AnimationController")
 controller.Parent=visual
 local animator=controller:FindFirstChildOfClass("Animator")or Instance.new("Animator")
 animator.Parent=controller
 local animation=Instance.new("Animation")
 animation.Name="Shisa_Walk"
 animation.AnimationId="rbxassetid://97913994042609"
 animation.Parent=visual
 local track=animator:LoadAnimation(animation)
 track.Looped=true
 track:Play(0,1,1)
for _,name in ipairs({"HumanoidRootPart","Torso","Head"})do
  local part=e:FindFirstChild(name)if part and part:IsA("BasePart")then part.Transparency=1 end
 end
end
local function attachEarlyStageVisual(e)
 local stageNumber=e:GetAttribute("StageNumber")
 if stageNumber~=1 and stageNumber~=2 then return end
 local templateFolder=SS.EnemyTemplates[("Stage%02dBoss"):format(stageNumber)]
 local visual=templateFolder[stageNumber==1 and "BallerinaCappuccinaRig" or "TralaleroTralalaRig"]:Clone()
 visual.Parent=e
 local root=e.HumanoidRootPart
 local floor=map.BattleCorridor[("Stage%02d"):format(stageNumber)].Floor
 visual:PivotTo(CFrame.lookAt(root.Position,root.Position+Vector3.new(0,0,-1)))
 -- Invisible helper roots extend below the visible mesh bounds.
 local bottom=math.huge
 for _,part in visual:GetDescendants()do
  if part:IsA("BasePart")and part.Transparency<1 then
   for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
    local corner=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
    bottom=math.min(bottom,corner.Y)
   end end end
  end
 end
 -- This skinned mesh's static bounds do not include its deformed feet.
 -- Keep the visible floor fit from sinking below the two foot anchors.
 if stageNumber==1 then
  for _,name in {"Leg.L.003","Leg.R.003"}do
   local foot=visual.FakeRootPart:FindFirstChild(name)
   if foot and foot:IsA("Bone")then bottom=math.min(bottom,foot.WorldPosition.Y)end
  end
 end
 local floorTop=floor.Position.Y+floor.Size.Y/2
 visual:PivotTo(visual:GetPivot()+Vector3.new(0,floorTop-bottom,0))
 local weld=Instance.new("Weld")
 weld.Name=("Stage%02dVisualRootWeld"):format(stageNumber)
 weld.Part0=root
 weld.Part1=visual.RootPart
 weld.C0=root.CFrame:ToObjectSpace(visual.RootPart.CFrame)
 weld.Parent=visual.RootPart
 for _,d in visual:GetDescendants()do
  if d:IsA("BasePart")then
   d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
  end
 end
 for _,name in ipairs({"HumanoidRootPart","Torso","Head"})do
  local part=e:FindFirstChild(name)
  if part and part:IsA("BasePart")then part.Transparency=1 end
 end
end

local function attachStage03TungTungSahur(e)
 if e:GetAttribute("StageNumber")~=3 then return end
 local template=SS.EnemyTemplates:FindFirstChild("Stage03Boss")
 local source=template and template:FindFirstChild("TungTungSahurRig")
 if not source then warn("Stage03 TungTungSahur visual template is missing")return end
 local visual=source:Clone()
 visual.Parent=e
 -- Cosmetic R15 rig only; EnemyManager retains the encounter root and HP.
 for _,d in visual:GetDescendants()do
  if d:IsA("LuaSourceContainer")then d:Destroy()end
 end
 local root=e.HumanoidRootPart
 local visualRoot=visual.HumanoidRootPart
 local floor=map.BattleCorridor.Stage03.Floor
 visual:PivotTo(CFrame.lookAt(root.Position,root.Position+Vector3.new(0,0,-1)))
 local box,size=visual:GetBoundingBox()
 local floorTop=floor.Position.Y+floor.Size.Y/2
 visual:PivotTo(visual:GetPivot()+Vector3.new(0,floorTop-(box.Position.Y-size.Y/2),0))
 -- Weld only the visual root so the original Motor6Ds remain usable.
 local weld=Instance.new("WeldConstraint")
 weld.Name="Stage03VisualRootWeld"
 weld.Part0=root
 weld.Part1=visualRoot
 weld.Parent=visualRoot
 for _,d in visual:GetDescendants()do
  if d:IsA("BasePart")then
   d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
  end
 end
 for _,name in ipairs({"HumanoidRootPart","Torso","Head"})do
  local part=e:FindFirstChild(name)
  if part and part:IsA("BasePart")then part.Transparency=1 end
 end
end

local function attachStage05Visual(e)
 if e:GetAttribute("StageNumber")~=5 then return end
 local visual=SS.EnemyTemplates.Stage05Boss["67Rig"]:Clone()
 visual.Parent=e
 local root=e.HumanoidRootPart
 local floor=map.BattleCorridor.Stage05.Floor
 visual:PivotTo(CFrame.lookAt(root.Position,root.Position+Vector3.new(0,0,-1)))
 -- Transparent FakeRootPart extends below the feet; fit visible mesh bounds.
 local bottom=math.huge
 for _,part in visual:GetDescendants()do
  if part:IsA("BasePart")and part.Transparency<1 then
   for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
    local corner=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
    bottom=math.min(bottom,corner.Y)
   end end end
  end
 end
 local floorTop=floor.Position.Y+floor.Size.Y/2
 visual:PivotTo(visual:GetPivot()+Vector3.new(0,floorTop-bottom,0))
 local weld=Instance.new("WeldConstraint")
 weld.Name="Stage05VisualRootWeld"
 weld.Part0=root
 weld.Part1=visual.RootPart
 weld.Parent=visual.RootPart
 for _,d in visual:GetDescendants()do
  if d:IsA("BasePart")then
   d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
  end
 end
 for _,name in ipairs({"HumanoidRootPart","Torso","Head"})do
  local part=e:FindFirstChild(name)
  if part and part:IsA("BasePart")then part.Transparency=1 end
 end
end


-- Static late-stage cosmetics. Combat roots/zones and collision references stay separate.
local staticVisualNames={
 [6]="Pipi_Kiwi",[7]="Trippi Troppi",[8]="Chimpanzini Bananini",[9]="Trippa Troppa Tralala Lirilì Rilà TungTung Sahur Boneca TungTung Tralalelo TrippiTroppa Crocodina",[10]="Dragon Cannelloni",
}
local function staticBounds(visual)
 local low=Vector3.new(math.huge,math.huge,math.huge)
 local high=Vector3.new(-math.huge,-math.huge,-math.huge)
 local function include(p) low=low:Min(p);high=high:Max(p) end
 for _,part in visual:GetDescendants() do
  if part:IsA("BasePart") and part.Transparency<1 then
   for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
    include(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))
   end end end
  elseif part:IsA("Bone") then
   include(part.WorldPosition)
  elseif part:IsA("BasePart") and part.Name=="floorfx" then
   include(part.Position)
  end
 end
 return low,high
end
local function attachStaticStageVisual(e)
 local n=e:GetAttribute("StageNumber")
 local name=staticVisualNames[n]
 if not name then return end
 local template=SS.EnemyTemplates:FindFirstChild(("Stage%02dBoss"):format(n))
 local source=template and template:FindFirstChild(name)
 if not source then return end -- Leave the existing appearance intact if its replacement is unavailable.
 local visual=source:Clone()
 local root=e.HumanoidRootPart
 local floor=map.BattleCorridor[("Stage%02d"):format(n)].Floor
 local particles={}
 for _,d in visual:GetDescendants() do
  if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Highlight") then
   d:SetAttribute("StaticVFXEnabled",d.Enabled)
  end
  if d:IsA("ParticleEmitter") then
   particles[d]={Size=d.Size,Speed=d.Speed,Acceleration=d.Acceleration,Drag=d.Drag,ZOffset=d.ZOffset}
  end
 end
 local low,high=staticBounds(visual)
 local size=high-low
 local desiredHeight=source:GetAttribute("DisplayHeight") or size.Y
 local floorHalf=floor.Size/2
 -- Size remains based on the authored boss-area floor center.
 -- EnemySpawn may move inside that area without shrinking the existing appearance.
 local bossArea=map.BattleCorridor[("Stage%02d"):format(n)]:FindFirstChild(("Stage%d.5"):format(n))
 local sizeAnchor=bossArea and bossArea:FindFirstChild("Floor")
 local relative=floor.CFrame:PointToObjectSpace(sizeAnchor and sizeAnchor.Position or root.Position)
 local depth=math.max(1,2*(floorHalf.Z-math.abs(relative.Z))-2)
 local factor=math.min(desiredHeight/math.max(size.Y,.01),(floor.Size.X-4)/math.max(size.X,.01),depth/math.max(size.Z,.01))
 visual:ScaleTo(source:GetScale()*factor)
 -- Model scaling must not change authored particle sizes, speeds or emission settings.
 for emitter,values in pairs(particles) do for property,value in pairs(values) do emitter[property]=value end end
 visual:PivotTo(CFrame.lookAt(root.Position,root.Position+Vector3.new(0,0,-1)))
 low,high=staticBounds(visual)
 local center=(low+high)/2
 local floorTop=floor.Position.Y+floor.Size.Y/2
 visual:PivotTo(visual:GetPivot()+Vector3.new(root.Position.X-center.X,floorTop-low.Y,root.Position.Z-center.Z))
 for _,part in visual:GetDescendants() do
  if part:IsA("BasePart") then
   part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
   local weld=Instance.new("WeldConstraint")
   weld.Name="StaticVisualWeld";weld.Part0=root;weld.Part1=part;weld.Parent=part
  end
 end
 visual.Parent=e
 e:SetAttribute("StaticAppearance",true)
 for _,name in {"HumanoidRootPart","Torso","Head"} do
  local part=e:FindFirstChild(name)
  if part and part:IsA("BasePart") then part.Transparency=1 end
 end
end

local function attachStage06Shisa(e)
 if e:GetAttribute("StaticAppearance") then return end
	if e:GetAttribute("StageNumber") ~= 6 then
		return
	end

	local source = SS.EnemyTemplates:FindFirstChild("Shisa_Stand")
	if not source then
		warn("Shisa_Stand visual template is missing")
		return
	end

	local visual = source:Clone()
	visual.Name = "Shisa_Stand"
	visual.Parent = e

	visual:ScaleTo(3)

	local root = e.HumanoidRootPart
	local visualRoot = visual:FindFirstChild("HumanoidRootPart")

	if not visualRoot then
		visual:Destroy()
		warn("Shisa_Stand HumanoidRootPart is missing")
		return
	end

	local stage = map.BattleCorridor.Stage06
	local floor = stage.Floor

	local playerSide = root.Position + Vector3.new(0, 0, -1)
	visual:PivotTo(CFrame.lookAt(root.Position, playerSide))

	local box, size = visual:GetBoundingBox()
	local floorTop = floor.Position.Y + floor.Size.Y / 2
	local bottom = box.Position.Y - size.Y / 2

	visual:PivotTo(
		visual:GetPivot() + Vector3.new(0, floorTop - bottom + 4, 0)
	)

	for _, d in visual:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end

	visualRoot.Anchored = true

	for _, name in ipairs({"HumanoidRootPart", "Torso", "Head"}) do
		local part = e:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end
local function attachStage07BossVisual(e)
 if e:GetAttribute("StaticAppearance") then return end
 if e:GetAttribute("StageNumber") ~= 7 then return end
 local source=SS.EnemyTemplates:FindFirstChild("Stage10_Boss_Roblox15K_autosetup")
 if not source or not source:IsA("Model") then warn("Stage10 Boss visual source is missing") return end
 local visual=source:Clone()
 visual.Name="Stage07_Boss_Visual"
 visual.Parent=e
 local a=visual:FindFirstChild("AnimateScript")
 if a then a:Destroy() end
 local root=e:FindFirstChild("HumanoidRootPart")
 local visualRoot=visual:FindFirstChild("HumanoidRootPart",true)
 local stage=map.BattleCorridor.Stage07
 local floor=stage.Floor
 if not root or not visualRoot or not floor then visual:Destroy() return end
 visual.PrimaryPart=visualRoot
 visual:ScaleTo(source:GetScale())
 local playerSide=root.Position+Vector3.new(0,0,-1)
 visual:PivotTo(CFrame.lookAt(root.Position,playerSide))
 local box,size=visual:GetBoundingBox()
 local floorTop=floor.Position.Y+floor.Size.Y/2
 local bottom=box.Position.Y-size.Y/2
 visual:PivotTo(visual:GetPivot()+Vector3.new(0,floorTop-bottom,0))

	local rootWeld = Instance.new("WeldConstraint")
	rootWeld.Name = "Stage07RootWeld"
	rootWeld.Part0 = root
	rootWeld.Part1 = visualRoot
	rootWeld.Parent = visualRoot local tailVisual=visual:FindFirstChild("Stage10_Boss_Tail",true)
 for _,d in ipairs(visual:GetDescendants()) do
  if d:IsA("BasePart") then
   d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
   -- Do not weld Boss body parts to the root: Avatar Setup AnimationConstraints
   -- must be free to apply the registered KeyframeSequence pose.
   -- The Tail's own Stage10TailWeld remains intact.
  end
 end
 local humanoid=visual:FindFirstChildOfClass("Humanoid")
 if humanoid then
  humanoid.AutoRotate=false
  local animator=humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
  animator.Parent=humanoid
  local function loadPublicAnimation(assetId,name,looped)
  local anim=Instance.new("Animation")
  anim.Name=name.."Animation"
  anim.AnimationId=assetId
  anim.Parent=visual
  local okLoad,track=pcall(function() return animator:LoadAnimation(anim) end)
  if not okLoad or not track then warn("Stage07 Boss animation load failed: "..name) return nil end
  track.Name=name.."Track"
  track.Priority=Enum.AnimationPriority.Action
  track.Looped=looped
  track:AdjustSpeed(1.0)
  return track
 end
 local equipTrack=loadPublicAnimation("rbxassetid://82074310685853","Stage07_FistEquip",false)
 local idleTrack

  local function playIdle()
   if idleTrack then idleTrack:Stop(0) end
   idleTrack=loadPublicAnimation("rbxassetid://89933395312088","Stage07_FistIdle",true)
   if idleTrack then idleTrack.Looped=true idleTrack:Play(0.1,1,1.0) idleTrack:AdjustSpeed(1.0) end
  end
  if equipTrack then
   equipTrack.Looped=false
   equipTrack:Play(0.1,1,1.0) equipTrack:AdjustSpeed(1.0)
   equipTrack.Stopped:Connect(playIdle)
  else
   playIdle()
  end
  visual:SetAttribute("FistEquipAnimation","R15 Criminality Fist Equip")
  visual:SetAttribute("FistIdleAnimation","R15 Criminality Fist Idle")
  visual:SetAttribute("FistEquipLooped",false)
  visual:SetAttribute("FistIdleLooped",true)
  visual:SetAttribute("AnimationSpeed",1.0)
 end
 for _,name in ipairs({"HumanoidRootPart","Torso","Head"}) do
  local part=e:FindFirstChild(name)
  if part and part:IsA("BasePart") then part.Transparency=1 end
 end
end
local function attachStage04Visual(e)
 if e:GetAttribute("StageNumber")~=4 then return end
 local visual=SS.EnemyTemplates.Stage04Boss.BombardiroCrocodiloRig:Clone()
 visual.Parent=e
 local root=e.HumanoidRootPart
 local floor=map.BattleCorridor.Stage04.Floor
 visual:PivotTo(CFrame.lookAt(root.Position,root.Position+Vector3.new(0,0,-1)))
 local bottom=math.huge
 for _,part in visual:GetDescendants()do
  if part:IsA("BasePart")and part.Transparency<1 then
   for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
    local corner=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
    bottom=math.min(bottom,corner.Y)
   end end end
  end
 end
 visual:PivotTo(visual:GetPivot()+Vector3.new(0,floor.Position.Y+floor.Size.Y/2-bottom+7,0))
 local weld=Instance.new("WeldConstraint")
 weld.Name="Stage04VisualRootWeld"weld.Part0=root weld.Part1=visual.RootPart weld.Parent=visual.RootPart
 for _,d in visual:GetDescendants()do
  if d:IsA("BasePart")then d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true end
 end
 for _,name in {"HumanoidRootPart","Torso","Head"}do
  local p=e:FindFirstChild(name)if p and p:IsA("BasePart")then p.Transparency=1 end
 end
end

local function createMiniBossCollider(e)
 local root=e:FindFirstChild("HumanoidRootPart")
 if not root then return end
 if e:GetAttribute("StaticAppearance") then
 local reference=SS.EnemyTemplates[("Stage%02dBoss"):format(e:GetAttribute("StageNumber"))].CollisionReference
 local collider=reference:Clone()
  collider.Name="MiniBossCollider";collider.CFrame=root.CFrame*reference.CFrame
  collider.CanCollide=false;collider.CanTouch=false;collider.CanQuery=false
  collider.Parent=e
  local weld=Instance.new("WeldConstraint")
  weld.Name="MiniBossColliderWeld";weld.Part0=root;weld.Part1=collider;weld.Parent=collider
  return
 end
 local box,size
 local visualModel
 for _,child in ipairs(e:GetChildren()) do
  if child:IsA("Model") then visualModel=child break end
 end
 if visualModel then
  box,size=visualModel:GetBoundingBox()
 else
  local torso=e:FindFirstChild("Torso")
  box=torso and torso.CFrame or (root.CFrame*CFrame.new(0,3.5,0))
  size=Vector3.new(4,7,3)
 end
 local collider=Instance.new("Part")
 collider.Name="MiniBossCollider"
 local padding=(e:GetAttribute("StageNumber")==6) and Vector3.new(4,4,4) or Vector3.new(1,0.5,1) collider.Size=size+padding
 collider.CFrame=box
 collider.Transparency=1
 collider.Anchored=false
 collider.CanCollide=false
 collider.CanTouch=false
 collider.CanQuery=false
 collider.Massless=true
 collider.Parent=e
 local weld=Instance.new("WeldConstraint")
 weld.Name="MiniBossColliderWeld"
 weld.Part0=root
 weld.Part1=collider
 weld.Parent=collider
end

local function refreshMiniBossCollider(e)
 if e and e:GetAttribute("StaticAppearance") then return end
 local collider=e and e:FindFirstChild("MiniBossCollider")
 if not collider then return end
 local visualModel
 for _,child in ipairs(e:GetChildren()) do
  if child:IsA("Model") then visualModel=child break end
 end
 if visualModel then
  local _,size=visualModel:GetBoundingBox()
  local padding=(e:GetAttribute("StageNumber")==6) and Vector3.new(4,4,4) or Vector3.new(1,0.5,1) collider.Size=size+padding
 end
end

local enemyGeneration={}
local function spawnEnemy(i)
 local previous=enemies[i]
 if previous and previous.Parent then previous:Destroy() end
 local e=SS.EnemyTemplates.DummyEnemy:Clone()
 e.Name=("Stage%02d_Enemy"):format(i)
 e:SetAttribute("ManagedBy","EnemyManager")
 e:SetAttribute("StageNumber",i)
 enemyGeneration[i]=(enemyGeneration[i] or 0)+1
 e:SetAttribute("SpawnGeneration",enemyGeneration[i])
 e:SetAttribute("MaxGauge",Boss.GetStageConfig(i).MaxHP)
 e:SetAttribute("RecommendedLevel",Boss.GetStageConfig(i).RecommendedLevel)
 e:SetAttribute("RequiredStrength",Boss.GetStageConfig(i).RequiredStrength)
 e:SetAttribute("BossMaxHP",Boss.GetStageConfig(i).MaxHP)
 for _,d in e:GetDescendants() do if d:IsA("BasePart") then d.CanCollide=false end end
 local root=e.HumanoidRootPart
 local prompt=root:FindFirstChild("FightPrompt")
 if prompt then prompt:Destroy() end
 local z=Instance.new("Part")
 z.Name="CombatZone" z.Size=Vector3.new(10,14,16) z.Transparency=1
 z.CanCollide=false z.CanTouch=true z.CanQuery=false z.Anchored=true
 z.CFrame=root.CFrame*CFrame.new(0,0,-5) z.Parent=e
 e.Parent=folder
 local spawnPart=map.BattleCorridor[("Stage%02d"):format(i)]:FindFirstChild("EnemySpawn",true)
 assert(spawnPart and spawnPart:IsA("BasePart"),"EnemySpawn missing for Stage "..i)
 e:PivotTo(spawnPart.CFrame*CFrame.new(0,3.5,0))
 attachShisaVisual(e)
 attachEarlyStageVisual(e)
 attachStage03TungTungSahur(e)
 attachStage04Visual(e)
 attachStage05Visual(e)
 attachStaticStageVisual(e)
 attachStage06Shisa(e)
 attachStage07BossVisual(e)
 -- Snapshot visual bounds once after scaling/floor placement, before combat animation.
 -- Recomputed on every spawn; never use the outer encounter Collider/CombatZone.
 local displayVisual=e:FindFirstChildOfClass("Model")
 if displayVisual then
  local low,high=staticBounds(displayVisual)
  if high.Y>low.Y then
   e:SetAttribute("BossDisplayHeight",high.Y-low.Y)
   e:SetAttribute("BossDisplayBaseY",low.Y)
  end
 end
 createMiniBossCollider(e)
 -- Large late-World1 bosses need a reachable combat trigger on every side.
 -- Preserve Stage1-5 zones. This zone has no physical collision.
 if i>=6 and i<=10 then
  local collider=e:FindFirstChild("MiniBossCollider")
  if collider then
   z.Size=Vector3.new(collider.Size.X+4,14,collider.Size.Z+4)
   local floorTop=collider.Position.Y-collider.Size.Y/2
   z.CFrame=CFrame.new(collider.Position.X,floorTop+z.Size.Y/2,collider.Position.Z)*collider.CFrame.Rotation
  end
 end
 if i==1 then
  local v=e:FindFirstChild("BallerinaCappuccinaRig")
  local head=v and v.FakeRootPart.Torso:FindFirstChild("Head")
  if head then e:SetAttribute("Stage01GaugeTopY",math.max(e.Head.Position.Y,head.WorldPosition.Y+v["Cube.001"].Size.Y/2))end
 end
 if i==2 then
  local cf,size=e:GetBoundingBox()
  e:SetAttribute("Stage02GaugeTopY",cf.Position.Y+size.Y/2)
 end
 task.delay(.5,function()
  if e.Parent and enemies[i]==e then
   refreshMiniBossCollider(e)
   for _,d in e:GetDescendants() do if d:IsA("BasePart") then d.CanCollide=false end end
  end
 end)
 e.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 enemies[i]=e
 return e
end
local function spawnAll()
 folder=W:FindFirstChild("Enemies") or Instance.new("Folder")
 folder.Name="Enemies" folder.Parent=W
 for _,x in folder:GetChildren() do if x:GetAttribute("ManagedBy")=="EnemyManager" then x:Destroy() end end
 table.clear(enemies)
 table.clear(enemyGeneration)
 for i=1,10 do spawnEnemy(i) end
end
local function inside(root,z)local p=z.CFrame:PointToObjectSpace(root.Position)local h=z.Size/2 return math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z end
local function defeat(p,n)
 local defeatedEnemy=enemies[n]
 local ps=state(p)
 if ps.Defeated[n] then return end
 ps.Gauges[n]=0
 ps.Defeated[n]=true
 sessions[p]=nil
 Boss.End(p) -- Discard carry at the boundary; keep this run\'s encounter decisions.
 p:SetAttribute("IsFighting",false)
 send(p,{Type="Fighting",Active=false})
 send(p,{Type="Gauge",Stage=n,Current=0,Max=Boss.GetStageConfig(n).MaxHP})
 send(p,{Type="EnemyDefeated",Stage=n})
 -- Boss defeat advances the Major Stage; Trophy remains claimable until pickup.
 task.delay(0.05,function()
  if p.Parent==Players and state(p)==ps and ps.Defeated[n] then
   local cleared=Stage.ClearStage(p,n)
   if cleared then
    Badges.Award(p,"FirstSmash")
    local st=Stage.GetState(p)
    if st.WorldComplete then Badges.Award(p,"World1Complete") end
    send(p,{Type="StageCleared",Stage=n,CurrentStage=st.CurrentStage,WorldComplete=st.WorldComplete})
   end
  end
 end)
 -- The ordered client event starts the existing Defeat Sound before the visual.
 local character=p.Character
 task.delay(.3,function()
  if p.Parent==Players and p.Character==character and state(p)==ps and ps.Defeated[n] then
   local hum=character and character:FindFirstChildOfClass("Humanoid")
   if hum and hum.Health>0 then Trophy.Spawn(p,n) end
  end
 end)
 -- One server-owned reward per confirmed enemy defeat.
 ItemDrops.OnEnemyDefeated(p,n,ps)
 -- Every replacement uses the same full spawn path, including a fresh collider.
 task.delay(.6,function()
  if map and defeatedEnemy and enemies[n]==defeatedEnemy then spawnEnemy(n) end
 end)
end
local function updateCombat(p,manualRequest)
 local now=W:GetServerTimeNow()
 local auto=PlayerData.IsAutoTapEnabled(p)
 if manualRequest and auto then return false,"AutoEnabled" end
   local n=Stage.GetCurrentStageNumber(p)
   local st=Stage.GetState(p)
   local ch=p.Character
   local hum=ch and ch:FindFirstChildOfClass("Humanoid")
   local root=ch and ch:FindFirstChild("HumanoidRootPart")
   local majorWall=Wall.Config[n] and n
   local wall=majorWall and Wall.GetCurrentWallForStage(p,majorWall)
   local wallPart=wall and wall:FindFirstChild("Wall")
   local wallTrigger=ch and ch:FindFirstChild("WallCombatTrigger")
   local wallHit=wallPart and wallTrigger and hum and hum.Health>0 and boxesOverlap(wallTrigger,wallPart)
   local e=not st.WorldComplete and not state(p).Defeated[n] and enemies[n]
   local bossUnlocked=(not Wall.Config[n]) or Wall.IsBossUnlockedForStage(p,n)
   local enemyTrigger=ch and ch:FindFirstChild("WallCombatTrigger")
   local enemyHit=bossUnlocked and e and hum and hum.Health>0 and enemyTrigger
    and e:FindFirstChild("CombatZone") and boxesOverlap(enemyTrigger,e.CombatZone)
   -- The existing session owns the combat type until contact and pending hits end.
   local active=sessions[p]
   if active and (active.Stage~=n or active.Character~=ch or not hum or hum.Health<=0 or st.WorldComplete) then
    Boss.Cancel(p)
    sessions[p]=nil
    p:SetAttribute("IsFighting",false)
    send(p,{Type="Fighting",Active=false})
    active=nil
   end
   if active then
    if active.CombatType=="Wall" then
     enemyHit=false
     wallHit=wallHit and active.Instance==wall
    else
     wallHit=false
     enemyHit=enemyHit and active.Instance==e
    end
   end
   local target=wallHit and wall or (enemyHit and e)
   if target then
    local s=sessions[p]
    local targetKey=wallHit and ("Wall"..n.."."..Wall.GetCurrentIndexForStage(p,n)) or ("Enemy"..n)
    local startedWall=false
    local startedEnemy=false
    local initialWallPower
    if not s then
     if wallHit then
      startedWall=true
      initialWallPower=Strength.GetStrength(p)
      if auto and initialWallPower>0 then
       local ps=state(p);ps.AttackSequence=(ps.AttackSequence or 0)+1
       send(p,{Type="CombatAttack",Id=ps.AttackSequence,Stage=n,Duration=Boss.AttackDuration})
      end
     end
     sessions[p]={Stage=n,Target=targetKey,LastTick=now,CombatType=wallHit and "Wall" or "MiniBoss",Instance=target,Character=ch,Pending=0}
     p:SetAttribute("IsFighting",true)
     send(p,{Type="Fighting",Active=true,CombatType=sessions[p].CombatType,Stage=n,WallIndex=wallHit and Wall.GetCurrentIndexForStage(p,n) or nil})
     if enemyHit and not wallHit and Wall.Config[n] then
      startedEnemy=true
      local maxHP=Boss.GetStageConfig(n).MaxHP
      local bs=Boss.Begin(p,e,n,maxHP)
      state(p).Gauges[n]=bs.HP
      send(p,{Type="BossInitialize",Stage=n,Current=bs.HP,Max=bs.MaxHP,RecommendedLevel=bs.RecommendedLevel})
     end
    end
    s=sessions[p]
    if manualRequest then
     if now-(lastManualAttack[p] or -math.huge)<AutoTapConfig.ManualAttackCooldown or s.Pending>0 then return false,"Cooldown" end
     lastManualAttack[p]=now
    end
    if manualRequest or (auto and (startedWall or startedEnemy or now-s.LastTick>=Boss.AttackInterval)) then
     s.LastTick=now
     local power=initialWallPower or Strength.GetStrength(p)
     if enemyHit and not wallHit and Wall.Config[n] then
      local bs=Boss.Get(p)
      if bs and not bs.Completed then
       local ps=state(p)
       ps.AttackSequence=(ps.AttackSequence or 0)+1
       -- Auto retains its existing hit delay; manual applies the accepted hit immediately.
       local attackId=ps.AttackSequence
       if n==2 and p:GetAttribute("TutorialCompleted")==false then
        PlayerData.CompleteTutorial(p)
       end
       send(p,{Type="CombatAttack",Id=attackId,Stage=n,Attack=bs.Attacks+1,Duration=Boss.AttackDuration,HitDelay=manualRequest and 0 or MINIBOSS_DAMAGE_DELAY,Manual=manualRequest==true,AnimationSpeed=manualRequest and AutoTapConfig.ManualAttackAnimationSpeed or nil})
       s.Pending+=1
       local function applyBossHit()
        s.Pending-=1
        if p.Parent~=Players or sessions[p]~=s or Stage.GetCurrentStageNumber(p)~=n or state(p)~=ps or p.Character~=ch or not hum or hum.Health<=0 then return end
        if s.CombatType~="MiniBoss" or s.Instance~=e or enemies[n]~=e or not e.Parent or ps.Defeated[n] or Boss.Get(p)~=bs or bs.Completed then return end
        local hpBefore=bs.HP
        local status,hitState=Boss.Attack(p)
        if hitState~=bs or status=="Inactive" or status=="Complete" then return end
        ps.Gauges[n]=bs.HP
        -- Presentation evidence from the accepted hit; damage math remains in Boss.Attack.
        send(p,{Type="BossGauge",Stage=n,Current=bs.HP,Max=bs.MaxHP,Attack=bs.Attacks,
         AttackId=attackId,GloveApplied=bs.Route~="LOTTERY_WIN" and bs.GloveBonus>0 and bs.HP<hpBefore})
        if status=="Win" then
         send(p,{Type="BossResult",Result="WIN"})
         defeat(p,n)
        elseif status=="Lose" then
         send(p,{Type="BossResult",Result="LOSE"})
         Boss.End(p)
         sessions[p]=nil
         p:SetAttribute("IsFighting",false)
         send(p,{Type="Fighting",Active=false})
         returnToLobbyAfterLoss(p)
        end
       end
       if manualRequest then applyBossHit() else task.delay(MINIBOSS_DAMAGE_DELAY,applyBossHit) end
      end
     elseif s.CombatType=="Wall" and power>0 then
      if manualRequest or not startedWall then
       local ps=state(p);ps.AttackSequence=(ps.AttackSequence or 0)+1
       send(p,{Type="CombatAttack",Id=ps.AttackSequence,Stage=n,Duration=Boss.AttackDuration,Manual=manualRequest==true,AnimationSpeed=manualRequest and AutoTapConfig.ManualAttackAnimationSpeed or nil})
      end
      local attackPlayer,attackStage,attackPower=p,n,power
      local attackTargetKey,attackEnemy=targetKey,e
      s.Pending+=1
      local function applyWallHit()
       s.Pending-=1
       if attackPlayer.Parent~=Players or sessions[attackPlayer]~=s or Stage.GetCurrentStageNumber(attackPlayer)~=attackStage or attackPlayer.Character~=ch or not hum or hum.Health<=0 then return end
       local cleared,nextIndex,remaining=Wall.ApplyDamageForStage(attackPlayer,attackStage,attackPower)
       for _,index in ipairs(cleared) do
        send(attackPlayer,{Type="WallGauge",MajorStage=attackStage,Index=index,Current=0,Max=Wall.GetStageConfig(attackStage).Walls[index]})
        send(attackPlayer,{Type="WallCleared",MajorStage=attackStage,Index=index,Next=nextIndex,State=Wall.GetSnapshotForStage(attackPlayer,attackStage),NextMax=(nextIndex<=4 and Wall.GetStageConfig(attackStage).Walls[nextIndex] or nil)})
       end
       if nextIndex<=4 then
        send(attackPlayer,{Type="WallGauge",MajorStage=attackStage,Index=nextIndex,Current=Wall.GetGaugeForStage(attackPlayer,attackStage,nextIndex),Max=Wall.GetStageConfig(attackStage).Walls[nextIndex]})
       elseif Wall.IsBossUnlockedForStage(attackPlayer,attackStage) then
        send(attackPlayer,{Type="Stage1BossUnlocked",MajorStage=attackStage})
        local bossMax=Boss.GetStageConfig(attackStage).MaxHP
        send(attackPlayer,{Type="BossRecommendation",Stage=attackStage,Current=state(attackPlayer).Gauges[attackStage],Max=bossMax,RecommendedLevel=Boss.GetStageConfig(attackStage).RecommendedLevel})
        if remaining>0 then
         local boss=attackEnemy
         local carryBossMax=Boss.GetStageConfig(attackStage).MaxHP
         Boss.QueueDamage(attackPlayer,boss,attackStage,carryBossMax,remaining)
        end
       end
       if #cleared>0 then
        local active=sessions[attackPlayer]
        if active==s then
         sessions[attackPlayer]=nil
         attackPlayer:SetAttribute("IsFighting",false)
         send(attackPlayer,{Type="Fighting",Active=false})
        end
       end
      end
      if manualRequest then applyWallHit() else task.delay(WALL_DAMAGE_DELAY,applyWallHit) end
     end
    end
   elseif sessions[p] and sessions[p].Pending==0 then
    Boss.Cancel(p)
    sessions[p]=nil
    p:SetAttribute("IsFighting",false)
    send(p,{Type="Fighting",Active=false})
   end
 return target~=nil,target and "Combat" or "NoCombat"
end
-- Same contact, damage, carry, result and progression path as automatic attacks.
function M.TryManualAttack(p)
 if not M.IsReady() then return false,"NotReady" end
 return updateCombat(p,true)
end
local function monitor()
 token+=1 local t=token task.spawn(function() while t==token do
  for _,p in Players:GetPlayers() do updateCombat(p,false) end
  task.wait(.1)
 end end)
end
function M.Initialize(newMap)map=newMap or W:FindFirstChild("GeneratedMap")assert(map)local rf=RS.Remotes:FindFirstChild("GameRemotes")or Instance.new("Folder")rf.Name="GameRemotes"rf.Parent=RS.Remotes remote=rf:FindFirstChild("CombatState")or Instance.new("RemoteEvent")remote.Name="CombatState"remote.Parent=rf
 remote.OnServerEvent:Connect(function(p,d) if typeof(d)=="table" and d.Type=="RequestState" then M.SendState(p) Trophy.SendState(p) end end)
 Trophy.Initialize(map,remote,function(p) M.InitializePlayer(p) end,function(p,n)
 return state(p).Defeated[n]==true
end)
 Stage.Initialize(map)spawnAll()for _,p in Players:GetPlayers()do M.InitializePlayer(p)end monitor()return enemies end
function M.IsReady()return map~=nil and remote~=nil and enemies[10]~=nil end
function M.StartRun(p,targetStage)
 assert(M.IsReady(),"Combat is not initialized")
 M.InitializePlayer(p,targetStage)
end
function M.GetEnemy(n)return enemies[n]end
function M.GetGauge(p,n)return state(p).Gauges[n]end
function M.GetPlayerState(p)return state(p)end
function M.ResetPlayer(p)M.InitializePlayer(p)end
Players.PlayerRemoving:Connect(function(p)states[p]=nil sessions[p]=nil end)
return M
