-- Read-only canonical Source audit. Pass captured metadata and approved Sources.
return function(before,approved)
 local function hash(s)
  local a,b=5381,2166136261
  for i=1,#s do local v=string.byte(s,i);a=(a*33+v)%4294967296;b=(b*65599+v)%4294967296 end
  return {#s,a,b}
 end
 local backup=game.ServerStorage:FindFirstChild("__W1BalanceBackup")
 local originals={}
 if backup then for _,v in backup:GetChildren()do
  assert(v.Target.Value.Source==v.After.Value,"Isolation target changed: "..v.Target.Value:GetFullName())
  originals[v.Target.Value]=v.Before.Value
 end end
 local report={Total=0,Changed={},Unchanged=0,Helpers={},Unexpected={},Missing={}}
 local found={}
 for _,v in game:GetDescendants()do if v:IsA("LuaSourceContainer")then
  local name=v:GetFullName()
  if name:find("__W1Balance",1,true)then table.insert(report.Helpers,name)
  else
   found[name]=true;report.Total+=1
   local source=originals[v]or v.Source;local previous=before.Sources[name]
   local h=hash(source)
   if not previous then table.insert(report.Unexpected,"new:"..name)
   elseif h[1]==previous[1]and h[2]==previous[2]and h[3]==previous[3]then report.Unchanged+=1
   elseif approved[name]and source==approved[name]then table.insert(report.Changed,name)
   else table.insert(report.Unexpected,"modified:"..name)end
  end
 end end
 for name in before.Sources do if not found[name]then table.insert(report.Missing,name)end end
 report.Orientation=tostring(game.StarterGui.ScreenOrientation)
 report.IsolationPresent=backup~=nil;report.PlaceId=game.PlaceId;report.PlaceVersion=game.PlaceVersion
 assert(#report.Unexpected==0 and #report.Missing==0,game.HttpService:JSONEncode(report))
 return report
end
