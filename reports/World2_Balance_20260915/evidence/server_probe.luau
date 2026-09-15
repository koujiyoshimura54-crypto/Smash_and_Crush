-- Temporary read-only config audit; removed after Play.
local H=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local result={rows={},format={},world1={},checks=0}
local function eq(a,b,label) assert(a==b,label..": "..tostring(a).." != "..tostring(b));result.checks+=1 end
local ok,err=pcall(function()
 local W=require(RS.Config.World2Config)
 local B=require(RS.Config.World2BossConfig)
 local Walls=require(game.ServerScriptService.Config.World2WallConfig)
 local L=require(RS.Config.LevelRequirements)
 local F=require(RS.Modules.NumberFormat)
 local expected=H:JSONDecode([==[[{"Stage":1,"RecommendedLevel":60,"RequiredStrength":3000000,"Walls":[6000000,7500000,9000000,12000000],"BossHP":15000000},{"Stage":2,"RecommendedLevel":75,"RequiredStrength":10000000,"Walls":[20000000,25000000,30000000,40000000],"BossHP":50000000},{"Stage":3,"RecommendedLevel":90,"RequiredStrength":20000000,"Walls":[40000000,50000000,60000000,80000000],"BossHP":100000000},{"Stage":4,"RecommendedLevel":105,"RequiredStrength":50000000,"Walls":[100000000,125000000,150000000,200000000],"BossHP":250000000},{"Stage":5,"RecommendedLevel":120,"RequiredStrength":100000000,"Walls":[200000000,250000000,300000000,400000000],"BossHP":500000000},{"Stage":6,"RecommendedLevel":140,"RequiredStrength":200000000,"Walls":[400000000,500000000,600000000,800000000],"BossHP":1000000000},{"Stage":7,"RecommendedLevel":155,"RequiredStrength":500000000,"Walls":[1000000000,1250000000,1500000000,2000000000],"BossHP":2500000000},{"Stage":8,"RecommendedLevel":170,"RequiredStrength":1000000000,"Walls":[2000000000,2500000000,3000000000,4000000000],"BossHP":5000000000},{"Stage":9,"RecommendedLevel":185,"RequiredStrength":2000000000,"Walls":[4000000000,5000000000,6000000000,8000000000],"BossHP":10000000000},{"Stage":10,"RecommendedLevel":200,"RequiredStrength":5000000000,"Walls":[10000000000,12500000000,15000000000,20000000000],"BossHP":25000000000}]]==])
 eq(W.World2HPScale,nil,"legacy scale absent")
 eq(W.StageCount,10,"stage count")
 for _,e in ipairs(expected) do
  local s=e.Stage local c=W.GetStageConfig(s)
  eq(c.RecommendedLevel,e.RecommendedLevel,"level")
  eq(c.RequiredStrength,e.RequiredStrength,"strength")
  eq(B.GetRecommendedLevel(s),e.RecommendedLevel,"boss level")
  eq(B.GetRequiredStrength(s),e.RequiredStrength,"boss strength")
  eq(B.GetMaxHP(s),e.BossHP,"boss HP")
  eq(c.BossMaxHP,e.BossHP,"authority HP")
  for i=1,4 do eq(Walls.GetMaxHP(s,i),e.Walls[i],"wall HP");eq(c.Walls[i],e.Walls[i],"authority wall") end
  local values={c.RequiredStrength,c.BossMaxHP,table.unpack(c.Walls)}
  local holder=Instance.new("Folder")
  for i,v in ipairs(values) do
   eq(typeof(v),"number","numeric type")
   holder:SetAttribute("N"..i,v)
   eq(holder:GetAttribute("N"..i),v,"attribute roundtrip")
   eq(H:JSONDecode(H:JSONEncode({n=v})).n,v,"JSON roundtrip")
   eq(tonumber(string.format("%.0f",v)),v,"decimal string roundtrip")
   eq((v-1)+1,v,"unit HP subtraction")
  end
  holder:Destroy()
  local hp=e.BossHP for _=1,5 do hp=math.max(0,hp-e.RequiredStrength) end eq(hp,0,"5-hit arithmetic")
  e.ActualLevel=L.CalculateLevel(e.RequiredStrength)
  e.StrengthAtRecommendedLevel=L.GetRequiredStrength(e.RecommendedLevel)
  table.insert(result.rows,e)
 end
 for _,e in ipairs({{15000000,"15M"},{500000000,"500M"},{1000000000,"1B"},{2500000000,"2.5B"},{25000000000,"25B"},{1250000000,"1.2B"}}) do
  local text=F.Format(e[1])
  if e[1]~=1250000000 then eq(text,e[2],"HP formatter") end
  table.insert(result.format,{value=e[1],text=text})
 end
 local W1=require(RS.Config.World1LateStageConfig)
 local W1Wall=require(game.ServerScriptService.World.Stage1WallManager)
 for s=1,10 do table.insert(result.world1,{Stage=s,RecommendedLevel=W1.GetRecommendedLevel(s),RequiredStrength=W1.GetRequiredStrength(s),BossHP=W1.GetMaxHP(s),Walls=W1Wall.GetStageConfig(s).Walls}) end
 eq(Walls.GetMaxHP(0,1),nil,"invalid stage")
 eq(B.GetMaxHP(11),nil,"invalid boss stage")
 result.integrationStatus=workspace.World2Map:GetAttribute("IntegrationStatus")
 result.world2Humanoids=0
 for _,o in workspace.World2Map:GetDescendants() do if o:IsA("Humanoid") then result.world2Humanoids+=1 end end
end)
result.ok=ok result.error=not ok and tostring(err) or nil
local v=Instance.new("StringValue") v.Name="World2BalanceAuditResult"
v.Value=H:JSONEncode(result)
v:SetAttribute("MaxHPProbe",25000000000)
v.Parent=RS
