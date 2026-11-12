return function(sources)
 local checks=0
 local function eq(a,b,label) checks+=1;assert(a==b,(label or "")..": "..tostring(a).." ~= "..tostring(b))end
 local function near(a,b) checks+=1;assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b))end
 local function module(source,requirements)
  local fn=assert(loadstring(source))
  setfenv(fn,setmetatable({game={ReplicatedStorage={Config={LevelRequirements="Requirements"}}},script={Parent={LevelRequirements="Requirements"}},require=function(k)assert(k=="Requirements");return requirements end},{__index=getfenv()}))
  return fn()
 end
 local Q=module(sources.Requirements);local OldQ=module(sources.OldRequirements)
 local P=module(sources.Progression,Q);local OldP=module(sources.OldProgression,OldQ)
 local R=module(sources.Rebirth,Q);local OldR=module(sources.OldRebirth,OldQ)
 local C=module(sources.Balance);local OldC=module(sources.OldBalance)
 local costs={5,12,23,45,60,90,125,145,170,195,225,260,300,345,400,480,580,700,840,1100,1400,1800,2200,2500,3200,4000,4750,5400,5965}
 local sums={[4]=40,[8]=360,[10]=675,[12]=1095,[15]=2000,[17]=2880,[20]=5000,[24]=11500,[25]=14000,[30]=37315,[50]=1018015}
 for level=1,10000 do
  eq(Q.GetRequiredStrength(level,1),OldQ.GetRequiredStrength(level),"legacy Q"..level)
  if level>=30 then eq(Q.GetRequiredStrength(level,2),OldQ.GetRequiredStrength(level),"retained Q"..level)end
  local value=Q.GetRequiredStrength(level,2);eq(value>0 and value<math.huge,true,"finite Q")
 end
 for i,v in costs do eq(Q.GetRequiredStrength(i,2),v,"new Q"..i)end
 for level,total in sums do eq(Q.GetCumulativeStrength(level,2),total,"cumulative LV"..level)end
 for curve=1,2 do
  -- Fractional probes at every changed/nearby level, where .125 is representable.
  for level=1,50 do
   local cost=Q.GetRequiredStrength(level,curve)
   for _,offset in {-.25,0,.25}do
    local l,p,v=P.Advance(level,0,cost+offset,curve)
    eq(l,offset<0 and level or level+1,"boundary level")
    near(p,offset<0 and cost+offset or offset);eq(v,curve)
    local raw={Strength=777.5,Level=level,LevelProgress=cost+offset,LevelProgressVersion=1,LevelCurveVersion=curve}
    local nl,np,nv=P.Normalize(raw);eq(nl,l);near(np,p);eq(nv,curve);eq(raw.Strength,777.5)
    local total,al,ap=P.ApplyGain({Strength=89.125,Level=level,LevelProgress=.125,LevelCurveVersion=curve},cost+offset)
    near(total,89.125+(cost+offset))
    local el,ep=P.Advance(level,.125,cost+offset,curve);eq(al,el);near(ap,ep)
   end
  end
  -- At high levels use representable offsets; sub-ULP fractions cannot survive
  -- IEEE-754 arithmetic on either pre-existing or new curves.
  for level=1,9999 do
   local cost=Q.GetRequiredStrength(level,curve)
   local delta=math.max(1,2^math.ceil(math.log(cost)/math.log(2)-49))
   for _,offset in {-delta,0,delta}do
    local l,p=P.Advance(level,0,cost+offset,curve)
    eq(l,offset<0 and level or level+1)
    eq(p,offset<0 and cost+offset or offset)
   end
  end
  local l,p=P.Advance(1,0,0,curve);eq(l,1);eq(p,0)
  l,p=P.Advance(1,0,1018015.25,curve);eq(l,50);eq(p,.25)
  local s={Strength=15.75,Level=4,LevelProgress=.125,LevelCurveVersion=curve}
  local n,nl,np=P.ApplyGain(s,0);eq(n,15.75);eq(nl,4);eq(np,.125)
  local loaded,pr,v=P.Normalize(s);eq(loaded,4);eq(pr,.125);eq(v,curve)
 end
 for _,raw in {{Strength=0,Level=1,LevelProgress=0},{Strength=99999,Level=4,LevelProgress=.25},{Strength=600},{Strength=0,Level=1,LevelProgress=70.125}}do
  local l,p,v=P.Normalize(raw);local ol,op=OldP.Normalize(raw);eq(l,ol);eq(p,op);eq(v,1)
 end
 for _,raw in {{LevelCurveVersion=0},{LevelCurveVersion=3},{LevelCurveVersion="2"},{LevelProgressVersion=2},{Level=2.5},{Level=1,LevelProgress=-1}}do eq(P.Normalize(raw),nil,"reject invalid")end
 eq(P.ApplyGain({Strength=0,Level=1,LevelProgress=0,LevelCurveVersion=3},1),nil)
 eq(P.Advance(1,0,math.huge,2),nil);eq(P.Advance(1,0,-1,2),nil)
 for count=0,30 do
  eq(R.GetRequiredLevel(count,1),OldR.GetRequiredLevel(count),"old rebirth")
  eq(R.GetMultiplier(count),OldR.GetMultiplier(count),"multiplier")
  if count>=5 then eq(R.GetRequiredLevel(count,2),OldR.GetRequiredLevel(count),"rebirth 6+")end
  for curve=1,2 do local level=R.GetRequiredLevel(count,curve);if level then eq(R.GetReferenceStrength(count,curve),Q.GetCumulativeStrength(level,curve))end end
 end
 for i,v in {12,17,24,30,45}do eq(R.GetRequiredLevel(i-1,2),v)end
 local walls={{50,75,100,135},{275,300,320,390},{565,705,845,1130},{2880,3600,4320,5760},{6860,8575,10290,13720}}
 local hp={200,1800,10000,25000,70000};local levels={4,8,15,20,25}
 local totalBoss,totalWall,oldTotal,allBefore,allAfter=0,0,0,0,0
 for stage=1,10 do
  local new,old=C.GetWallConfig(stage),OldC.GetWallConfig(stage)
  eq(new.BossMaxHP<=old.BossMaxHP,true,"boss must not increase")
  local a,b=new.BossMaxHP,old.BossMaxHP
  for i=1,4 do
   eq(new.Walls[i]<=old.Walls[i],true,"wall must not increase")
   a+=new.Walls[i];b+=old.Walls[i]
   if stage<=5 then eq(new.Walls[i],walls[stage][i]);totalWall+=new.Walls[i]else eq(new.Walls[i],old.Walls[i])end
  end
  eq(a<=b,true,"stage total");allBefore+=b;allAfter+=a
  if stage<=5 then
   eq(new.BossMaxHP,hp[stage]);eq(C.GetRecommendedLevel(stage),levels[stage])
   totalBoss+=new.BossMaxHP;oldTotal+=b
   eq(new.BossMaxHP/Q.GetCumulativeStrength(levels[stage],2),5,"five hits arithmetic")
  else eq(new.BossMaxHP,old.BossMaxHP);eq(C.GetRecommendedLevel(stage),OldC.GetRecommendedLevel(stage))end
 end
 eq(totalBoss,107000);eq(totalWall,60895);eq(totalBoss+totalWall,167895);eq(oldTotal,182660)
 eq(allBefore-allAfter,14765);eq(sources.World2,sources.OldWorld2,"World2 source unchanged")
 eq(C.NeedsIntroTraining(2,5,false),true);eq(C.NeedsIntroTraining(2,10,false),false)
 return {Checks=checks,BossTotal=totalBoss,WallTotal=totalWall,World1Before=allBefore,World1After=allAfter,Kind="Pure Luau; no actual Play"}
end
