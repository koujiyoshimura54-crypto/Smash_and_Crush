local C={}
-- Verified share redirect and GroupService:GetGroupInfoAsync.
C.GroupId=787332211 -- Work Game Ltd. E&A
C.WinAmount=3
C.ItemAmount=1
function C.IsValid()
 return typeof(C.GroupId)=="number" and C.GroupId>0 and C.GroupId%1==0
  and typeof(C.WinAmount)=="number" and C.WinAmount>0 and C.WinAmount%1==0
  and typeof(C.ItemAmount)=="number" and C.ItemAmount>0 and C.ItemAmount%1==0 and C.ItemAmount<=100
end
return C