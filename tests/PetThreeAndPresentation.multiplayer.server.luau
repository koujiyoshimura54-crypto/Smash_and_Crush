-- Append to the corresponding native fixture for an isolated two-client run.

local multi=Instance.new("RemoteFunction");multi.Name="__P3QAMulti";multi.Parent=RS
local started=false;local done={};local states={};local barrier={}
task.spawn(function()
 repeat task.wait(.2)until #game.Players:GetPlayers()==2
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 for i,p in ipairs(players)do
  local ids=seed(p,i==1 and {"Dog","Elephant","Crocodile"} or {"Dog","Dog","Slime"})
  for _,key in ipairs(ids)do assert(equip(p,key))end
  states[p.UserId]=D.GetPetState(p)
 end
 started=true
end)
multi.OnServerInvoke=function(p,action,value)
 if action=="Ready"then repeat task.wait(.2)until started;return states
 elseif action=="RespawnReady"then barrier[p.UserId]=true;repeat task.wait(.1);local n=0;for _ in pairs(barrier)do n+=1 end until n==2;return true
 elseif action=="Reset"then assert(D.Reset(p));return D.GetPetState(p)
 elseif action=="Report"then
  done[p.UserId]=value
  if #game.Players:GetPlayers()==2 then
   local count=0;for _ in pairs(done)do count+=1 end
   if count==2 then task.defer(function()game:GetService("StudioTestService"):EndTest(H:JSONEncode({Reports=done,States=states}))end)end
  end
  return true
 end
end
task.delay(110,function()game:GetService("StudioTestService"):EndTest(H:JSONEncode({Timeout=true,Reports=done}))end)
