-- Studio Edit only: require(game.ServerStorage.Tests.Phase741AllTests).Run()
-- Each suite runs from a fresh clone to avoid cached ModuleScript versions.
-- All purchase/quantity mutations stay in isolated in-memory test stores.
local T={}
function T.Run()
 local output={}
 local count=0
 for _,name in ipairs({"Phase741Tests","Phase741MovementTests","Phase741ShopTests"}) do
  local copy=game.ServerStorage.Tests[name]:Clone()
  copy.Name=name.."_Run"
  copy.Parent=game.ServerStorage
  local ok,result=pcall(function() return require(copy).Run() end)
  copy:Destroy()
  if not ok then error(name..": "..tostring(result)) end
  for line in result:gmatch("[^\n]+") do if line:sub(1,5)=="PASS " then count+=1 end end
  table.insert(output,name.."\n"..result)
 end
 local registration={}
 for _,s in ipairs(game:GetDescendants()) do
  if s:IsA("LuaSourceContainer") and not s:IsDescendantOf(game.ServerStorage)
   and s.Source:find("ProcessReceipt%s*=") then table.insert(registration,s:GetFullName()) end
 end
 assert(#registration==1 and registration[1]=="ServerScriptService.Systems.Controllers.StageSkipController","Unexpected receipt registration")
 table.insert(output,"PASS single ProcessReceipt registration: "..registration[1])
 table.insert(output,tostring(count).." test groups passed")
 return table.concat(output,"\n")
end
return T
