-- In-memory callback/retry simulation of the real acquisition module; no DataStore API.
return function(Ownership)
 local result={Checks={}}
 local function check(name,ok)table.insert(result.Checks,{Name=name,Passed=not not ok});assert(ok,name)end
 local function defaults()return {Win=0,Strength=0,OwnedItems={}}end
 local function validate(old)return {OwnedItems=old and old.OwnedItems or {}}end
 local function scenario(read,old,failAfter,replay)
  local value=old;local attempt={Token='this-session'}
  local s={}
  function s:GetAsync()return read end
  function s:UpdateAsync(_,fn)
   if replay then fn(nil,nil);replay=false end
   value=fn(value,nil)
   if failAfter then failAfter=false;error('Lost commit acknowledgement')end
   return value
  end
  local ok,raw=pcall(Ownership.Acquire,s,'key',attempt,defaults,validate,function()return true end)
  return {OK=ok,Raw=raw,Attempt=attempt,Store=s,Value=function()return value end}
 end
 local fresh=scenario(nil,nil)
 check('Absent read and committed create is New',fresh.OK and fresh.Attempt.ProfileKind=='New')
 local old=defaults();old.SessionOwnerToken='old-session'
 local existing=scenario(old,old)
 check('Existing zero-level-like profile is Existing',existing.OK and existing.Attempt.ProfileKind=='Existing')
 local missing=scenario(defaults(),nil)
 check('Disappearing saved record is Unknown',missing.OK and missing.Attempt.ProfileKind=='Unknown')
 local lost=scenario(nil,nil,true)
 check('Creation acknowledgement loss not a successful load',not lost.OK)
 local ok=pcall(Ownership.Acquire,lost.Store,'key',lost.Attempt,defaults,validate,function()return true end)
 check('Same confirmed creation attempt retry remains New',ok and lost.Attempt.ProfileKind=='New')
 local raw=lost.Value();local rejoin=scenario(raw,raw)
 check('Next acquisition of saved profile is Existing',rejoin.OK and rejoin.Attempt.ProfileKind=='Existing')
 local race=defaults();local replay=scenario(nil,race,false,true)
 check('Repeated callback cannot keep tentative New over existing record',replay.OK and replay.Attempt.ProfileKind=='Existing')
 local reset=defaults();reset.ResetToken='debug-reset';local resetCase=scenario(reset,reset)
 check('Reset default-looking persisted data is Existing',resetCase.OK and resetCase.Attempt.ProfileKind=='Existing')
 result.Passed=true;return result
end
