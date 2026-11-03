local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local H=game.HttpService
local players,ready,phase={},false,0
local reports,started={},{}
local remote=Instance.new("RemoteFunction");remote.Name="__EggQAMulti";remote.Parent=RS
local function waitFor(fn,seconds)
 local untilTime=os.clock()+(seconds or 30)
 repeat local r=fn();if r then return r end;task.wait(.1)until os.clock()>untilTime
 error("Multiplayer fixture timeout")
end
local function idle(p)return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
local function state(p)return {Tutorial=D.Get(p).Data.EggPetTutorial,Pets=D.GetPetState(p),Win=D.Get(p).Data.Win}end
local ended=false
local function finish(value)if ended then return end;ended=true;game:GetService("StudioTestService"):EndTest(H:JSONEncode(value))end
task.spawn(function()
 local ok,err=xpcall(function()
  waitFor(function()return #game.Players:GetPlayers()==2 end,40)
  players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
  for i,p in players do
   local s=idle(p);if s.StudioStartOverride then D.RestoreStudioStartOverride(p)end
   idle(p);assert(D.Reset(p));D.SetAutoTapEnabled(p,false);assert(D.CompleteTutorial(p));D.SetWin(p,i==1 and 3 or 2)
   local root=waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)
   p:SetAttribute("CurrentWorld",1);require(game.ServerScriptService.Services.LobbySpawnService).MoveToLobby(p,p.Character,1);root.Anchored=true
  end
  ready=true
 end,debug.traceback)
 if not ok then finish({Error=err})end
end)
remote.OnServerInvoke=function(p,action,v)
 if action=="Ready" then waitFor(function()return ready end,50);return table.find(players,p)
 elseif action=="Started" then started[p]=true;waitFor(function()return started[players[1]] and started[players[2]]end);return true
 elseif action=="Basic" then p.Character:PivotTo(workspace.Eggs.Basic.CFrame+Vector3.new(0,0,5));return true
 elseif action=="CompletedA" then assert(p==players[1] and state(p).Tutorial.Completed);phase=1;return state(players[2])
 elseif action=="WaitA" then waitFor(function()return phase>=1 end,35);return state(p)
 elseif action=="ResetA" then
  assert(p==players[1]);idle(p);assert(D.Reset(p));assert(D.CompleteTutorial(p));D.SetAutoTapEnabled(p,false);D.SetWin(p,2);phase=2;return state(p)
 elseif action=="StartB" then
  assert(p==players[2]);waitFor(function()return phase==2 end);D.SetWin(p,3);return state(players[1])
 elseif action=="Report" then
  reports[table.find(players,p)]=v
  if reports[1] and reports[2] then task.defer(function()finish({Reports=reports,States={state(players[1]),state(players[2])}})end)end
  return true
 end
 error(action)
end
task.delay(110,function()finish({Timeout=true,Reports=reports})end)
