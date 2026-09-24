local R={Records={},Ordered={},Tasks={}}
function R.Signal()
 local signal={Listeners={}}
 function signal:Connect(fn)
  local connection={Connected=true}
  function connection:Disconnect() self.Connected=false end
  table.insert(self.Listeners,{Connection=connection,Fn=fn})
  return connection
 end
 function signal:Fire(...)
  for _,entry in ipairs(self.Listeners) do
   if entry.Connection.Connected then entry.Fn(...) end
  end
 end
 return signal
end
R.Players={List={},PlayerAdded=R.Signal(),PlayerRemoving=R.Signal()}
function R.Players:GetPlayers() return self.List end
R.Workspace={ChildAdded=R.Signal()}
function R.Workspace:FindFirstChild() return nil end
R.RunService={Heartbeat=R.Signal()}
R.Task={}
function R.Task.wait(interval) return coroutine.yield(interval) end
function R.Task.spawn(fn)
 local co=coroutine.create(fn)
 local success,message=coroutine.resume(co)
 assert(success,message)
 table.insert(R.Tasks,co)
 return co
end
function R.Tick(dt)
 R.RunService.Heartbeat:Fire(dt)
 for _,co in ipairs(table.clone(R.Tasks)) do
  if coroutine.status(co)=="suspended" then
   local success,message=coroutine.resume(co)
   assert(success,message)
  end
 end
end
R.RebirthRemote={OnServerEvent=R.Signal(),Replies={}}
function R.RebirthRemote:FireClient(p,reply) self.Replies[p]=reply end
local H=game:GetService("HttpService")
local function copy(v)
 if v==nil then return nil end
 return H:JSONDecode(H:JSONEncode(v))
end
R.DSS={}
function R.DSS:GetDataStore(name)
 assert(name=="PlayerData_v1")
 return {
  GetAsync=function(_,key)
   if R.FailLoad then error("simulated load failure") end
   return copy(R.Records[key])
  end,
  UpdateAsync=function(_,key,callback)
   if R.BeforeUpdate then R.BeforeUpdate() end
   if R.FailSave then error("simulated save failure") end
   callback(copy(R.Records[key])) -- emulate a retried callback
   R.Records[key]=copy(callback(copy(R.Records[key])))
   return copy(R.Records[key])
  end,
 }
end
function R.DSS:GetOrderedDataStore(name)
 return {SetAsync=function(_,key,value)
  R.Ordered[name]=R.Ordered[name] or {}
  R.Ordered[name][key]=value
 end}
end
return R
