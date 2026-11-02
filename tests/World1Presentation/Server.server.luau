local RS=game.ReplicatedStorage
local Driver=require(game.ServerScriptService.__PresentationDriver)
-- Inspection fixture only: prevent incidental chase damage ending a screenshot/sample.
-- Explicit Health=0 still exercises the real death/respawn lifecycle.
task.spawn(function()
 while script.Parent do
  for _,p in game.Players:GetPlayers() do
   local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if h and h.Health>0 then h.Health=h.MaxHealth end
  end
  task.wait(.1)
 end
end)
local request=Instance.new("RemoteEvent");request.Name="__PresentationRequest";request.Parent=RS
local reply=Instance.new("RemoteEvent");reply.Name="__PresentationReply";reply.Parent=RS
local probe=Instance.new("BindableFunction");probe.Name="__PresentationServer"
probe.OnInvoke=function(action,value,index)
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 return Driver.Run(assert(players[index or 1]),action,value)
end;probe.Parent=RS
if script:GetAttribute("Mode")~="Multiplayer" then return end
-- The same current Edit model is copied by native StudioTestService, not a disk rbxl.
local report={Checks={},Snapshots={},Kind="Two real native clients, in-memory stores, prepared combat"}
local responses={}
reply.OnServerEvent:Connect(function(p,key,value)responses[key]={Player=p,Value=value}end)
local function check(ok,label)assert(ok,label);table.insert(report.Checks,label)end
local function ask(p,action,value)
 local key=game.HttpService:GenerateGUID(false);request:FireClient(p,key,action,value)
 local r=Driver.Wait(function()return responses[key]end,15)
 assert(r.Player==p and r.Value.OK,tostring(r.Value.Result));return r.Value.Result
end
local function trophy(s,stage)
 local total=0;for _,r in s.Trophies do if r.Stage==stage then total+=r.VisibleParts+r.EnabledGui+r.EnabledEffects end end;return total
end
local ended=false
local function finish()if ended then return end;ended=true;game:GetService("StudioTestService"):EndTest(report)end
task.delay(150,function()report.Error="Timeout";finish()end)
local ok,err=xpcall(function()
 Driver.Wait(function()return #game.Players:GetPlayers()==2 end,40)
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local a,b=players[1],players[2]
 for _,p in players do Driver.Ready(p);Driver.Run(p,"Stage",8) end
 task.wait(2)
 local first,second=ask(a,"Sample"),ask(b,"Sample");report.Snapshots.Before={first,second}
 check(first.BodyMotion.ChangedBones>0 and second.BodyMotion.ChangedBones>0,"Both owners animate actual Stage8 body bones")
 check(trophy(first.Snapshot,8)==0 and trophy(second.Snapshot,8)==0,"Both whole Trophy pairs hidden before defeat")
 for _,p in players do for _,r in ask(p,"OtherOwners") do check(r.VisibleParts==0 and r.Tracks==0,"Other owner remains invisible and unanimated") end end
 Driver.Run(a,"Defeat");task.wait(.5)
 local defeated,peer=ask(a,"Snapshot"),ask(b,"Sample");report.Snapshots.OneDefeat={defeated,peer}
 check(trophy(defeated,8)>0 and trophy(peer.Snapshot,8)==0,"Only defeated owner sees both Trophy devices")
 check(peer.BodyMotion.ChangedBones>0 and #peer.Snapshot.Tracks==1,"Peer animation continues once after other defeat")
 local beforePrompt=Driver.Run(a,"Status")
 local prompt=Driver.Run(a,"Pad",{Stage=8,Double=true})
 check(prompt.Prompts==beforePrompt.Prompts+1 and prompt.Win==beforePrompt.Win,"Qualified double pad prompts mock purchase without granting Win")
 local cancelled=Driver.Run(a,"CancelPrompt");report.Snapshots.Cancelled=cancelled
 check(not cancelled.PromptBusy and cancelled.Win==beforePrompt.Win,"Mock purchase cancellation releases lock without reward")
 check(trophy(ask(a,"Snapshot"),8)>0,"Purchase cancellation preserves authorized Trophy")
 Driver.Run(a,"Death");task.wait(.3)
 check(trophy(ask(a,"Snapshot"),8)==0,"Owner death hides whole devices")
 check(ask(b,"Sample").BodyMotion.ChangedBones>0,"Peer animation survives other death")
 Driver.Wait(function()local h=a.Character and a.Character:FindFirstChildOfClass("Humanoid");return h and h.Health>0 end,15)
 Driver.Run(a,"Stage",8);task.wait(1)
 local retry=ask(a,"Sample");check(retry.BodyMotion.ChangedBones>0 and #retry.Snapshot.Tracks==1,"Owner retry has one moving track")
 Driver.Run(a,"Defeat")
 local beforeWin=Driver.Run(a,"Status").Win
 local collected=Driver.Run(a,"Pad",{Stage=8});task.wait(1)
 local repeated=Driver.Run(a,"Pad",{Stage=8});report.Snapshots.Collected={Before=beforeWin,After=collected,Repeated=repeated}
 check(collected.Win>beforeWin and repeated.Win==collected.Win,"Normal Trophy grants once, repeated contact grants nothing")
 check(trophy(ask(a,"Snapshot"),8)==0 and trophy(ask(b,"Snapshot"),8)==0,"Normal collection hides owner Trophy and preserves peer")
 check(ask(b,"Sample").BodyMotion.ChangedBones>0,"Peer animation survives other return")
 report.Passed=true
end,debug.traceback)
if not ok then report.Passed=false;report.Error=err end
finish()
