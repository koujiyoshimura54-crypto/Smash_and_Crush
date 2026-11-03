-- Studio issuer -> production directive; only the owning live session applies Win.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Messaging=game:GetService("MessagingService")
local State=require(script.Parent.ProductionWinState)
local Ownership=require(script.Parent.PlayerDataOwnership)
local M={Topic="AdminWinDirective_v1"}
local function meta(info)return info and info:GetUserIds() or {},info and info:GetMetadata() or {} end
local function read(store,key)
 local options=Instance.new("DataStoreGetOptions");options.UseCache=false
 return store:GetAsync(key,options)
end
local function status(raw,id)
 local a=raw and raw.AdminWin
 if a and a.Applied and a.Applied.Id==id then return a.Applied.Synced and "Applied" or "CommittedAwaitingLiveSync" end
 if a and a.Request and a.Request.Id==id then
  return a.Request.ResetToken==(raw.ResetToken or "") and "PendingOnlineSessionOrNextLogin" or "CancelledByReset"
 end
 return "Superseded"
end
function M.Request(issuer,userId,value,store)
 if not RunService:IsStudio() or game.PlaceId~=126576845524886 or game.GameId~=10765181857 then return false,"StudioOnly" end
 if typeof(issuer)~="Instance" or not issuer:IsA("Player") or issuer.Parent~=Players or issuer.UserId~=7467238848 then return false,"DeveloperRequired" end
 if not State.Integer(userId,true) or not State.Integer(value) then return false,"InvalidTargetOrWin" end
 local key="Player_"..tostring(userId)
 local requestId=HttpService:GenerateGUID(false)
 local rejected
 local ok,saved=pcall(function()
  return store:UpdateAsync(key,function(old,info)
   rejected=nil
   if type(old)~="table" or not State.Integer(old.Win) then rejected="TargetDataMissingOrInvalid";return nil end
   local pending=State.Pending(old)
   if pending then
    if pending.Value==value and pending.ActorUserId==issuer.UserId then requestId=pending.Id;local users,metadata=meta(info);return old,users,metadata end
    rejected="AnotherWinChangePending";return nil
   end
   local nextData=table.clone(old);local a=table.clone(old.AdminWin or {})
   a.Request={Id=requestId,Value=value,ActorUserId=issuer.UserId,ResetToken=old.ResetToken or "",CreatedAt=os.time()}
   nextData.AdminWin=a
   local users,metadata=meta(info);return nextData,users,metadata
  end)
 end)
 local prefix=("UserId=%d Win=%.0f Request=%s "):format(userId,value,requestId)
 if not ok then return false,prefix.."UnconfirmedWrite: "..tostring(saved) end
 if rejected or not saved then return false,prefix..(rejected or "UnconfirmedWrite") end
 -- Notification is only a hint. Receivers reread the protected key; polling/load recovers missed messages.
 pcall(function()Messaging:PublishAsync(M.Topic,{UserId=userId})end)
 local last=saved
 for _=1,3 do
  if status(last,requestId)=="Applied" then break end
  task.wait(.5)
  local readOK,current=pcall(read,store,key)
  if not readOK then return false,prefix.."StatusReadFailed" end
  last=current
 end
 local result=status(last,requestId)
 return result=="Applied",prefix..result
end
function M.Sync(player,session,store,current)
 if not session or not session.Loaded or not session.Data or session.OwnershipLost then return false,"DataNotLoaded" end
 local op=session.PendingAdminWin
 if op and op.Resolving or not op and (session.Saving or session.PendingItemMutation or session.PendingFirstStage1Defeat) then return false,"DataBusy" end
 if not op then
  local ok,raw=pcall(read,store,"Player_"..tostring(player.UserId))
  if not ok then return false,"ReadFailed" end
  if not current() then return false,"SessionChanged" end
  local request=State.Pending(raw)
  if not request then return true,"NoPendingWin" end
  if request.ResetToken~=(session.Data.ResetToken or "") then return false,"ResetChanged" end
  -- The read yielded; do not overlap a purchase/save that started meanwhile.
  if session.Saving or session.PendingItemMutation or session.PendingFirstStage1Defeat then return false,"DataBusy" end
  op={Id=request.Id,Before=session.Data.Win,ResetToken=session.Data.ResetToken,Data=session.Data}
  session.PendingAdminWin=op
 end
 if session.Data~=op.Data then session.PendingAdminWin=nil;return false,"SessionChanged" end
 op.Resolving=true;session.Saving=true
 local rejected
 local ok,saved=pcall(function()
  return Ownership.Update(store,"Player_"..tostring(player.UserId),session,function(old,info)
   rejected=nil
   if (old.ResetToken or "")~=(op.ResetToken or "") then rejected="CancelledByReset";return nil end
   if State.AppliedId(old)==op.Id then local users,metadata=meta(info);return old,users,metadata end
   local request=State.Pending(old)
   if not request or request.Id~=op.Id then rejected="RequestChanged";return nil end
   local result=State.Apply(old,request,session.OwnerToken)
   local users,metadata=meta(info);return result,users,metadata
  end,current)
 end)
 if not ok or not saved then
  op.Resolving=false
  if rejected or session.OwnershipLost or not current() then session.PendingAdminWin=nil;session.Saving=false end
  -- An uncertain commit retains the barrier until a read/write retry recovers it.
  return false,rejected or "CommitUnconfirmed"
 end
 if not current() or session.Data~=op.Data then op.Resolving=false;return false,"SessionChanged" end
 if not op.LiveApplied then
  session.Data.Win=math.max(0,saved.AdminWin.Applied.Value+(session.Data.Win-op.Before))
  session.AdminWinAppliedId=op.Id
  player:SetAttribute("Win",session.Data.Win);session.Dirty=true;op.LiveApplied=true
 end
 local ackOK,ack=pcall(function()
  return Ownership.Update(store,"Player_"..tostring(player.UserId),session,function(old,info)
   if State.AppliedId(old)~=op.Id then return nil end
   local result=table.clone(old);local a=table.clone(old.AdminWin);a.Applied=table.clone(a.Applied)
   a.Applied.Synced=true;result.AdminWin=a
   local users,metadata=meta(info);return result,users,metadata
  end,current)
 end)
 op.Resolving=false
 if not ackOK or not ack then return false,"LiveAppliedAckPending" end
 session.PendingAdminWin=nil;session.Saving=false
 return true,"Applied"
end
return M
