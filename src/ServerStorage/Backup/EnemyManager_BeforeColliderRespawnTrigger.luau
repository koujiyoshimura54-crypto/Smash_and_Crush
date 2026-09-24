local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local W=game:GetService("Workspace")
local Stage=require(script.Parent.StageManager)
local Strength=require(script.Parent.StrengthManager)
local Wall=require(script.Parent.Stage1WallManager)
local Boss=require(script.Parent.BossCombatService)
local Trophy=require(script.Parent.TrophyRewardService)
local ItemDrops=require(script.Parent.BossItemDropService)
local watched=setmetatable({}, {__mode="k"})
local lossRespawns=setmetatable({}, {__mode="k"})
local M={} local map,folder,remote,remoteConnection local enemies={} local states=setmetatable({},{__mode="k"}) local sessions=setmetatable({},{__mode="k"}) local token=0
local LOSS_DEATH_DISPLAY_DURATION=0.8
local WALL_TRIGGER_SIZE=Vector3.new(4.5,5.5,4)
local WALL_TRIGGER_FORWARD_OFFSET=3
local WALL_DAMAGE_DELAY=0.18

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
 if not watched[p] then
  watched[p]=true
  p.RespawnLocation=Trophy.GetLobbySpawn()
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
 if typeof(stageNumber)~="number"or stageNumber<1 or stageNumber>5 then return end
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
local function attachStage06Shisa(e)
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
local function createMiniBossCollider(e)
 local root=e:FindFirstChild("HumanoidRootPart")
 if not root then return end
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

local function setMiniBossColliderEnabled(e,enabled)
 local collider=e and e:FindFirstChild("MiniBossCollider")
 if collider then collider.CanCollide=enabled end
end

local function spawnAll()
 folder=W:FindFirstChild("Enemies")or Instance.new("Folder")folder.Name="Enemies"folder.Parent=W
 for _,x in folder:GetChildren()do if x:GetAttribute("ManagedBy")=="EnemyManager"then x:Destroy()end end table.clear(enemies)
 for i=1,10 do local e=SS.EnemyTemplates.DummyEnemy:Clone()e.Name=("Stage%02d_Enemy"):format(i)e:SetAttribute("ManagedBy","EnemyManager")e:SetAttribute("StageNumber",i)e:SetAttribute("MaxGauge",Boss.GetStageConfig(i).MaxHP)e:SetAttribute("RecommendedLevel",Boss.GetStageConfig(i).RecommendedLevel)e:SetAttribute("RequiredStrength",Boss.GetStageConfig(i).RequiredStrength) local cfg=Wall.Config[i] if cfg then e:SetAttribute("BossMaxHP",cfg.BossMaxHP) end
  for _,d in e:GetDescendants()do if d:IsA("BasePart")then d.CanCollide=false end end
  local root=e.HumanoidRootPart local prompt=root:FindFirstChild("FightPrompt")if prompt then prompt:Destroy()end
  local z=Instance.new("Part")z.Name="CombatZone"z.Size=Vector3.new(10,14,16)z.Transparency=1 z.CanCollide=false z.CanTouch=true z.CanQuery=false z.Anchored=true z.CFrame=root.CFrame*CFrame.new(0,0,-5)z.Parent=e
  e.Parent=folder local spawnPart=map.BattleCorridor[("Stage%02d"):format(i)]:FindFirstChild("EnemySpawn",true)
  assert(spawnPart and spawnPart:IsA("BasePart"),"EnemySpawn missing for Stage "..i)
  e:PivotTo(spawnPart.CFrame*CFrame.new(0,3.5,0))attachShisaVisual(e)attachStage06Shisa(e)attachStage07BossVisual(e)createMiniBossCollider(e) task.delay(.5,function()if e.Parent then refreshMiniBossCollider(e) for _,d in e:GetDescendants()do if d:IsA("BasePart")then d.CanCollide=false end end end end)e.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None enemies[i]=e
 end
end
local function inside(root,z)local p=z.CFrame:PointToObjectSpace(root.Position)local h=z.Size/2 return math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z end
local function defeat(p,n)
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
    local st=Stage.GetState(p)
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
 -- Only the configured .5 Boss victory enters the drop service.
 if Wall.Config[n] and Wall.IsBossUnlockedForStage(p,n) then
  ItemDrops.OnBossDefeated(p,n,5,ps)
 end
