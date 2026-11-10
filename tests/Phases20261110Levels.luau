local R=require(game.ReplicatedStorage.Config.LevelRequirements)
local P=require(game.ReplicatedStorage.Modules.LevelProgression)
local report={Checks=0,Values={}}
local function check(v,label)assert(v,label);report.Checks+=1 end
for level,value in {[50]=200010,[51]=240020,[52]=288200,[53]=346250,[60]=1271460,[70]=8564370,[80]=61112700,[90]=461819340,[100]=3694673210}do
 check(R.GetRequiredStrength(level)==value,'Q '..level);report.Values[tostring(level)]=value
end
local previous=0
for level=1,R.MaxLevel do local n=R.GetRequiredStrength(level);check(n==n and n>previous and n<math.huge,'Finite increasing Q '..level);previous=n end
check(R.MaxLevel==10000 and R.Post200StrengthPerLevel==250000000,'Unchanged cap and post200 coefficient')
for _,level in {200,201,9999,10000}do report.Values[tostring(level)]=R.GetRequiredStrength(level)end
check(R.GetRequiredStrength(201)==R.GetRequiredStrength(200)+250000000,'Linear join201')
local raw={Strength=1000000,Level=51,LevelProgress=300000,LevelProgressVersion=1}
local level,progress=P.Normalize(raw);check(level==51 and progress==300000,'Saved explicit level/progress retained on load')
local strength,l,q=P.ApplyGain(raw,0);check(strength==1000000 and l==51 and q==300000,'Zero gain never reallocates old Strength')
strength,l,q=P.ApplyGain(raw,1);check(strength==1000001 and l==52 and q==59981,'Only next positive gain consumes existing excess progress')
local total=0;for i=1,60 do total+=R.GetRequiredStrength(i)end
strength,l,q=P.ApplyGain({Strength=0,Level=1,LevelProgress=0},total);check(strength==total and l==61 and q==0,'Multiple levels consume incremental costs')
strength,l,q=P.ApplyGain({Strength=0,Level=200,LevelProgress=0},R.GetRequiredStrength(200));check(l==201 and q==0,'200 to201 boundary')
strength,l,q=P.ApplyGain({Strength=0,Level=9999,LevelProgress=0},R.GetRequiredStrength(9999));check(l==10000 and q==0,'Max boundary')
strength,l,q=P.ApplyGain({Strength=0,Level=1,LevelProgress=0},1e30);check(l==10000 and q<math.huge and strength==1e30,'Huge finite gain terminates')
check(P.ApplyGain({Strength=0,Level=1,LevelProgress=0},math.huge)==nil,'Infinity rejected')
check(P.ApplyGain({Strength=0,Level=1,LevelProgress=0},0/0)==nil,'NaN rejected')
report.Passed=true;return report
