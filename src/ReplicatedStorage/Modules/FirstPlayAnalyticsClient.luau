-- Client observations only. Server owns cohort, eligibility, acceptance and commits.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local M={}
local reader,started,remote,readyAck
local sequence,viewRevision=0,0
local readyAttempts=0
local guideReader,lastRendered,viewIdentity
local lastSignature,lastSend,attempts=nil,-math.huge,0
local function readView()
 if not reader then return nil end
 local ok,v=pcall(reader)
 if not ok or type(v)~="table" then return nil end
 return v
end
function M.BindMergeGuide(fn)
 guideReader=fn
 return function()if guideReader==fn then guideReader=nil end end
end
function M.Snapshot()
 local ok,value=pcall(function()
  local v=readView();local r=lastRendered
  if not v or not r or os.clock()-r.At>1 or r.Character~=player.Character
   or r.PostBattleToken~=player:GetAttribute("MTFPostBattleToken") or r.Session~=player:GetAttribute("MTFSession")
   or v.Token~=r.Token or v.Generation~=r.Generation or v.CloseRevision~=r.CloseRevision
   or v.Open~=true or r.Open~=true or v.Tab~="Ore" or v.Selling~=false then return nil end
  sequence+=1
  local result=table.clone(r);result.At=nil;result.Sequence=sequence;result.Materials=v.Materials
  return result
 end)
 return ok and value or nil
end
function M.BindOre(fn,event)
 reader=fn -- Observe on rendered frames, not view-model/Target attribute changes.
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
local function renderedPanel(o)
 if not o then return false end
 local pg=player:FindFirstChild("PlayerGui");local camera=workspace.CurrentCamera
 if not pg or not camera then return false end
 local a,b=o.AbsolutePosition,o.AbsolutePosition+o.AbsoluteSize
 local n=o
 while n and n~=pg do
  if n:IsA("GuiObject") then
   if not n.Visible then return false end
   if n.ClipsDescendants then
    local x,y=n.AbsolutePosition,n.AbsolutePosition+n.AbsoluteSize
    a=Vector2.new(math.max(a.X,x.X),math.max(a.Y,x.Y));b=Vector2.new(math.min(b.X,y.X),math.min(b.Y,y.Y))
   end
  elseif n:IsA("ScreenGui") and not n.Enabled then return false end
  n=n.Parent
 end
 local size=camera.ViewportSize
 return n==pg and math.min(b.X,size.X)>math.max(a.X,0)+1 and math.min(b.Y,size.Y)>math.max(a.Y,0)+1
end
local function observe()
 if not remote or player:GetAttribute("MTFNewFirstSession")~=true or player:GetAttribute("MTFOreFinished")==true then return end
 local challenge=player:GetAttribute("MTFPostBattleToken");if not challenge then return end
 local v=readView();if not v then return end
 v.Open=v.Open==true and v.Tab=="Ore" and v.Selling==false and renderedPanel(v.Panel)
 v.Panel=nil
 local identity={Character=player.Character,Open=v.Open,Token=v.Token,Generation=v.Generation,CloseRevision=v.CloseRevision}
 local changed=not viewIdentity
 if viewIdentity then for k,value in identity do if viewIdentity[k]~=value then changed=true;break end end end
 if changed then viewRevision+=1;viewIdentity=identity end
 local ready=playable()
 v.Ready=ready~=nil;v.HUDReady=ready and ready.HUDReady;v.ControlsReady=ready and ready.ControlsReady;v.LoadingGone=ready and ready.LoadingGone
 v.Revision=player.Character and player.Character:GetAttribute("SpawnPlacementRevision")
 local ok,shown=pcall(function()return guideReader and guideReader()end)
 v.GuideShown=ok and shown==true
 v.Session=player:GetAttribute("MTFSession");v.PostBattleToken=challenge;v.Character=player.Character
 v.ViewRevision=viewRevision;v.Rendered=true;v.At=os.clock()
 lastRendered=table.clone(v)
 local signature=table.concat({tostring(v.Session),challenge,tostring(viewRevision),tostring(v.Revision),tostring(v.Ready),tostring(v.GuideShown),tostring(v.Tab),tostring(v.Selling)},"|")
 if signature~=lastSignature then lastSignature=signature;attempts=0 end
 -- Bounded observation retries handle placement/message races, never retry Analytics API sends.
 if attempts>=5 or os.clock()-lastSend<(attempts==0 and .25 or 1) then return end
 sequence+=1;v.Sequence=sequence;v.At=nil
 lastSend=os.clock();attempts+=1
 remote:FireServer("OreView",v)
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
    elseif action=="RefreshOre" then lastSignature=nil end
   end)
  end
  if not readyAck and readyAttempts<5 and os.clock()-readyAt>=2 then
   local ok,v=pcall(playable)
   if ok and v then readyAttempts+=1;readyAt=os.clock();remote:FireServer("Playable",v) end
  end
 end)
 local renderElapsed=0
 Run.RenderStepped:Connect(function(dt)
  renderElapsed+=dt;if renderElapsed<.1 then return end;renderElapsed=0
  pcall(observe)
 end)
end
return M
