-- Pure Luau verification of captured strings. No live require, instances, remotes or data.
return function(studioSource,mergedSource,baselineSource,progressionSource)
 local checks,groups=0,{}
 local function check(ok,label,group) checks+=1 groups[group]=(groups[group] or 0)+1 assert(ok,label) end
 local function loadPure(source,requirements)
  local token={}
  local env={math=math,table=table,tonumber=tonumber,typeof=typeof,pairs=pairs,ipairs=ipairs,assert=assert}
  if requirements then
   env.game={ReplicatedStorage={Config={LevelRequirements=token}}}
   env.require=function(value) assert(value==token,"Unexpected dependency") return requirements end
  end
  local fn,err=loadstring(source) assert(fn,err) setfenv(fn,env) return fn()
 end
 local studio=loadPure(studioSource)
 local merged=loadPure(mergedSource)
 local old=loadPure(baselineSource)
 local progression=loadPure(progressionSource,merged)
 local oldProgression=loadPure(progressionSource,old)
 local rows={}
 for curve=1,2 do
  for level=1,merged.MaxLevel do
   local q=merged.GetRequiredStrength(level,curve)
   check(type(q)=="number" and q==q and q>0 and q<math.huge,"Invalid requirement "..level,"FinitePositive")
   check(q==studio.GetRequiredStrength(level,curve),"Studio mismatch "..level,"StudioMergedEquality")
   if level<=50 then check(q==old.GetRequiredStrength(level,curve),"Early curve changed","EarlyPreserved") end
   if level>=201 then check(q==math.ceil(merged.GetRequiredStrength(level-1,curve)*1.05/10)*10,"Post200 recurrence","Post200") end
   if level<=201 then table.insert(rows,{Level=level,CurveVersion=curve,StudioRequiredStrength=studio.GetRequiredStrength(level,curve),PreIntegrationGitHubRequiredStrength=old.GetRequiredStrength(level,curve)}) end
   if level<=200 then
    local a,b=progression.Advance(level,q-1,0,curve) check(a==level and b==q-1,"Below boundary","Boundaries")
    a,b=progression.Advance(level,q,0,curve) check(a==level+1 and b==0,"Exact boundary","Boundaries")
    a,b=progression.Advance(level,q+1,0,curve) check(a==level+1 and b==1,"Above boundary","Boundaries")
   end
  end
  local raw={Level=136,Strength=123456.5,LevelProgress=merged.GetRequiredStrength(136,curve)+merged.GetRequiredStrength(137,curve)+17,LevelCurveVersion=curve,LevelProgressVersion=1}
  local copy=table.clone(raw)
  local l,p,c=progression.Normalize(raw)
  check(l==138 and p==17 and c==curve,"Two-level carry","SavedProgress")
  for k,v in pairs(copy) do check(raw[k]==v,"Raw state mutated: "..k,"SavedProgress") end
  for _,strength in ipairs({0,1,123456.5,1e18}) do
   local state={Level=136,Strength=strength,LevelProgress=123.5,LevelCurveVersion=curve,LevelProgressVersion=1}
   local l2,p2=progression.Normalize(state)
   check(l2==136 and p2==123.5 and state.Strength==strength,"Saved Level/Strength/progress changed","SavedProgress")
  end
  local state={Level=136,Strength=123456.5,LevelProgress=merged.GetRequiredStrength(136,curve)-1,LevelCurveVersion=curve}
  local strength,level,progress=progression.ApplyGain(state,18)
  check(strength==123474.5 and level==137 and progress==17,"ApplyGain carry/Strength","SavedProgress")
  check(state.Strength==123456.5 and state.Level==136,"ApplyGain mutated input","SavedProgress")
  local l3,p3=progression.Advance(merged.MaxLevel,17,0,curve)
  check(l3==merged.MaxLevel and p3==17,"Max level progress lost","SavedProgress")
 end
 local historical={} for l=1,50 do historical[l]=old.LegacyStrength[l] end
 for l=51,200 do historical[l]=math.ceil(historical[l-1]*(1+0.20+(l-51)*0.0007)/10)*10 end
 local early={10,30,50,70,90,125,155}
 for l=1,old.MaxLevel do
  local q=early[l] or historical[l] or historical[200]+(l-200)*old.Post200StrengthPerLevel
  for _,v in ipairs({q-1,q,q+1}) do
   check(merged.CalculateLevel(v)==old.CalculateLevel(v),"Historical restoration changed","LegacyMigration")
  end
 end
 for _,v in ipairs({0,1,10,123456,1e12,1e20,1e100,math.huge}) do
  local raw={Strength=v}
  local a,b,c=progression.Normalize(raw) local x,y,z=oldProgression.Normalize(raw)
  check(a==x and b==y and c==z and raw.Strength==v,"Legacy Normalize changed","LegacyMigration")
 end
 local invalid={
  {Level=0},{Level=1.5},{Level=10001},{Level=0/0},{Level=math.huge},
  {Level=136,LevelProgress=-1},{Level=136,LevelProgress=0/0},{Level=136,LevelProgress=math.huge},
  {Level=136,LevelCurveVersion=99},{Level=136,LevelProgressVersion=99},
  {Level=136,LevelProgressVersion=1}
 }
 for _,raw in ipairs(invalid) do local l,reason=progression.Normalize(raw) check(l==nil and type(reason)=="string","Invalid saved state accepted","InvalidInput") end
 for _,gain in ipairs({-1,0/0,math.huge}) do local l,reason=progression.Advance(136,0,gain,1) check(l==nil and type(reason)=="string","Invalid gain accepted","InvalidInput") end
 check(merged.GetRequiredStrength(0/0,1)==merged.GetRequiredStrength(1,1),"NaN level not clamped","InvalidInput")
 return {Mode="Independent pure calculations inside existing Studio Edit; no live ModuleScript require or Player data",Assertions=checks,Groups=groups,Rows=rows,MaxLevel=merged.MaxLevel,MaxRequirement=merged.GetRequiredStrength(merged.MaxLevel,2),MultipleLevelExample={StartLevel=136,EndLevel=138,RemainingProgress=17,StrengthUnchanged=123456.5},PlayExecuted=false}
end
