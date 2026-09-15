local H=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local out={checks=0,anchors={},world2={},samples={}}
local function eq(a,b,label) assert(a==b,label..": "..tostring(a).." != "..tostring(b));out.checks+=1 end
local ok,err=pcall(function()
 local L=require(RS.Config.LevelRequirements)
 local explicit=H:JSONDecode([==[{"1":0,"2":20,"3":40,"4":60,"5":80,"6":115,"7":145,"8":180,"9":225,"10":280,"11":320,"12":365,"13":410,"14":460,"15":525,"16":600,"17":750,"18":1100,"19":1350,"20":1500,"21":1750,"22":2000,"23":2500,"24":3000,"25":3500,"26":4000,"27":5000,"28":6000,"29":7500,"30":9000,"31":11000,"32":14000,"33":17000,"34":21000,"35":25000,"36":30000,"37":36000,"38":43000,"39":51000,"40":60000,"41":72000,"42":85000,"43":98000,"44":114000,"45":130000,"46":150000,"47":172000,"48":196000,"49":222000,"50":250000,"51":319000,"52":463000,"53":671000,"54":932000,"55":1235000,"56":1569000,"57":1924000,"58":2287000,"59":2650000,"60":3000000,"61":3351000,"62":3724000,"63":4118000,"64":4530000,"65":4961000,"66":5408000,"67":5871000,"68":6349000,"69":6840000,"70":7343000,"71":7857000,"72":8381000,"73":8914000,"74":9454000,"75":10000000,"76":10543000,"77":11080000,"78":11614000,"79":12153000,"80":12702000,"81":13266000,"82":13852000,"83":14465000,"84":15111000,"85":15795000,"86":16524000,"87":17304000,"88":18139000,"89":19036000,"90":20000000,"91":21098000,"92":22382000,"93":23840000,"94":25458000,"95":27222000,"96":29120000,"97":31138000,"98":33262000,"99":35480000,"100":37778000,"101":40142000,"102":42560000,"103":45018000,"104":47502000,"105":50000000,"106":52568000,"107":55269000,"108":58098000,"109":61049000,"110":64116000,"111":67294000,"112":70578000,"113":73963000,"114":77442000,"115":81010000,"116":84662000,"117":88392000,"118":92196000,"119":96067000,"120":100000000,"121":103910000,"122":107737000,"123":111513000,"124":115273000,"125":119048000,"126":122873000,"127":126779000,"128":130800000,"129":134968000,"130":139317000,"131":143880000,"132":148690000,"133":153779000,"134":159181000,"135":164928000,"136":171053000,"137":177591000,"138":184572000,"139":192031000,"140":200000000,"141":209441000,"142":221171000,"143":235012000,"144":250782000,"145":268301000,"146":287388000,"147":307864000,"148":329548000,"149":352259000,"150":375817000,"151":400042000,"152":424753000,"153":449770000,"154":474912000,"155":500000000,"156":525383000,"157":551580000,"158":578667000,"159":606716000,"160":635802000,"161":666000000,"162":697383000,"163":730025000,"164":764000000,"165":799383000,"166":836247000,"167":874667000,"168":914716000,"169":956469000,"170":1000000000,"171":1045235000,"172":1092247000,"173":1141333000,"174":1192790000,"175":1246914000,"176":1304000000,"177":1364346000,"178":1428247000,"179":1496000000,"180":1567901000,"181":1644247000,"182":1725333000,"183":1811457000,"184":1902914000,"185":2000000000,"186":2109778000,"187":2238222000,"188":2384000000,"189":2545778000,"190":2722222000,"191":2912000000,"192":3113778000,"193":3326222000,"194":3548000000,"195":3777778000,"196":4014222000,"197":4256000000,"198":4501778000,"199":4750222000,"200":5000000000}]==])
 local old=H:JSONDecode([==[{"1":0,"2":20,"3":40,"4":60,"5":80,"6":115,"7":145,"8":180,"9":225,"10":280,"11":320,"12":365,"13":410,"14":460,"15":525,"16":600,"17":750,"18":1100,"19":1350,"20":1500,"21":1750,"22":2000,"23":2500,"24":3000,"25":3500,"26":4000,"27":5000,"28":6000,"29":7500,"30":9000,"31":11000,"32":14000,"33":17000,"34":21000,"35":25000,"36":30000,"37":36000,"38":43000,"39":51000,"40":60000,"41":72000,"42":85000,"43":98000,"44":114000,"45":130000,"46":150000,"47":172000,"48":196000,"49":222000,"50":250000}]==])
 eq(L.MaxLevel,10000,"cap")
 eq(L.MaxFixedLevel,200,"explicit range")
 for s=1,200 do eq(L.FixedStrength[s],explicit[tostring(s)],"literal threshold") end
 for s=1,50 do eq(L.GetRequiredStrength(s),old[tostring(s)],"World1 threshold unchanged") end
 local prev=-1
 for level=1,10000 do
  local threshold=level<=200 and explicit[tostring(level)] or 5000000000+(level-200)*250000000
  eq(L.GetRequiredStrength(level),threshold,"required threshold")
  assert(threshold>prev,"not strictly increasing");out.checks+=1
  eq(L.CalculateLevel(threshold),level,"at threshold")
  if level>1 then
   eq(L.CalculateLevel(threshold-1),level-1,"below threshold")
   eq(L.CalculateLevel(threshold-0.5),level-1,"fraction below threshold")
  end
  eq(L.CalculateLevel(threshold+0.5),level,"fraction above threshold")
  if level<10000 then
   local nextT=L.GetRequiredStrength(level+1)
   eq(L.CalculateLevel((threshold+nextT)/2),level,"midpoint")
  end
  prev=threshold
 end
 for _,pair in ipairs(H:JSONDecode([==[[[50,250000],[60,3000000],[75,10000000],[90,20000000],[105,50000000],[120,100000000],[140,200000000],[155,500000000],[170,1000000000],[185,2000000000],[200,5000000000]]]==])) do
  eq(L.GetRequiredStrength(pair[1]),pair[2],"anchor")
  table.insert(out.anchors,{level=pair[1],strength=pair[2]})
 end
 local W=require(RS.Config.World2Config)
 for s=1,10 do local c=W.Stages[s]
  eq(L.GetRequiredStrength(c.RecommendedLevel),c.RequiredStrength,"World2 anchor")
  eq(L.CalculateLevel(c.RequiredStrength),c.RecommendedLevel,"World2 level")
  table.insert(out.world2,{Stage=s,Level=c.RecommendedLevel,Strength=c.RequiredStrength})
 end
 eq(L.CalculateLevel(1e308),10000,"huge finite terminates")
 eq(L.CalculateLevel(math.huge),10000,"infinity terminates")
 eq(L.CalculateLevel(0/0),1,"NaN")
 eq(L.CalculateLevel(-1),1,"negative")
 eq(L.GetRequiredStrength(10001),2455000000000,"cap getter")
 eq(L.GetRequiredStrength(201),5250000000,"201 bridge")
 eq(L.GetRequiredStrength(10000),2455000000000,"10000 threshold")
 local F=require(RS.Modules.NumberFormat)
 for _,level in ipairs({50,51,60,75,90,105,120,140,155,170,185,199,200,201,9999,10000}) do
  local t=L.GetRequiredStrength(level) local n=L.GetRequiredStrength(level+1)
  local holder=Instance.new("Folder") holder:SetAttribute("Strength",t)
  eq(holder:GetAttribute("Strength"),t,"attribute") holder:Destroy()
  eq(H:JSONDecode(H:JSONEncode({value=t})).value,t,"JSON")
  eq((t-1)+1,t,"unit precision")
  table.insert(out.samples,{level=level,strength=t,nextStrength=n,formatted=F.Format(t)})
 end
end)
out.ok=ok out.error=not ok and tostring(err) or nil
local v=Instance.new("StringValue") v.Name="LevelCurveAuditResult" v.Value=H:JSONEncode(out) v.Parent=RS