end
local function monitor()
 token+=1 local t=token task.spawn(function() while t==token do
  local now=W:GetServerTimeNow()
  for _,p in Players:GetPlayers() do
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
   local enemyHit=bossUnlocked and e and hum and hum.Health>0 and root and inside(root,e.CombatZone)
   local target=wallHit and wall or (enemyHit and e)
   if target then
    local s=sessions[p]
    local targetKey=wallHit and ("Wall"..n.."."..Wall.GetCurrentIndexForStage(p,n)) or ("Enemy"..n)
    local startedWall=false
    local initialWallPower
    if not s or s.Target~=targetKey then
     if wallHit then
      startedWall=true
      initialWallPower=Strength.GetStrength(p)
      if initialWallPower>0 then
       local ps=state(p);ps.AttackSequence=(ps.AttackSequence or 0)+1
       send(p,{Type="CombatAttack",Id=ps.AttackSequence,Stage=n,Duration=Boss.AttackDuration})
      end
     end
     sessions[p]={Stage=n,Target=targetKey,LastTick=now}
     p:SetAttribute("IsFighting",true)
     send(p,{Type="Fighting",Active=true})
     if enemyHit and not wallHit and Wall.Config[n] then
      local maxHP=e:GetAttribute("BossMaxHP") or 100
      local bs=Boss.Begin(p,e,n,maxHP)
      state(p).Gauges[n]=bs.HP
      send(p,{Type="BossInitialize",Stage=n,Current=bs.HP,Max=bs.MaxHP,RecommendedLevel=bs.RecommendedLevel})
     end
    end
    s=sessions[p]
    if startedWall or now-s.LastTick>=Boss.AttackInterval then
     s.LastTick=now
     local power=initialWallPower or Strength.GetStrength(p)
     if enemyHit and not wallHit and Wall.Config[n] then
      local status,bs=Boss.Attack(p)
      if bs and status~="Inactive" and status~="Complete" then
       local ps=state(p)
       ps.AttackSequence=(ps.AttackSequence or 0)+1
       send(p,{Type="CombatAttack",Id=ps.AttackSequence,Stage=n,Attack=bs.Attacks,Duration=Boss.AttackDuration})
       -- Apply visible HP/death after the server-authorized punch, not on zone entry.
       local hpAfter,attack=bs.HP,bs.Attacks
       task.delay(Boss.AttackDuration,function()
        if p.Parent~=Players or state(p)~=ps or p.Character~=ch or not hum or hum.Health<=0 then return end
        ps.Gauges[n]=hpAfter
        send(p,{Type="BossGauge",Stage=n,Current=hpAfter,Max=bs.MaxHP,Attack=attack})
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
       end)
      end
     elseif wallHit and power>0 then
      if not startedWall then
       local ps=state(p);ps.AttackSequence=(ps.AttackSequence or 0)+1
       send(p,{Type="CombatAttack",Id=ps.AttackSequence,Stage=n,Duration=Boss.AttackDuration})
      end
      local attackPlayer,attackStage,attackPower=p,n,power
      local attackTargetKey,attackEnemy=targetKey,e
      task.delay(WALL_DAMAGE_DELAY,function()
       if attackPlayer.Parent~=Players then return end
       local cleared,nextIndex,remaining=Wall.ApplyDamageForStage(attackPlayer,attackStage,attackPower)
       for _,index in ipairs(cleared) do
        send(attackPlayer,{Type="WallGauge",MajorStage=attackStage,Index=index,Current=0,Max=Wall.Config[attackStage].Walls[index]})
        send(attackPlayer,{Type="WallCleared",MajorStage=attackStage,Index=index,Next=nextIndex,NextMax=(nextIndex<=4 and Wall.Config[attackStage].Walls[nextIndex] or nil)})
       end
       if nextIndex<=4 then
        send(attackPlayer,{Type="WallGauge",MajorStage=attackStage,Index=nextIndex,Current=Wall.GetGaugeForStage(attackPlayer,attackStage,nextIndex),Max=Wall.Config[attackStage].Walls[nextIndex]})
       elseif Wall.IsBossUnlockedForStage(attackPlayer,attackStage) then
        setMiniBossColliderEnabled(enemies[attackStage],true)
        send(attackPlayer,{Type="Stage1BossUnlocked",MajorStage=attackStage})
        local bossMax=(enemies[attackStage] and enemies[attackStage]:GetAttribute("BossMaxHP")) or 100
        send(attackPlayer,{Type="BossRecommendation",Stage=attackStage,Max=bossMax,RecommendedLevel=Boss.GetStageConfig(attackStage).RecommendedLevel})
        if remaining>0 then
         local boss=attackEnemy
         local carryBossMax=(boss and boss:GetAttribute("BossMaxHP")) or 100
         Boss.QueueDamage(attackPlayer,boss,attackStage,carryBossMax,remaining)
        end
       end
       if #cleared>0 then
        local active=sessions[attackPlayer]
        if not active or active.Target==attackTargetKey then
         sessions[attackPlayer]=nil
         attackPlayer:SetAttribute("IsFighting",false)
         send(attackPlayer,{Type="Fighting",Active=false})
        end
       end
      end)
     elseif enemyHit then
      local ps=state(p)
      if power>0 then ps.Gauges[n]=math.max(0,ps.Gauges[n]-power) end
      send(p,{Type="Gauge",Stage=n,Current=ps.Gauges[n],Max=n*10})
      if ps.Gauges[n]<=0 then defeat(p,n) end
     end
    end
   elseif sessions[p] then
    Boss.Cancel(p)
    sessions[p]=nil
    p:SetAttribute("IsFighting",false)
    send(p,{Type="Fighting",Active=false})
   end
  end
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