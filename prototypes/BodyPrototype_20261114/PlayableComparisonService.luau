-- Session-only comparison controls. This module is never required outside the gate.
local RunService=game:GetService("RunService")
local folder=script.Parent
local function enabled()
 return RunService:IsStudio() and game.PlaceId==126576845524886 and folder:GetAttribute("Enabled")==true
end
if not enabled()then return table.freeze({})end
local Players=game:GetService("Players")
local Placement=require(game.ServerScriptService.Services.LobbySpawnService)
local Shape=require(folder.PlayableShapeConfig)
local Prototype=require(folder.PlayableBodyPrototype)
local M={}
local sessions=setmetatable({}, {__mode="k"})
local remote,refresh,started
local function session(player)
 local s=sessions[player]
 if not s then s={Settings={Active=false,Body="Normal",Mode="Growth",Stage=0,Height=1,Thickness=1},Revision=0,Busy=false,Last=-math.huge};sessions[player]=s end
 return s
end
function M.Get(player)return table.clone(session(player).Settings),session(player).Revision end
local function send(player,code,id,message,extra)
 if not remote or player.Parent~=Players then return end
 local s=sessions[player];if not s then return end;local c=player.Character
 local packet={Code=code,RequestId=id,Message=message,Settings=table.clone(s.Settings),Busy=s.Busy,
  Stage=c and c:GetAttribute("BodyPrototypeStage"),Height=c and c:GetAttribute("BodyComparisonHeight"),BaseHeight=c and c:GetAttribute("BodyComparisonBaseHeight")}
 for key,value in extra or {}do packet[key]=value end
 remote:FireClient(player,packet)
end
function M.Updated(player)send(player,"State")end
local function finite(value,lo,hi)
 return typeof(value)=="number"and value==value and value>=lo and value<=hi
end
function M.Validate(value)
 if typeof(value)~="table"then return nil end
 if value.Body~="Normal"and value.Body~="Muscle"then return nil end
 if value.Mode~="Growth"and value.Mode~="Manual"then return nil end
 if not finite(value.Stage,0,10)or value.Stage%1~=0 then return nil end
 if not finite(value.Height,Shape.Manual.MinHeight,Shape.Manual.MaxHeight)or not finite(value.Thickness,Shape.Manual.MinThickness,Shape.Manual.MaxThickness)then return nil end
 return {Active=true,Body=value.Body,Mode=value.Mode,Stage=value.Stage,Height=math.round(value.Height*100)/100,Thickness=math.round(value.Thickness*100)/100}
