local T={}
function T.Run()
 local reports={}
 for _,name in ipairs({"Phase741AllTests","Phase742Tests","Phase742UITests"}) do
  local m=game.ServerStorage.Tests[name]:Clone();m.Parent=game.ServerStorage
  local ok,result=pcall(function() return require(m).Run() end);m:Destroy()
  assert(ok,result);table.insert(reports,name.."\n"..result)
 end
 return table.concat(reports,"\n").."\n74 test groups passed"
end
return T