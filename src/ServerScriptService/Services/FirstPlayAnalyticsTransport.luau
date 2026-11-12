-- Non-blocking, bounded, ordered delivery. No retries or game-state mutations.
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Config=require(script.Parent.Parent.Config.FirstPlayAnalyticsConfig)
local API=game:GetService("AnalyticsService")
local M={}
local records={}
local failNext=0
local budget=120
local updated=os.clock()
local active=0
local function send(p,e)
 if Run:IsStudio() then
  if failNext>0 then failNext-=1;error("Isolated analytics failure") end
  if #records>=Config.StudioRecordLimit then table.remove(records,1) end
  table.insert(records,{UserId=p.UserId,Kind=e.Kind,Name=e.Name,Session=e.Session,Step=e.Step,
   StepName=e.StepName,Value=e.Value,Fields=table.clone(e.Fields)})
 elseif e.Kind=="Funnel" then
  API:LogFunnelStepEvent(p,e.Name,e.Session,e.Step,e.StepName,e.Fields)
 else API:LogCustomEvent(p,e.Name,e.Value,e.Fields) end
end
function M.Enqueue(p,s,e)
 if not Config.Enabled then return end
 if e.Kind=="Funnel" and s.SendBroken[e.Name] then return end
 if #s.Queue>=Config.QueuePerSession then
  if e.Kind=="Funnel" then s.SendBroken[e.Name]=true end
  s.Dropped+=1;return
 end
 e.Expires=os.clock()+30
 table.insert(s.Queue,e)
 if s.Draining then return end
 s.Draining=true
 task.defer(function()
  active+=1
  while #s.Queue>0 do
   local row=table.remove(s.Queue,1)
   if not (row.Kind=="Funnel" and s.SendBroken[row.Name]) then
    local now=os.clock();local rate=120+20*#Players:GetPlayers()
    budget=math.min(rate,budget+(now-updated)*rate/60);updated=now
    -- Queue expiry bounds waiting; this is pacing before a single send, not a retry.
    while budget<1 and not Run:IsStudio() and os.clock()<row.Expires do
     task.wait(math.min(1,60/rate))
     now=os.clock();rate=120+20*#Players:GetPlayers()
     budget=math.min(rate,budget+(now-updated)*rate/60);updated=now
    end
    if Run:IsStudio() then budget=math.max(1,budget) end
    if budget<1 then
     s.Dropped+=1
     if row.Kind=="Funnel" then s.SendBroken[row.Name]=true end
    else
     budget-=1
     local ok=pcall(send,p,row)
     if not ok then
      s.Failed+=1
      if row.Kind=="Funnel" then s.SendBroken[row.Name]=true end
     end
    end
   end
  end
  s.Draining=false;active-=1
 end)
end
function M.StudioRecords()
 if not Run:IsStudio() then return nil end
 local out={} for i,v in records do out[i]=table.clone(v);out[i].Fields=table.clone(v.Fields) end return out
end
function M.StudioFailNext(n)
 if Run:IsStudio() then failNext=math.clamp(math.floor(tonumber(n) or 0),0,64) end
end
function M.StudioClear()
 if Run:IsStudio() then table.clear(records);failNext=0;budget=10000;updated=os.clock() end
end
return M
