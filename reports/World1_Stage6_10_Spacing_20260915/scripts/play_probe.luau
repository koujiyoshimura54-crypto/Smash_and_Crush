if not game:GetService("RunService"):IsStudio() then return end
local H=game:GetService("HttpService")
local D=require(game.ServerScriptService.Services.PlayerDataService)
local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local B=require(game.ServerScriptService.World.BossCombatService)
local p=game.Players:GetPlayers()[1]
local function clone(t)if typeof(t)~="table" then return t end local o={}for k,v in t do o[k]=clone(v) end return o end
local function waitFor(f,t)local deadline=os.clock()+t repeat if f() then return true end task.wait(.05) until os.clock()>deadline return false end
assert(waitFor(function()p=p or game.Players:GetPlayers()[1] return p and p.Character and D.IsLoaded(p) and E.IsReady()end,25),"Player unavailable")
local session=D.Get(p)
assert(waitFor(function()return not session.Saving end,20),"Save busy")
local original={Data=clone(session.Data),Attributes=p:GetAttributes(),Dirty=session.Dirty,Pivot=p.Character:GetPivot(),Speed=p.Character.Humanoid.WalkSpeed}
session.Saving=true
local state=Instance.new("Folder")state.Name="SpacingPlayTest" state.Parent=workspace
local cmd=Instance.new("StringValue")cmd.Name="Command"cmd.Parent=state
local result=Instance.new("StringValue")result.Name="Result"result.Parent=state
local function place(n)
 E.StartRun(p,n)
 p:SetAttribute("Strength",B.GetStageConfig(n).RequiredStrength)
 p:SetAttribute("Level",B.GetStageConfig(n).RecommendedLevel)
 session.Data.EquippedItems.Glove=""
 local ws=W.GetStageState(p,n)
 for i=1,3 do ws.Gauges[i]=0 ws.Cleared[i]=true end
 ws.Current=4 p:SetAttribute(("Stage%dSubStage"):format(n),4)
 E.SendState(p)
 local wall=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(n)][("Stage%d.4"):format(n)].Wall
 local root=p.Character.HumanoidRootPart
 root.Anchored=false
 root:SetNetworkOwner(nil)
 local hum=p.Character.Humanoid
 local y=2+hum.HipHeight+root.Size.Y/2
 local pos=Vector3.new(wall.Position.X,y,wall.Position.Z-7)
 p.Character:PivotTo(CFrame.lookAt(pos,pos+Vector3.zAxis))
 root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
 root.Anchored=true hum:MoveTo(pos) hum.WalkSpeed=16
 return {Stage=n,Root={pos.X,pos.Y,pos.Z},WallZ=wall.Position.Z}
