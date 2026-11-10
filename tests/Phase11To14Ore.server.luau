-- Install only in a temporary memory-isolated Play session.
local RS=game.ReplicatedStorage
local Mem=require(RS.__Phase110Memory)
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local Forge=require(S.ForgeService)
local Run=require(S.RunInventoryService)
local Bank=require(S.RunItemBankService)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn)
 local deadline=os.clock()+25
 repeat local v=fn();if v then return v end task.wait(.05)until os.clock()>deadline
 error("Ore QA timeout")
end
waitFor(function()return D.Get(p) and D.Get(p).Loaded and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)
D.SetAutoTapEnabled(p,false)
local function state()return {Ores=table.clone(D.Get(p).Data.OwnedOres),Bag=Run.GetSnapshot(p),Win=D.Get(p).Data.Win}end
local last
local bf=Instance.new("BindableFunction");bf.Name="__PhaseOreServer";bf.Parent=game.ServerStorage
bf.OnInvoke=function(action,value)
 if action=="Grant" then
  assert(D.CompleteTutorial(p))
  for i=1,32 do
   local id=string.format("ORE_%03d",i)
   for _=1,2 do waitFor(function()return not D.Get(p).Saving end);local ok,why=Forge.GrantOre(p,id,game.HttpService:GenerateGUID(false));assert(ok,why)end
  end
  return state()
 elseif action=="Cue" then
  p:SetAttribute("CurrentWorld",1)
  local s=Run.GetSnapshot(p)
  if not s or not Run.IsCurrent(p,s.RunId) or s.Count>=s.Capacity then Run.Reset(p,true);s=Run.GetSnapshot(p)end
  local id=game.HttpService:GenerateGUID(false);Run.ExpectDrop(p,id)
  assert(Run.TryAddOreDrop(p,s.RunId,id,value))
  last={Id=id,OwnerUserId=p.UserId,WorldId=1,RunId=s.RunId,Outcome="ORE",OreId=value}
  RS.Remotes.EnemyDropGachaResult:FireClient(p,last)
  return state()
 elseif action=="Drop" then local ok,why=Run.DropRequest(p,"Drop",last.RunId,last.Id);return {OK=ok,Reason=why,State=state()}
 elseif action=="Bank" then
  local s=Run.GetSnapshot(p);local token,why=Bank.Begin(p,s.RunId);assert(token,why)
  return state()
 elseif action=="Forge" then
  local s=Forge.State(p);local request={Action=value.Action,Materials=value.Materials,Id=game.HttpService:GenerateGUID(false),Token=s.Token,Generation=s.Generation,Sequence=s.Sequence+1}
  local result=Forge.Request(p,request);assert(result.Success,result.Code)
  local replay=Forge.Request(p,request);assert(replay.Success and replay.Code=="AlreadyApplied")
  return {Result=result,Replay=replay.Code}
 elseif action=="Status" then return state()
 elseif action=="Pose" then
  D.SetCurrentStrength(p,0)
  local r=p.Character.HumanoidRootPart;r.Anchored=true;r.CFrame=CFrame.new(0,12,0)
  return {Head={p.Character.Head.Position.X,p.Character.Head.Position.Y,p.Character.Head.Position.Z}}
 end
end
