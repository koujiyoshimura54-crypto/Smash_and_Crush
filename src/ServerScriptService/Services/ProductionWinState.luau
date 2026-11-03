-- Server-only durable administrative Win directive; no client grant route.
local M={}
function M.Integer(n,positive)
 return type(n)=="number" and n==n and n<math.huge and n%1==0 and n>=(positive and 1 or 0) and n<=9007199254740991
end
function M.AppliedId(data)
 local a=data and data.AdminWin and data.AdminWin.Applied
 return a and a.Id
end
function M.Pending(data)
 local a=data and data.AdminWin;local r=a and a.Request
 return r and r.ResetToken==(data.ResetToken or "") and r.Id~=M.AppliedId(data) and r or nil
end
function M.Apply(data,request,owner)
 assert(M.Integer(request.Value) and request.ActorUserId==7467238848,"InvalidAdminWin")
 local nextData=table.clone(data);local a=table.clone(data.AdminWin)
 nextData.Win=request.Value
 a.Applied={Id=request.Id,Value=request.Value,OwnerToken=owner,Synced=false}
 nextData.AdminWin=a
 return nextData
end
function M.Acquire(data,owner)
 local request=M.Pending(data)
 if request then data=M.Apply(data,request,owner) end
 -- A newly acquired session reads the committed balance, never an old live snapshot.
 if data.AdminWin and data.AdminWin.Applied then
  local a=table.clone(data.AdminWin);a.Applied=table.clone(a.Applied)
  a.Applied.Synced=true;a.Applied.OwnerToken=owner;data.AdminWin=a
 end
 return data
end
return table.freeze(M)
