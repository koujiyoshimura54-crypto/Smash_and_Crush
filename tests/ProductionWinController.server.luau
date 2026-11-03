local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local Prod=require(S.__WBQAProdData)
local Debug=require(game.ServerScriptService.Systems.Debug.StudioDebugService)
local Mem=require(game.ReplicatedStorage.__WBQAMemory)
local p=game.Players:GetPlayers()[1]
local result={}
local signals={}
Mem.MessagingService.SubscribeAsync=function(_,topic,fn) signals[topic]=fn;return {Disconnect=function()signals[topic]=nil end} end
Mem.MessagingService.PublishAsync=function(_,topic,data) if signals[topic] then signals[topic]({Data=data}) end end
local f=Instance.new("BindableFunction");f.Name="__WBQAExtra";f.Parent=game.ServerStorage
f.OnInvoke=function(action)
 if action=="run" then
  D.SetWin(p,23)
  local ok,text=Debug.Execute(p,"/setwin 1000");assert(ok and D.Get(p).Data.Win==1000)
  assert(Debug.Execute(p,"/setwin 0"));assert(D.Get(p).Data.Win==0)
  result.OmittedId="Own Studio 23 -> 1000 -> 0"
  local issuerBefore=D.Get(p).Data.Win
  local accepted,info=Debug.Execute(p,"/setwin 1234 10591394123")
  assert(not accepted and info:find("PendingOnlineSessionOrNextLogin",1,true),info)
  assert(D.Get(p).Data.Win==issuerBefore and p:GetAttribute("Win")==issuerBefore)
  result.IssuerUnchanged=issuerBefore;result.OfflineStatus=info
  -- Actual new public-controller callback with isolated production data adapter.
  local live,message=Debug.Execute(p,"/setwin 2345 "..p.UserId)
  assert(live,message);assert(Prod.Get(p).Data.Win==2345 and p:GetAttribute("Win")==2345)
  result.ControllerStatus=message
  Prod.Get(p).Dirty=true;assert(Prod.Save(p))
  Prod.Release(p);assert(Prod.Load(p));assert(Prod.Get(p).Data.Win==2345)
  result.OnlineReloadWin=Prod.Get(p).Data.Win
  return result
 elseif action=="status" then return result end
end
