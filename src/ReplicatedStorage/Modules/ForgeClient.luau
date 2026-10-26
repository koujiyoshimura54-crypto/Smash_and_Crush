-- Shared client state for the existing Merge and Dumbbell inventory panels.
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local player=game:GetService("Players").LocalPlayer
local M={State=nil}
local changed=Instance.new("BindableEvent");M.Changed=changed.Event
local completed=Instance.new("BindableEvent");M.Completed=completed.Event
local pending,fetching,invoking
local function accept(response)
 if typeof(response)~="table" or typeof(response.State)~="table" then return end
 M.State=response.State
 if pending and (pending.Token~=M.State.Token or pending.Generation~=M.State.Generation) then
  local op=pending;pending=nil
  completed:Fire(op,{Success=false,Code="InventoryChanged",State=M.State})
 end
 if pending and M.State.Journal and M.State.Journal.Id==pending.Id then
  local op=pending;pending=nil
  completed:Fire(op,{Success=true,Code="Applied",State=M.State})
 end
 changed:Fire(M.State)
end
function M.IsPending() return pending~=nil end
function M.Refresh()
 if fetching then return M.State end
 fetching=true
 local ok,response=pcall(function() return RS.Remotes:WaitForChild("ForgeRequest"):InvokeServer({Action="GetState"}) end)
 fetching=false
 if ok then accept(response) end
 return M.State
end
local function send()
 if not pending or invoking then return end
 invoking=true;local op=pending
 local ok,response=pcall(function() return RS.Remotes.ForgeRequest:InvokeServer(op) end)
 invoking=false
 if ok then
  accept(response)
  if pending==op and typeof(response)=="table" and response.Code~="InventorySavePending" and response.Code~="RateLimited" and response.Code~="DataSaving" then
   pending=nil;completed:Fire(op,response);changed:Fire(M.State)
  end
 end
end
function M.Request(action,fields)
 if pending then return false,"InventorySavePending" end
 local state=M.State or M.Refresh()
 if not state or not state.Loaded then return false,"DataNotLoaded" end
 local op=table.clone(fields or {})
 op.Action=action;op.Id=Http:GenerateGUID(false);op.Sequence=state.Sequence+1;op.Token=state.Token;op.Generation=state.Generation
 pending=op;changed:Fire(state)
 task.spawn(function()
  local attempt=0
  while pending==op and player.Parent do
   attempt+=1
   send()
   if pending~=op then return end
   task.wait(math.min(8,attempt))
   if attempt%8==0 then M.Refresh() end
  end
  -- Retries keep one identity and back off to eight seconds. A temporary network
  -- outage cannot leave the UI permanently pending after an arbitrary retry cap.
 end)
 return true
end
player:GetAttributeChangedSignal("ForgeInventoryRevision"):Connect(function() task.defer(M.Refresh) end)
player:GetAttributeChangedSignal("ForgeSavePending"):Connect(function() task.defer(M.Refresh) end)
player:GetAttributeChangedSignal("PetViewGeneration"):Connect(function() task.defer(M.Refresh) end)
return M