end
function M.Handle(player,packet)
 if not enabled()or player.Parent~=Players or typeof(packet)~="table"then return end
 local id=packet.Id
 if id~=nil and(not finite(id,0,1e9)or id%1~=0)then return end
 local s=session(player)
 if packet.Action=="Prepared"or packet.Action=="Ready"or packet.Action=="ClientFailed"then
  local job=s.Job
  if job and packet.Token==job.Token and packet.Character==job.Character then
   if packet.Action=="Prepared"then job.Prepared=true
   elseif packet.Action=="Ready"and packet.Revision==job.PoseRevision then job.Ready=true
   elseif packet.Action=="ClientFailed"then job.Failed=true end
  end
  return
 end
 if packet.Action=="Get"then send(player,"State",id);return end
 if s.Busy or os.clock()-s.Last<.2 then send(player,"Busy",id,"変更処理中です");return end
 local nextSettings
 if packet.Action=="Clear"then
  nextSettings=table.clone(s.Settings);nextSettings.Active=false;nextSettings.Body="Normal"
 elseif packet.Action=="Set"then nextSettings=M.Validate(packet.Settings)end
 if not nextSettings then send(player,"Invalid",id,"比較設定の範囲を確認してください");return end
 local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
 if packet.Character~=c or not Placement.IsCharacterCurrent(player,c)or not c:GetAttribute("MuscleScaleReady")or not c:GetAttribute("BodyPrototypeManaged")or not root or root.Anchored then
  send(player,"Unavailable",id,"生成・移動完了後に再試行してください");return
 end
 s.Busy=true;s.Last=os.clock()
 local job={Character=c,World=Placement.WorldFor(player),Token=s.Revision+1,Anchored=root.Anchored};s.Job=job
 job.Request=Placement.CancelPending(player)
 job.Request.Root=root;job.Request.Anchored=job.Anchored;root.Anchored=true
 local originalNeck=Prototype.BeginTransition(c)
 local function valid()return sessions[player]==s and s.Job==job and Placement.IsCharacterCurrent(player,c)and Placement.IsCurrent(player,job.Request)and Placement.WorldFor(player)==job.World end
 local function await(key)
  local deadline=os.clock()+3
  while valid()and not job[key]and not job.Failed and os.clock()<deadline do RunService.Heartbeat:Wait()end
  return valid()and job[key]==true and not job.Failed
 end
 local function finish()
  local restoreAnchor
  if Placement.IsCurrent(player,job.Request)then
   restoreAnchor=job.Anchored;job.Request.Root=nil
   for _,part in c:GetDescendants()do if part:IsA("BasePart")then part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero end end
   root.Anchored=job.Anchored
  end
  Prototype.EndTransition(c)
  s.Busy=false;s.Job=nil
  send(player,"Release",id,nil,{Token=job.Token,Character=c,RestoreNeck=originalNeck,RestoreAnchor=restoreAnchor})
 end
 send(player,"Prepare",id,nil,{Token=job.Token,Character=c,RestoreNeck=originalNeck})
 if not await("Prepared")then finish();send(player,"Failed",id,"準備を確認できませんでした。元の表示を保持します");return end
 local previous=s.Settings
 s.Settings=nextSettings;s.Revision+=1
 local ok,applied,why=pcall(refresh,player,true)
 if ok and applied then
  job.PoseRevision=c:GetAttribute("BodyComparisonRevision")
  send(player,"Commit",id,nil,{Token=job.Token,Character=c,Revision=job.PoseRevision})
  if not await("Ready")then ok=false;why="Client pose confirmation timed out"end
 end
 if not ok or not applied then
  s.Settings=previous;s.Revision+=1
  local restored=false
  if valid()then
   local rollbackOk,result=pcall(refresh,player,true)
   if rollbackOk and result then
    job.Ready=false;job.Failed=false;job.PoseRevision=c:GetAttribute("BodyComparisonRevision")
    send(player,"Commit",id,nil,{Token=job.Token,Character=c,Revision=job.PoseRevision})
    restored=await("Ready")
   end
  end
  finish()
  warn("[BodyComparison] "..tostring(why or applied))
  send(player,"Failed",id,"変更に失敗しました。前の設定を維持します")
  if not restored and Placement.IsCharacterCurrent(player,c)then task.defer(function()if Placement.IsCharacterCurrent(player,c)then Placement.LoadCharacter(player,c)end end)end
  return
 end
 finish();send(player,"Success",id)
end
function M.Start(callback)
 if started or not enabled()then return end
 started=true;refresh=callback
 local existing=game.ReplicatedStorage:FindFirstChild("BodyComparison")
 assert(not existing,"BodyComparison remote already exists")
 local container=Instance.new("Folder");container.Name="BodyComparison";container:SetAttribute("Enabled",true);container.Parent=game.ReplicatedStorage
 remote=Instance.new("RemoteEvent");remote.Name="Request";remote.Parent=container
 remote.OnServerEvent:Connect(M.Handle)
 local function bind(player)
  session(player)
  task.spawn(function()
   local gui=player:WaitForChild("PlayerGui",10)
   if not enabled()or player.Parent~=Players or not sessions[player]or not gui then return end
   if gui:FindFirstChild("BodyComparisonGui")then return end
   local screen=Instance.new("ScreenGui");screen.Name="BodyComparisonGui";screen.ResetOnSpawn=false;screen.DisplayOrder=75;screen.IgnoreGuiInset=false
   screen:SetAttribute("ComparisonEnabled",true)
   local client=folder.ComparisonClient:Clone();client.Parent=screen
   screen.Parent=gui
  end)
 end
 Players.PlayerAdded:Connect(bind)
 Players.PlayerRemoving:Connect(function(player)sessions[player]=nil end)
 for _,player in Players:GetPlayers()do bind(player)end
end
return M
