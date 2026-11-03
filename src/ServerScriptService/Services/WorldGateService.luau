-- Gate prompts and travel share server-owned contact and saved unlock checks.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(RS.Config.WorldGateConfig)
local Contact=require(RS.Modules.WorldGateContact)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Badges=require(game.ServerScriptService.Services.BadgeAwardService)
local remote=RS.Remotes:WaitForChild("WorldTravelRequest")
local M={}
local sessions=setmetatable({},{__mode="k"})
local started=false
local Enemy,Placement
local function world(p)return p:GetAttribute("CurrentWorld")==2 and 2 or 1 end
local function alive(p)
 local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
 return c and h and h.Health>0 and c:FindFirstChild("HumanoidRootPart") and c or nil
end
local function ready(id)
 if id~=1 and id~=2 then return false end -- No implicit/fallback World3 destination.
 local entry=Config.Worlds[id]
 return entry and entry.Ready==true and Placement.GetLobby(id)~=nil
end
function M.State(p)
 local current=world(p)
 local cards={}
 for _,entry in Config.Worlds do
  local available=ready(entry.Id)==true and Data.CanAccessWorld(p,entry.Id)==true
  cards[#cards+1]={Id=entry.Id,Status=available and (current==entry.Id and "Current" or "Teleport") or "Locked"}
 end
 return {CurrentWorld=current,Worlds=cards}
end
local function session(p)
 local s=sessions[p]
 if not s then s={LastRequest=-math.huge};sessions[p]=s end
 return s
end
local function send(p,kind,extra)
 local result=M.State(p);result.Type=kind
 if extra then for k,v in extra do result[k]=v end end
 remote:FireClient(p,result)
end
local function travel(p,target)
 local s=session(p);local now=os.clock()
 if s.Busy or now-s.LastRequest<1 then send(p,"Result",{Success=false,Code="Busy"});return end
 s.LastRequest=now
 if type(target)~="number" or target%1~=0 or not ready(target) or not Data.CanAccessWorld(p,target) then
  send(p,"Result",{Success=false,Code="Locked"});return
 end
 local source=world(p)
 if source==target then send(p,"Result",{Success=false,Code="Current"});return end
 local c=alive(p);local wall=Contact.Wall(source)
 if not c or not Contact.Touching(wall,c,Config.ContactPadding) then send(p,"Result",{Success=false,Code="NotAtGate"});return end
 s.Busy=true
 local token=p:GetAttribute("ForgeSessionToken")
 local ok,success,code=pcall(function()
  local request=Placement.StreamLobby(p,c,target)
  if not request or not Placement.IsCurrent(p,request) or alive(p)~=c or world(p)~=source
   or p:GetAttribute("ForgeSessionToken")~=token or not Data.CanAccessWorld(p,target)
   or not ready(target) or not Contact.Touching(wall,c,Config.ContactPadding) then return false,"TravelCancelled" end
  if not Placement.MoveToLobby(p,c,target) then return false,"PlacementUnavailable" end
  Enemy.ForWorld(source).Deactivate(p)
  p:SetAttribute("CurrentWorld",target)
  if target==2 then Data.MarkWorld2Reached(p) end
  Enemy.ForWorld(target).Activate(p)
  if target==2 then Badges.Award(p,"IntoWorld2") end
  s.Contact=nil;s.ExitSince=nil;s.SuppressUntil=os.clock()+1
  return true,"Travelled"
 end)
 s.Busy=false
 if not ok then warn("[WorldTravel] "..tostring(success));success=false;code="TravelFailed" end
 if p.Parent==Players then send(p,"Result",{Success=success==true,Code=code}) end
end
function M.Start(enemy,placement)
 if started then return end;started=true;Enemy=enemy;Placement=placement
 remote.OnServerEvent:Connect(function(p,action,target)
  if action=="State" then
   local s=session(p);local now=os.clock()
   if now-(s.LastState or -math.huge)<.2 then return end;s.LastState=now;send(p,"State")
  elseif action=="Teleport" then travel(p,target)
  -- Retain the existing route names, with the same strengthened validation.
  elseif action=="ToWorld2" then travel(p,2)
  elseif action=="ReturnWorld1" then travel(p,1) end
 end)
 local elapsed=0
 RunService.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<Config.ContactInterval then return end;elapsed=0
  for _,p in Players:GetPlayers() do
   local s=session(p);local c=alive(p);local id=world(p);local wall=Contact.Wall(id)
   local contact=c and Data.CanAccessWorld(p,id) and Contact.Touching(wall,c,s.Contact and Config.ExitPadding or Config.ContactPadding)
   if s.Character~=c or s.World~=id then
    if s.Contact then send(p,"Close") end
    s.Contact=nil;s.ExitSince=nil;s.Character=c;s.World=id
   end
   if contact and not s.Busy and os.clock()>=(s.SuppressUntil or 0) then
    s.ExitSince=nil
    if not s.Contact then s.Contact=wall;send(p,"Open") end
   elseif not contact and s.Contact then
    s.ExitSince=s.ExitSince or os.clock()
    if not c or os.clock()-s.ExitSince>=Config.ExitDelay then s.Contact=nil;s.ExitSince=nil;send(p,"Close") end
   end
  end
 end)
 Players.PlayerRemoving:Connect(function(p)sessions[p]=nil end)
end
return M
