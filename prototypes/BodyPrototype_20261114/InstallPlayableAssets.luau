-- Edit command. Import PlayableBodyPrototype and PlayableShapeConfig beside the
-- existing assets first, and apply the three current src changes separately.
-- This never saves/publishes or installs a StarterPlayer.StarterCharacter.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==126576845524886)
assert(game.GameId==10765181857 and not game:GetService("RunService"):IsRunning())
local folder=assert(game.ServerStorage:FindFirstChild("BodyPrototype_20261114"))
assert(folder:FindFirstChild("PlayableBodyPrototype") and folder:FindFirstChild("PlayableShapeConfig"))
local original=workspace:FindFirstChild("StarterCharacter") or folder:FindFirstChild("StarterCharacter")
assert(original and original:FindFirstChild("UpperTorso") and original:FindFirstChild("Humanoid"))
if not folder:FindFirstChild("PlayableSourceBody") then
 local copy=original:Clone();copy.Name="PlayableSourceBody";copy.Parent=folder
end
original.Parent=folder
local previous=workspace:FindFirstChild("BodyPrototype_20261114")
if previous then
 assert(not folder:FindFirstChild("ArchivedPreviews"),"Retain both existing preview groups; inspect the conflict")
 previous.Name="ArchivedPreviews";previous.Parent=folder
end
folder:SetAttribute("Enabled",true) -- The only ON/OFF switch; change in Edit, then start a new Play.

-- New comparisons stay in ServerStorage. A fresh module instance avoids an old
-- Studio command-bar require cache after updating the prototype source.
local loader=folder.PlayableBodyPrototype:Clone();loader.Name="__PlayableBodyBuild";loader.Parent=folder
local ok,result=pcall(function()
 local prototype=require(loader)
 local reference=assert(folder:FindFirstChild("CurrentAvatarReference"))
 local made={}
 for _,spec in {{1,0},{32,5},{140,10}} do
  local name="Playable_LV"..spec[1]
  if not folder:FindFirstChild(name) then
   local model=reference:Clone();model.Name=name
   for _,v in model:GetDescendants() do if v:IsA("BaseScript") then v:Destroy() end end
   local applied,why=prototype.Apply(model,function()return true end);assert(applied,why)
   assert(prototype.ApplyStage(model,spec[2]))
   local root=model.HumanoidRootPart
   root.CFrame=CFrame.new(0,model.Humanoid.HipHeight+root.Size.Y/2,0)*CFrame.Angles(0,math.pi,0)
   local done={[root]=true}
   for _=1,16 do
    for _,joint in model:GetDescendants() do
     if joint:IsA("Motor6D") and done[joint.Part0] and not done[joint.Part1] then
      joint.Transform=CFrame.identity
      joint.Part1.CFrame=joint.Part0.CFrame*joint.C0*joint.C1:Inverse()
      done[joint.Part1]=true
     end
    end
   end
   for _,shell in model.PrototypeShorts:GetChildren() do
    shell.CFrame=model[shell.Name:gsub("Shorts$","")].CFrame
   end
   for _,acc in model:GetChildren() do
    if acc:IsA("Accessory") then
     local handle=acc:FindFirstChild("Handle")
     local weld=handle and handle:FindFirstChild("AccessoryWeld")
     local rigid=handle and handle:FindFirstChildOfClass("RigidConstraint")
     if weld and weld.Part0 and weld.Part1 then handle.CFrame=weld.Part1.CFrame*weld.C1*weld.C0:Inverse() end
     if rigid and rigid.Attachment0 and rigid.Attachment1 then
      local own=rigid.Attachment0:IsDescendantOf(handle) and rigid.Attachment0 or rigid.Attachment1
      local other=own==rigid.Attachment0 and rigid.Attachment1 or rigid.Attachment0
      handle.CFrame=other.WorldCFrame*own.CFrame:Inverse()
     end
    end
   end
   for _,v in model:GetDescendants() do if v:IsA("BasePart") then v.CanCollide=false;v.CanTouch=false;v.CanQuery=false end end
   root.Anchored=true;model.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
   model:SetAttribute("ComparisonLevel",spec[1]);model:SetAttribute("StaticPreviewOnly",true)
   model.Parent=folder;prototype.Release(model);table.insert(made,model:GetFullName())
  end
 end
 return made
end)
loader:Destroy()
assert(ok,result)
return {Enabled=folder:GetAttribute("Enabled"),Created=result,Original=original:GetFullName()}
