-- Run manually on the Play server. DataStore and Marketplace are isolated fakes.
local T={}
function T.Run()
assert(not game.ServerStorage:FindFirstChild("SpeedVerification"),"Speed test already running")
local folder=Instance.new("Folder");folder.Name="SpeedVerification";folder.Parent=game.ServerStorage
local function module(name,source) local m=Instance.new("ModuleScript");m.Name=name;m.Source=source;m.Parent=folder;return m end
local function replace(s,a,b) local x,y=s:find(a,1,true);assert(x,a);return s:sub(1,x-1)..b..s:sub(y+1) end
local results={}
local function test(name,fn) local ok,err=pcall(fn);results[#results+1]={Name=name,Pass=ok,Error=not ok and tostring(err) or nil} end
local ok,err=pcall(function()
local http=game.HttpService
local function copy(v) if v==nil then return nil end return http:JSONDecode(http:JSONEncode(v)) end
local records={};local fail=false;local writes=0;local replay=false
local store={}
function store:GetAsync(k) return copy(records[k]) end
function store:UpdateAsync(k,fn)
 if fail then error("Injected store failure") end
 local v=fn(copy(records[k]))
 if replay then v=fn(copy(records[k])) end
 if v~=nil then records[k]=copy(v);writes+=1 end
 return copy(v)
end
local dss={GetDataStore=function() return store end,GetOrderedDataStore=function() return {SetAsync=function() end} end}
local ds=replace(game.ServerScriptService.Services.PlayerDataService.Source,'local DSS=game:GetService("DataStoreService")','local DSS=TestDSS')
local factory=require(module("DataFactory","return function(TestDSS) "..ds.." end"))
local data=factory(dss)
local function signal()
 local handlers={}
 return {Connect=function(_,fn) handlers[#handlers+1]=fn;return {Disconnect=function() end} end,Fire=function(_,...) for _,fn in handlers do fn(...) end end}
end
local players={PlayerRemoving=signal()}
local ownership=false;local ownershipFails=false;local prompts=0
local marketplace={PromptGamePassPurchaseFinished=signal()}
function marketplace:UserOwnsGamePassAsync(_,id)
 assert(id==require(game.ReplicatedStorage.Config.SpeedConfig).Premium.GamePassId)
 if ownershipFails then error("Injected ownership failure") end
 return ownership
end
function marketplace:PromptGamePassPurchase(_,id) assert(id==require(game.ReplicatedStorage.Config.SpeedConfig).Premium.GamePassId);prompts+=1 end
local ps=game.ServerScriptService.Services.GamePassService.Source
-- Existing ownership tests always exercise real-entitlement mode, independently of Studio UI debugging.
ps=replace(ps,'require(script.Parent:WaitForChild("StudioDebugConfig"))','{ForceSpeedPremiumUnowned=false}')
ps=replace(ps,'local Players=game:GetService("Players")','local Players=TestPlayers')
ps=replace(ps,'local MarketplaceService=game:GetService("MarketplaceService")','local MarketplaceService=TestMarketplace')
local passFactory=require(module("PassFactory","return function(TestPlayers,TestMarketplace) "..ps.." end"))
local pass=passFactory(players,marketplace)
local shim='local origTypeof=typeof;local function typeof(v) if type(v)=="table" and v.TestPlayer then return "Instance" end return origTypeof(v) end\n'
local ss=game.ServerScriptService.Services.SpeedService.Source
ss=replace(ss,'local Players=game:GetService("Players")','local Players=Deps.Players')
ss=replace(ss,'require(script.Parent:WaitForChild("PlayerDataService"))','Deps.Data')
ss=replace(ss,'require(script.Parent:WaitForChild("GamePassService"))','Deps.Pass')
local speedFactory=require(module("SpeedFactory","return function(Deps) "..shim..ss.." end"))
local speed=speedFactory({Players=players,Data=data,Pass=pass})
local function character()
 local h={WalkSpeed=24}
 return {Humanoid=h,FindFirstChildOfClass=function() return h end}
end
local p={TestPlayer=true,UserId=987654321,Name="SpeedTest",Parent=players,Attributes={},Character=character()}
function p:GetAttribute(k) return self.Attributes[k] end
function p:SetAttribute(k,v) self.Attributes[k]=v end
function p:IsA(c) return c=="Player" end
test("Legacy data defaults to unowned / 24",function() assert(data.Load(p));assert(next(data.Get(p).Data.OwnedSpeeds)==nil);assert(speed.Apply(p).WalkSpeed==24) end)
test("Invalid request and insufficient Win do not mutate",function()
 assert(data.SetWin(p,499));assert(not speed.Purchase(p,{}));assert(not speed.Purchase(p,"Premium"));assert(not speed.Purchase(p,"Speed1"));assert(p:GetAttribute("Win")==499 and p.Character.Humanoid.WalkSpeed==24 and writes==0)
end)
test("Save failure retains 500 Win, unowned, 24",function()
 assert(data.SetWin(p,500));fail=true
 local success,code=speed.Purchase(p,"Speed1");fail=false
 assert(not success and code=="SaveFailed")
 assert(p:GetAttribute("Win")==500 and not data.Get(p).Data.OwnedSpeeds.Speed1 and p.Character.Humanoid.WalkSpeed==24)
end)
test("Purchase persists one 500 debit / 32, UpdateAsync callback replay safe",function()
 replay=true;assert(speed.Purchase(p,"Speed1"));replay=false
 assert(p:GetAttribute("Win")==0 and p.Character.Humanoid.WalkSpeed==32 and records.Player_987654321.OwnedSpeeds.Speed1 and records.Player_987654321.Win==0)
end)
test("Duplicate purchase cannot debit again",function()
 assert(data.SetWin(p,800));local w=writes;assert(not speed.Purchase(p,"Speed1"));assert(p:GetAttribute("Win")==800 and writes==w)
end)
test("Respawn restores 32",function() p.Character=character();speed.Apply(p);assert(p.Character.Humanoid.WalkSpeed==32) end)
test("Save / release / fresh service rejoin restores ownership and 32",function()
 assert(data.Save(p));data.Release(p);data=factory(dss);assert(data.Load(p))
 speed=speedFactory({Players=players,Data=data,Pass=pass});speed.Apply(p)
 assert(p:GetAttribute("Win")==800 and p.Character.Humanoid.WalkSpeed==32)
end)
test("Rebirth reset operations retain ownership / 32",function()
 data.SetRebirthCount(p,1);data.SetCurrentStrength(p,0);p:SetAttribute("Strength",0);p:SetAttribute("Level",1)
 speed.Apply(p);assert(data.Get(p).Data.OwnedSpeeds.Speed1 and p.Character.Humanoid.WalkSpeed==32)
end)
test("Premium unowned + Speed1 remains 32; prompt uses configured ID",function()
 ownership=false;assert(not pass.RefreshPremiumSpeed(p));assert(pass.PromptPremiumSpeed(p));assert(prompts==1);assert(speed.Apply(p).WalkSpeed==32)
end)
test("Purchase completion verifies ownership, Premium + Speed1 = 40",function()
 ownership=true;marketplace.PromptGamePassPurchaseFinished:Fire(p,require(game.ReplicatedStorage.Config.SpeedConfig).Premium.GamePassId,true)
 task.wait()
 assert(pass.HasPremiumSpeed(p));assert(speed.Apply(p).WalkSpeed==40)
end)
test("Premium only = 40, additive speed never used",function()
 local q={TestPlayer=true,UserId=987654322,Name="PremiumOnly",Parent=players,Attributes={},Character=character(),GetAttribute=p.GetAttribute,SetAttribute=p.SetAttribute,IsA=p.IsA}
 assert(data.Load(q));assert(pass.RefreshPremiumSpeed(q));assert(not data.Get(q).Data.OwnedSpeeds.Speed1);assert(speed.Apply(q).WalkSpeed==40)
end)
test("Ownership lookup failure retains already verified Premium",function()
 ownershipFails=true;local owned,status=pass.RefreshPremiumSpeed(p);ownershipFails=false
 assert(owned and status=="OwnershipUnavailable");assert(speed.Apply(p).WalkSpeed==40)
end)
test("Default normalizes missing field; malformed ownership rejects load",function()
 records.Player_987654323={OwnedSpeeds="bad"}
 local q={UserId=987654323,Attributes={},SetAttribute=p.SetAttribute}
 assert(not data.Load(q))
end)

test("Actual walking loop gives identical ticks at 24 / 32 / 40",function()
 local source=game.ServerScriptService.Systems.Controllers.TrainingController.Source
 local a=assert(source:find("local WalkStepInterval=",1,true))
 local z=assert(source:find("local function initialize()",a,true))
 local part=source:sub(a,z-1)
 local make=require(module("WalkingFactory","return function(Players,TrainingManager,StrengthManager) "..part.." return updateWalkingSteps end"))
 for _,v in {24,32,40} do
  local total=0
  local hum={Health=100,MoveDirection=Vector3.new(1,0,0),GetState=function() return Enum.HumanoidStateType.Running end}
  local root={AssemblyLinearVelocity=Vector3.new(v,0,0)}
  local q={Character={FindFirstChildOfClass=function() return hum end,FindFirstChild=function() return root end},GetAttribute=function() return false end}
  local step=make({GetPlayers=function() return {q} end},{GetOccupiedTreadmill=function() return nil end},{AddStrength=function(_,amount,ticks) assert(amount==ticks);total+=ticks end})
  for _=1,20 do step(.1) end
  assert(total==4,"Speed "..v.." ticks "..total)
 end
end)
test("Actual Rebirth request keeps Speed1 and 32",function()
 ownership=false;pass.RefreshPremiumSpeed(p);data.SetRebirthCount(p,0);speed.Apply(p)
 players.PlayerAdded=signal();function players:GetPlayers() return {p} end
 local request={OnServerEvent=signal(),FireClient=function() end}
 local strength={GetRebirthCount=function(q) return q:GetAttribute("RebirthCount") end,GetStrength=function() return 100000000 end,CalculateLevel=function() return 1000 end,ResetGainRemainder=function(q) q.Remainder=0 end,SetStrength=function(q,v) q:SetAttribute("Strength",v);q:SetAttribute("Level",1);data.SetCurrentStrength(q,v) end}
 local source=game.ServerScriptService.Systems.Controllers.RebirthService.Source
 source=replace(source,'local Players=game:GetService("Players")','local Players=Deps.Players')
 source=replace(source,'require(script.Parent:WaitForChild("StrengthManager"))','Deps.Strength')
 source=replace(source,'require(script.Parent:WaitForChild("PlayerDataService"))','Deps.Data;')
 source=replace(source,'local request=RS.Remotes:WaitForChild("RebirthRequest")','local request=Deps.Request')
 require(module("RebirthFactory","return function(Deps) "..source.." end"))({Players=players,Strength=strength,Data=data,Request=request})
 request.OnServerEvent:Fire(p,"Request")
 assert(p:GetAttribute("RebirthCount")==1 and p:GetAttribute("Strength")==0 and p:GetAttribute("Level")==1)
 assert(data.Get(p).Data.OwnedSpeeds.Speed1 and p.Character.Humanoid.WalkSpeed==32)
end)

test("Actual SpeedController: initial load, purchase, respawn and Premium change publish immediately",function()
 local signals={}
 function p:GetAttributeChangedSignal(k) signals[k]=signals[k] or signal();return signals[k] end
 function p:SetAttribute(k,v) local old=self.Attributes[k];self.Attributes[k]=v;if old~=v and signals[k] then signals[k]:Fire() end end
 p.CharacterAdded=signal()
 players.PlayerAdded=signal()
 function players:GetPlayers() return {p} end
 p.Character=character();function p.Character:WaitForChild() return self.Humanoid end
 ownership=false;pass.RefreshPremiumSpeed(p)
 data.Get(p).Data.OwnedSpeeds={};records.Player_987654321.OwnedSpeeds={}
 data.SetWin(p,500)
 local remotes={}
 for name,class in pairs({SpeedPurchaseRequest="RemoteEvent",SpeedInventoryState="RemoteFunction",SpeedPremiumPrompt="RemoteEvent"}) do
  local r={ClassName=class,OnServerEvent=signal(),Messages={}}
  function r:FireClient(_,message) table.insert(self.Messages,message) end
  remotes[name]=r
 end
 function remotes:FindFirstChild(name) return self[name] end
 local testTask={}
 function testTask.spawn(fn) local co=coroutine.create(fn);local good,message=coroutine.resume(co);assert(good,message);return co end
 function testTask.wait() coroutine.yield() end
 local cs=game.ServerScriptService.Systems.Controllers.SpeedController.Source
 cs=replace(cs,'local Players=game:GetService("Players")','local Players=Deps.Players')
 cs=replace(cs,'local RS=game:GetService("ReplicatedStorage")','local RS=Deps.Remotes')
 cs=replace(cs,'require(script.Parent:WaitForChild("SpeedService"))','Deps.Speed')
 cs=replace(cs,'require(script.Parent:WaitForChild("PlayerDataService"))','Deps.Data')
 cs=replace(cs,'require(script.Parent:WaitForChild("GamePassService"))','Deps.Pass')
 require(module("ControllerFactory","return function(Deps) local task=Deps.Task; "..cs.." end"))({Players=players,Remotes=remotes,Speed=speed,Data=data,Pass=pass,Task=testTask})
 assert(p.Character.Humanoid.WalkSpeed==24)
 remotes.SpeedPurchaseRequest.OnServerEvent:Fire(p,"Speed1")
 assert(p.Character.Humanoid.WalkSpeed==32 and p:GetAttribute("Win")==0)
 local last=remotes.SpeedPurchaseRequest.Messages[#remotes.SpeedPurchaseRequest.Messages]
 assert(last.Success==true and last.State.OwnedSpeeds.Speed1)
 p.Character=character();function p.Character:WaitForChild() return self.Humanoid end
 p.CharacterAdded:Fire(p.Character);assert(p.Character.Humanoid.WalkSpeed==32)
 ownership=true;marketplace.PromptGamePassPurchaseFinished:Fire(p,require(game.ReplicatedStorage.Config.SpeedConfig).Premium.GamePassId,true);task.wait()
 assert(p.Character.Humanoid.WalkSpeed==40)
 assert(remotes.SpeedPurchaseRequest.Messages[#remotes.SpeedPurchaseRequest.Messages].State.PremiumOwned)
 remotes.SpeedPremiumPrompt.OnServerEvent:Fire(p,"Prompt")
 local reply=remotes.SpeedPremiumPrompt.Messages[#remotes.SpeedPremiumPrompt.Messages]
 assert(reply and reply.Success==false and reply.Code=="RequestInProgress")
 p.Parent=nil
end)

end)
folder:Destroy()
if not ok then results[#results+1]={Name="Harness",Pass=false,Error=tostring(err)} end
return results
end
return T
