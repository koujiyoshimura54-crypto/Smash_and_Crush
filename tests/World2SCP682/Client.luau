local P=game.Players.LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local request=RS:WaitForChild("FourRequest",60);local reply=RS:WaitForChild("FourReply",60)
if not request or not reply then return end
local labelGui=Instance.new("ScreenGui",P:WaitForChild("PlayerGui"));labelGui.Name="__FourBossQA"
local label=Instance.new("TextLabel",labelGui);label.Size=UDim2.fromOffset(380,24);label.Position=UDim2.new(.5,-190,0,0);label.TextSize=17
request.OnClientEvent:Connect(function(key,action,stage,duration,view)
 if action=="Leave" then game:GetService("StudioTestService"):LeaveTest();return end
 if action=="Preview" then
  local ok,data=pcall(function()return script.Parent.StudioBossAnimationPreview:WaitForChild("__FourPreview"):Invoke(stage)end)
  reply:FireServer(key,ok and data or {Error=tostring(data)});return
 end
 task.spawn(function()
  local result={Stage=stage,VisibleLimbRadians=0,VisibleMovedParts={},ForeignVisibleParts=0,MinBoundsAboveFloor=math.huge,MaxJointGap=0}
  local ok,err=xpcall(function()
   local owner=workspace.World2Enemies:WaitForChild("Owner_"..P.UserId,15)
   local e=owner and owner:WaitForChild(("Stage%02d_Enemy"):format(stage),15);assert(e,"Actor missing")
   local root=e:WaitForChild("HumanoidRootPart",15);assert(root,"Actor root replication timeout")
   local v=e:WaitForChild("SCP-"..({[1]="096",[2]="023",[3]="035",[4]="058",[5]="049",[6]="173",[7]="939",[8]="106",[9]="682",[10]="323"})[stage],15)
   assert(v,"Visual replication timeout")
   task.wait(.6)
   local parts,joints,partNames={},{},{}
   local bones={}
   local index=0
   for _,x in v:GetDescendants() do
    if x:IsA("Bone") and (x.Name:find("Thigh") or x.Name:find("Calf") or x.Name:find("UpperArm") or x.Name:find("Forearm") or x.Name:find("Foot") or x.Name:find("Hand")) then bones[x]=x.Transform
    elseif x:IsA("BasePart") and x.Transparency<.99 then index+=1;parts[x]=root.CFrame:ToObjectSpace(x.CFrame);partNames[x]=x.Name.."_"..index
    elseif x:IsA("Motor6D") and x.Part0 and x.Part1 then table.insert(joints,x) end
   end
   for _,j in joints do if parts[j.Part1] then partNames[j.Part1]=j.Name.."_"..partNames[j.Part1] end end
   local before=root.Position;local start=os.clock();local camera=workspace.CurrentCamera
   label.Text="SCP682 QA / "..P.Name.." / Stage "..stage.." / "..view
   local floor=workspace.World2Map.BattleCorridor[("Stage%02d"):format(stage)]:WaitForChild("Floor",15);assert(floor,"Floor replication timeout")
   local function aim()
    camera=workspace.CurrentCamera
    local cf,size=v:GetBoundingBox();local direction=view=="Side" and root.CFrame.RightVector or root.CFrame.LookVector
    if view=="Normal" then
     -- Ordinary third-person distance, aimed at the encounter for repeatable QA.
     -- This test camera never changes the saved gameplay camera or HUD.
     local p=P.Character.HumanoidRootPart.Position
     local away=Vector3.new(p.X-root.Position.X,0,p.Z-root.Position.Z)
     if away.Magnitude<.1 then away=Vector3.zAxis end
     camera.CameraType=Enum.CameraType.Scriptable
     camera.CFrame=CFrame.lookAt(p+away.Unit*18+Vector3.new(0,9,0),cf.Position)
    else
     camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=50
     local target=cf.Position+root.CFrame.LookVector*5
     camera.CFrame=CFrame.lookAt(target+(direction+Vector3.new(0,.18,0))*(view=="Front" and 30 or 45),target)
    end
   end
   Run:BindToRenderStep("__FourCamera",Enum.RenderPriority.Last.Value+110,aim)
   print("SKIN_CAPTURE S"..stage.."_"..P.Name.."_"..view)
   repeat
    for b,first in bones do
     local _,angle=first:ToObjectSpace(b.Transform):ToAxisAngle();result.VisibleLimbRadians=math.max(result.VisibleLimbRadians,math.abs(angle))
     if math.abs(angle)>.03 then result.VisibleMovedParts[b.Name]=math.max(result.VisibleMovedParts[b.Name] or 0,math.abs(angle)) end
    end
    for part,first in parts do
     if part.Parent then
      local cf=root.CFrame:ToObjectSpace(part.CFrame);local _,a=first:ToObjectSpace(cf):ToAxisAngle()
      if math.abs(a)>.03 then local name=partNames[part];result.VisibleMovedParts[name]=math.max(result.VisibleMovedParts[name] or 0,math.abs(a)) end
      result.VisibleLimbRadians=math.max(result.VisibleLimbRadians,math.abs(a))
      local half=part.Size/2;local c=part.CFrame
      local low=part.Position.Y-math.abs(c.RightVector.Y)*half.X-math.abs(c.UpVector.Y)*half.Y-math.abs(c.LookVector.Y)*half.Z
      result.MinBoundsAboveFloor=math.min(result.MinBoundsAboveFloor,low-floor.Position.Y-floor.Size.Y/2)
     end
    end
    for _,j in joints do
     local a=j.Part0.CFrame*j.C0*j.Transform;local b=j.Part1.CFrame*j.C1
     result.MaxJointGap=math.max(result.MaxJointGap,(a.Position-b.Position).Magnitude)
    end
    task.wait(.05)
   until os.clock()-start>duration
   Run:UnbindFromRenderStep("__FourCamera")
   result.Moved=(root.Position-before).Magnitude;result.Animation=e:GetAttribute("LocalBossAnimation")
   result.Motors=#joints;result.Bones=0;for _,b in v:GetDescendants() do if b:IsA("Bone") then result.Bones+=1 end end;result.Tracks=0
   local diagnostic=script.Parent.World2BossAnimationClient:FindFirstChild("__FourDiagnostics")
   if diagnostic then result.Records=diagnostic:Invoke() end
   for _,x in v:GetDescendants() do if x:IsA("Animator") then result.Tracks+=#x:GetPlayingAnimationTracks() end end
   for _,f in workspace.World2Enemies:GetChildren() do
    if f~=owner then for _,x in f:GetDescendants() do
     if x:IsA("BasePart") and x.Transparency<.99 and x.LocalTransparencyModifier<.99 then result.ForeignVisibleParts+=1 end
    end end
   end
  end,debug.traceback)
  if not ok then result.Error=err end
  reply:FireServer(key,result)
 end)
end)
