local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local Pet=require(RS.Modules.Pet)
local Memory=require(RS.__PMQAMemory)
local H=game.HttpService
local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local players,ready,phase={},false,0
local reports,started={},{}
local remote=Instance.new("RemoteFunction");remote.Name="__PMMulti";remote.Parent=RS
local function waitFor(fn,seconds)
 local untilTime=os.clock()+(seconds or 30)
 repeat local r=fn();if r then return r end;task.wait(.1)until os.clock()>untilTime
 error("PM multiplayer fixture timeout")
end
local function idle(p)return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
local function state(p)return {Tutorial=D.Get(p).Data.PetMergeTutorial,Pets=D.GetPetState(p),Win=D.Get(p).Data.Win}end
local ended=false
local function finish(value)if ended then return end;ended=true;game:GetService("StudioTestService"):EndTest(H:JSONEncode(value))end
task.spawn(function()
 local ok,err=xpcall(function()
  waitFor(function()return #game.Players:GetPlayers()==2 end,40)
  players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
  for _,p in players do
   local s=idle(p);if s.StudioStartOverride then D.RestoreStudioStartOverride(p)end
   idle(p);assert(D.Reset(p));D.SetAutoTapEnabled(p,false);assert(D.CompleteTutorial(p));D.SetWin(p,0);assert(D.Save(p))
   store:UpdateAsync("Player_"..p.UserId,function(raw)
    local pets=assert(Pet.NormalizeState(nil));pets.Owned["copy-a"]="Grey Cat";pets.Owned["copy-b"]="Dog";raw.Pets=pets;return raw
   end)
   local g=D.Get(p).PetViewGeneration or 0;D.Release(p);assert(D.Load(p));D.Get(p).PetViewGeneration=g+1;p:SetAttribute("PetViewGeneration",g+1)
   local root=waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)
   p:SetAttribute("CurrentWorld",1);require(game.ServerScriptService.Services.LobbySpawnService).MoveToLobby(p,p.Character,1);root.Anchored=true
  end
  ready=true
 end,debug.traceback)
 if not ok then finish({Error=err})end
end)
remote.OnServerInvoke=function(p,action,v)
 if action=="Ready"then waitFor(function()return ready end,50);return table.find(players,p)
 elseif action=="Started"then started[p]=true;waitFor(function()return started[players[1]]and started[players[2]]end);return true
 elseif action=="MergeArea"then p.Character:PivotTo(workspace.RestockShop.Area.CFrame+Vector3.new(0,2,0));return true
 elseif action=="CompletedA"then assert(p==players[1]and state(p).Tutorial.Completed);phase=1;return state(players[2])
 elseif action=="WaitA"then waitFor(function()return phase>=1 end,40);return state(p)
 elseif action=="ResetA"then
  assert(p==players[1]);idle(p);assert(D.Reset(p));assert(D.CompleteTutorial(p));D.SetAutoTapEnabled(p,false);D.SetWin(p,0);phase=2;return state(p)
 elseif action=="StartB"then assert(p==players[2]);waitFor(function()return phase>=2 end);return state(players[1])
 elseif action=="CheckA"then return state(players[1])
 elseif action=="Report"then reports[table.find(players,p)]=v
  if reports[1]and reports[2]then task.defer(function()finish({Reports=reports,States={state(players[1]),state(players[2])}})end)end;return true
 end
 error(action)
end
task.delay(115,function()finish({Timeout=true,Reports=reports})end)