end
local function combat(n)
 E.StartRun(p,n)
 p:SetAttribute("Strength",B.GetStageConfig(n).RequiredStrength)
 p:SetAttribute("Level",B.GetStageConfig(n).RecommendedLevel)
 session.Data.EquippedItems.Glove=""
 local root=p.Character.HumanoidRootPart local hum=p.Character.Humanoid
 local function move(pos) state:SetAttribute("MoveTarget",pos) end
 root.Anchored=false root:SetNetworkOwner(p)
 task.wait(.4)
 local function at(pos)
  local y=2+hum.HipHeight+root.Size.Y/2+.05
  pos=Vector3.new(pos.X,y,pos.Z)
  p.Character:PivotTo(CFrame.lookAt(pos,pos+Vector3.zAxis))
  root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  hum.WalkSpeed=16 move(pos)
 end
 local row={Stage=n,WallHits=0}
 state:SetAttribute("Stage",n)state:SetAttribute("Phase","Wall")
 local total=0 for _,hp in W.GetStageState(p,n).Gauges do total+=hp end
 local deadline=os.clock()+45
 while not W.IsBossUnlockedForStage(p,n) and os.clock()<deadline do
  local index=W.GetCurrentIndexForStage(p,n)
  local wall=W.GetCurrentWallForStage(p,n).Wall
  at(wall.Position-Vector3.zAxis*5)
  repeat
   task.wait(.03)
   local now=0 for _,hp in W.GetStageState(p,n).Gauges do now+=hp end
   if now<total then row.WallHits+=1 total=now end
  until W.GetCurrentIndexForStage(p,n)~=index or os.clock()>deadline
 end
 assert(W.IsBossUnlockedForStage(p,n),"Wall timeout")
 local e=E.GetEnemy(n) local col=e.MiniBossCollider
 row.ApproachStart={root.Position.X,root.Position.Y,root.Position.Z}
 state:SetAttribute("Phase","Approach")
 local target=Vector3.new(col.Position.X,root.Position.Y,col.Position.Z)
 move(target)
 local battle
 assert(waitFor(function()battle=B.Get(p)return battle~=nil end,9),"Boss not reachable by walking from Wall4")
 row.BossStartHP=battle.HP row.MaxHP=battle.MaxHP
 state:SetAttribute("Phase","Boss")
 task.wait(.85)
 row.StopPosition={root.Position.X,root.Position.Y,root.Position.Z}
 row.ColliderLocal={col.CFrame:PointToObjectSpace(root.Position).X,col.CFrame:PointToObjectSpace(root.Position).Y,col.CFrame:PointToObjectSpace(root.Position).Z}
 row.Fighting=p:GetAttribute("IsFighting")
 move(root.Position)
 -- Retreat before the boss is defeated, then re-enter the same encounter.
 move(root.Position-Vector3.zAxis*12)
 assert(waitFor(function()return not p:GetAttribute("IsFighting")end,3),"Exit failed")
 row.ExitNormal=true
 move(target)
 assert(waitFor(function()return p:GetAttribute("IsFighting")end,4),"Reentry failed")
 row.Reentry=true
 -- Keep walking toward the boss: stopping at the outer trigger edge can rotate
 -- the character away and end combat. The physical collider stops the player.
 move(target)
 assert(waitFor(function()
  if p:GetAttribute("IsFighting")~=true then move(target) end
  return battle.Completed
 end,12),"Boss completion timeout")
 row.BossHits=battle.Attacks row.BossWon=battle.HP==0
 assert(row.BossWon,"Boss not defeated")
 assert(waitFor(function()return workspace.PersonalTrophyHitboxes:FindFirstChild("Trophy_"..p.UserId.."_Stage"..n)end,4),"RewardPad not spawned")
 local pad=workspace.PersonalTrophyHitboxes["Trophy_"..p.UserId.."_Stage"..n]
 row.RewardPadPosition={pad.Position.X,pad.Position.Y,pad.Position.Z}
 row.RewardPadSize={pad.Size.X,pad.Size.Y,pad.Size.Z}
 local function overlaps(a,b)
  local axes={a.CFrame.RightVector,a.CFrame.UpVector,a.CFrame.LookVector,b.CFrame.RightVector,b.CFrame.UpVector,b.CFrame.LookVector}
  local delta=b.Position-a.Position
  local function radius(p,axis)
   return math.abs(axis:Dot(p.CFrame.RightVector))*p.Size.X/2+math.abs(axis:Dot(p.CFrame.UpVector))*p.Size.Y/2+math.abs(axis:Dot(p.CFrame.LookVector))*p.Size.Z/2
  end
  for _,axis in axes do if math.abs(delta:Dot(axis))>radius(a,axis)+radius(b,axis) then return false end end
  return true
 end
 task.wait(.8)
 e=E.GetEnemy(n)
 row.PadColliderOverlap=overlaps(pad,e.MiniBossCollider)
 row.PadZoneOverlap=overlaps(pad,e.CombatZone)
 local minX=math.huge
 for _,v in e:GetChildren() do if v:IsA("Model") then local cf,sz=v:GetBoundingBox() for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do minX=math.min(minX,cf:PointToWorldSpace(sz*Vector3.new(x,y,z)/2).X)end end end end end
 row.PadVisualXClearance=minX-(pad.Position.X+pad.Size.X/2)
 row.WorldComplete=p:GetAttribute("WorldComplete")
 state:SetAttribute("Phase","Complete")
 return row
end
cmd.Changed:Connect(function(value)
 local ok,r=xpcall(function()
 local c=H:JSONDecode(value)
 if c.Action=="place" then return place(c.Stage)
 elseif c.Action=="combat" then return combat(c.Stage)
 elseif c.Action=="restore" then
  state:SetAttribute("MoveTarget",nil)
  local root=p.Character.HumanoidRootPart
  root.Anchored=false E.StartRun(p,original.Attributes.CurrentStage or 1)
  session.Data=original.Data
  for k in p:GetAttributes() do if original.Attributes[k]==nil then p:SetAttribute(k,nil) end end
  for k,v in original.Attributes do p:SetAttribute(k,v) end
  p.Character:PivotTo(original.Pivot)root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  p.Character.Humanoid.WalkSpeed=original.Speed root:SetNetworkOwnershipAuto()
  session.Dirty=original.Dirty session.Saving=false
  return {Restored=true,Strength=p:GetAttribute("Strength"),Win=p:GetAttribute("Win")}
 end
 end,debug.traceback)
 result.Value=H:JSONEncode({ok=ok,result=r})
end)
state:SetAttribute("Ready",true)
