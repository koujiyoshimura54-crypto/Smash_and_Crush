-- Client observations only. Server owns cohort, eligibility, acceptance and commits.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local M={}
local reader,started,remote,readyAck
local sequence=0
local lastSignature,lastSend,readyAttempts=nil,-math.huge,0
local function snapshot()
 if not reader then return nil end
 local ok,v=pcall(reader)
 if not ok or type(v)~="table" then return nil end
 local token=player:GetAttribute("MTFSession")
 if not token then return nil end
 sequence+=1
 v.Session=token;v.Character=player.Character;v.Sequence=sequence
 return v
end
function M.Snapshot()
 local ok,v=pcall(snapshot);return ok and v or nil
end
local function observe(force)
 if not remote or player:GetAttribute("MTFNewFirstSession")~=true or player:GetAttribute("MTFOreFinished")==true then return end
 local v=M.Snapshot();if not v then return end
 local parts={tostring(v.Open),tostring(v.Token),tostring(v.Generation),tostring(player:GetAttribute("ForgeInventoryRevision"))}
 local ids={} for id in v.Materials or {} do table.insert(ids,id) end;table.sort(ids)
 for _,id in ids do table.insert(parts,id..":"..tostring(v.Materials[id])) end
 local signature=table.concat(parts,"|")
 if not force and signature==lastSignature then return end
 if os.clock()-lastSend<.25 then return end
 lastSignature=signature;lastSend=os.clock()
 remote:FireServer("OreView",v)
end
function M.BindOre(fn,event)
 reader=fn
 if event then event:Connect(function()task.defer(function()pcall(observe,false)end)end) end
end
local function visible(o)
 if not o or not o:IsA("GuiObject") or o.AbsoluteSize.X<=0 or o.AbsoluteSize.Y<=0 then return false end
 local n=o
 while n and n~=player.PlayerGui do
  if n:IsA("GuiObject") and not n.Visible or n:IsA("ScreenGui") and not n.Enabled then return false end
  n=n.Parent
 end
 return true
end
local controls
local function playable()
 local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 if not game:IsLoaded() or player:GetAttribute("MTFDataLoaded")~=true or not r or r.Anchored or not h or h.Health<=0
  or not c:GetAttribute("LobbySpawnPlaced") or not c:GetAttribute("SpawnEngineReady") or not c:GetAttribute("MuscleScaleReady") then return nil end
 local pg=player:FindFirstChild("PlayerGui");if not pg then return nil end
 local loading=pg:FindFirstChild("LoadingScreen")
 if loading and loading:IsA("ScreenGui") and loading.Enabled then return nil end
 local initial=game.ReplicatedFirst:FindFirstChild("LoadingScreen")
 local loader=initial and initial:FindFirstChild("LoadingClient")
 if initial and initial.Enabled and loader and loader.Enabled then return nil end
 if not controls then
  local scripts=player:FindFirstChild("PlayerScripts")
  local pm=scripts and scripts:FindFirstChild("PlayerModule") or game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
  if not pm then return nil end
  local controlModule=pm:FindFirstChild("ControlModule");if not controlModule then return nil end
  controls=require(controlModule)
 end
 if not controls or controls.controlsEnabled~=true or not controls.activeController or controls.activeController.enabled~=true then return nil end
 local g=pg:FindFirstChild("StrengthGui");local hud=g and g:FindFirstChild("StrengthLevelHUD")
 local panel=hud and hud:FindFirstChild("LevelPanel");local bar=panel and panel:FindFirstChild("StrengthProgressBar")
 local total=hud and hud:FindFirstChild("StrengthValueContainer");local health=hud and hud:FindFirstChild("PlayerHealth")
 local auto=panel and panel:FindFirstChild("AutoTapButton")
 if not bar or not total or not health or not auto then return nil end
 for _,label in {bar:FindFirstChild("Level"),bar:FindFirstChild("Exp"),total:FindFirstChild("Strength"),health:FindFirstChild("Exp"),auto:FindFirstChild("State")} do
  if not visible(label) or label.Text=="" or label.Text:find("--",1,true) then return nil end
 end
 if not bar:FindFirstChild("Level") or not bar:FindFirstChild("Exp") or not total:FindFirstChild("Strength")
  or not health:FindFirstChild("Exp") or not auto:FindFirstChild("State") then return nil end
 return {Session=player:GetAttribute("MTFSession"),Character=c,Revision=c:GetAttribute("SpawnPlacementRevision"),
  HUDReady=true,ControlsReady=true,LoadingGone=true}
end
function M.Start()
 if started then return end;started=true
 local elapsed,readyAt=0,-math.huge
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<.25 then return end;elapsed=0
  remote=remote or RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("FirstPlayAnalytics")
  if not remote then return end
  if not M.Listening then
   M.Listening=true
   remote.OnClientEvent:Connect(function(action,token,value)
    if token~=player:GetAttribute("MTFSession") then return end
    if action=="PlayableAck" and value==true then readyAck=true
    elseif action=="RefreshOre" then lastSignature=nil;task.defer(function()pcall(observe,true)end) end
   end)
  end
  if not readyAck and readyAttempts<5 and os.clock()-readyAt>=2 then
   local ok,v=pcall(playable)
   if ok and v then readyAttempts+=1;readyAt=os.clock();remote:FireServer("Playable",v) end
  end
  pcall(observe,false)
 end)
end
return M
