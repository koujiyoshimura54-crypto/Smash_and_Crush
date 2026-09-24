local T={}
function T.Run()
 local storage=Instance.new("Folder");storage.Name="PinkEffectTestSandbox";storage.Parent=game.ServerStorage
 local state=Instance.new("ModuleScript");state.Name="AuraService";state.Source=[==[
local M={Loaded=false,Owned=false,Equipped=""}
function M.GetEquippedAura() return M.Loaded and M.Owned and M.Equipped or nil end
return M
]==];state.Parent=storage
 local mod=game.ServerScriptService.Services.AuraCharacterEffects:Clone();mod.Parent=storage
 local Aura=require(state);local Effects=require(mod)
 local events={}
 local function signal() local e=Instance.new("BindableEvent");table.insert(events,e);return e end
 local added,removing,attribute=signal(),signal(),signal()
 local p={Name="PinkEffectFixture",CharacterAdded=added.Event,CharacterRemoving=removing.Event}
 function p:GetAttributeChangedSignal() return attribute.Event end
 function p:SetAttribute(_,value) self.Value=value;attribute:Fire() end
 function p:Destroy() for _,e in ipairs(events) do e:Destroy() end end
 local function setCharacter(c)
  if p.Character then removing:Fire(p.Character);task.wait() end
  p.Character=c;added:Fire(c)
 end
 local rigs={}
 local results={}
 local function flush() task.wait(.1) end
 local function rig(withRoot)
  local c=Instance.new("Model");c.Name="PinkEffectTestRig";c.Parent=workspace
  local h=Instance.new("Humanoid");h.RequiresNeck=false;h.Parent=c
  if withRoot then local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1);root.Anchored=true;root.CFrame=CFrame.new(0,10,0);root.Parent=c end
  table.insert(rigs,c);return c
 end
 local function count(c)
  local f=c:FindFirstChild("AuraEffects");local n=0
  if f then for _,x in ipairs(f:GetChildren()) do if x.Name=="PinkAura" then n+=1 end end end
  return n
 end
 local function change(id)
  Aura.Equipped=id;p:SetAttribute("EquippedAura",id);flush()
 end
 local ok,err=xpcall(function()
  local c=rig(true);setCharacter(c);Effects.Bind(p);flush()
  assert(count(c)==0);table.insert(results,"PASS unloaded/unequipped: no effect")
  Aura.Loaded=true;Aura.Owned=true;change("Pink")
  assert(count(c)==1)
  local effect=c.AuraEffects.PinkAura
  assert(effect.Size==workspace["vfx pack"].VFX.PinkAura2.Size)
  assert(not effect.Anchored and not effect.CanCollide and not effect.CanTouch and not effect.CanQuery and effect.Massless and effect.Transparency==1)
  assert(effect.RootWeld.Part0==c.HumanoidRootPart and effect.RootWeld.Part1==effect)
  for _,key in ipairs({"Texture","Color","Rate","Lifetime","Speed","Shape","ShapeStyle","ShapeInOut","Transparency","RotSpeed","LightEmission","LockedToPart"}) do assert(effect.Core[key]==workspace["vfx pack"].VFX.PinkAura2.Core[key],key) end
  local function verifySize(part)
   local original=workspace["vfx pack"].VFX.PinkAura2.Core.Size.Keypoints
   for i,k in ipairs(part.Core.Size.Keypoints) do
    assert(k.Time==original[i].Time and math.abs(k.Value-original[i].Value*.67)<.0001 and math.abs(k.Envelope-original[i].Envelope*.67)<.0001)
   end
  end
  verifySize(effect)
  table.insert(results,"PASS Size scaled 0.67; other emitter and physics settings unchanged")
  Effects.Bind(p);Effects.Sync(p);Effects.Sync(p);assert(count(c)==1)
  change("");assert(count(c)==0)
  change("Pink");assert(count(c)==1)
  change("Purple");assert(count(c)==0)
  change("Pink");assert(count(c)==1)
  table.insert(results,"PASS equip/unequip/switch and repeated sync: no duplicate")
  c.HumanoidRootPart.CFrame=CFrame.new(12,15,4)*CFrame.Angles(0,1,0);flush()
  assert((c.AuraEffects.PinkAura.Position-c.HumanoidRootPart.Position).Magnitude<.05)
  table.insert(results,"PASS root translation/rotation/vertical movement follows")
  c.Humanoid.Health=0;flush();assert(count(c)==0)
  local respawn=rig(true);setCharacter(respawn);flush();assert(count(respawn)==1);verifySize(respawn.AuraEffects.PinkAura)
  table.insert(results,"PASS death cleanup and respawn restores Pink")
  Aura.Loaded=false
  local late=rig(false);setCharacter(late);flush();assert(count(late)==0)
  Aura.Loaded=true;Effects.Sync(p);assert(count(late)==0)
  local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true;root.Parent=late;flush();assert(count(late)==1)
  table.insert(results,"PASS data first, root later")
  Aura.Loaded=false
  local rejoin=rig(true);setCharacter(rejoin);flush();assert(count(rejoin)==0)
  Aura.Loaded=true;Effects.Sync(p);assert(count(rejoin)==1)
  table.insert(results,"PASS character first, restored data later (rejoin equivalent)")
  Aura.Owned=false;p:SetAttribute("EquippedAura","Red");flush();p:SetAttribute("EquippedAura","Pink");flush();assert(count(rejoin)==0)
  table.insert(results,"PASS forged display attribute without authoritative ownership rejected")
 end,debug.traceback)
 Effects.Unbind(p);p:Destroy()
 for _,c in ipairs(rigs) do c:Destroy() end
 storage:Destroy()
 if not ok then error(err) end
 return results
end
return T
