-- Play regression probe: temporary Script, removed from Edit after verification.
-- Uses isolated attribute-only player doubles with live service modules; no saved/connected Player mutations.
local HttpService=game:GetService("HttpService")
local expected=HttpService:JSONDecode([==[{"world2":[{"BossMaxHP":15000000,"RequiredStrength":3000000,"RecommendedLevel":60,"Walls":[6000000,7500000,9000000,12000000]},{"BossMaxHP":50000000,"RequiredStrength":10000000,"RecommendedLevel":75,"Walls":[20000000,25000000,30000000,40000000]},{"BossMaxHP":100000000,"RequiredStrength":20000000,"RecommendedLevel":90,"Walls":[40000000,50000000,60000000,80000000]},{"BossMaxHP":250000000,"RequiredStrength":50000000,"RecommendedLevel":105,"Walls":[100000000,125000000,150000000,200000000]},{"BossMaxHP":500000000,"RequiredStrength":100000000,"RecommendedLevel":120,"Walls":[200000000,250000000,300000000,400000000]},{"BossMaxHP":1000000000,"RequiredStrength":200000000,"RecommendedLevel":140,"Walls":[400000000,500000000,600000000,800000000]},{"BossMaxHP":2500000000,"RequiredStrength":500000000,"RecommendedLevel":155,"Walls":[1000000000,1250000000,1500000000,2000000000]},{"BossMaxHP":5000000000,"RequiredStrength":1000000000,"RecommendedLevel":170,"Walls":[2000000000,2500000000,3000000000,4000000000]},{"BossMaxHP":10000000000,"RequiredStrength":2000000000,"RecommendedLevel":185,"Walls":[4000000000,5000000000,6000000000,8000000000]},{"BossMaxHP":25000000000,"RequiredStrength":5000000000,"RecommendedLevel":200,"Walls":[10000000000,12500000000,15000000000,20000000000]}],"world1":[{"recommendedLevel":8,"bossHP":250,"wallHP":[100,125,150,200],"requiredStrength":50,"stage":1,"wallBossHP":250},{"recommendedLevel":10,"bossHP":500,"wallHP":[300,325,350,425],"requiredStrength":100,"stage":2,"wallBossHP":500},{"recommendedLevel":15,"bossHP":2250,"wallHP":[600,750,900,1200],"requiredStrength":450,"stage":3,"wallBossHP":2250},{"recommendedLevel":20,"bossHP":10000,"wallHP":[3000,3750,4500,6000],"requiredStrength":2000,"stage":4,"wallBossHP":10000},{"recommendedLevel":25,"bossHP":25000,"wallHP":[7000,8750,10500,14000],"requiredStrength":5000,"stage":5,"wallBossHP":25000},{"recommendedLevel":30,"bossHP":186575,"wallHP":[74630,93287.5,111945,149260],"requiredStrength":37315,"stage":6,"wallBossHP":186575},{"recommendedLevel":35,"bossHP":409325,"wallHP":[163730,204662.5,245595,327460],"requiredStrength":81865,"stage":7,"wallBossHP":409325},{"recommendedLevel":40,"bossHP":984575,"wallHP":[393830,492287.5,590745,787660],"requiredStrength":196915,"stage":8,"wallBossHP":984575},{"recommendedLevel":45,"bossHP":2314825,"wallHP":[925930,1157412.5,1388895,1851860],"requiredStrength":462965,"stage":9,"wallBossHP":2314825},{"recommendedLevel":50,"bossHP":5090075,"wallHP":[2036030,2545037.5,3054045,4072060],"requiredStrength":1018015,"stage":10,"wallBossHP":5090075}]}]==])
local function newProbePlayer()
 local attributes={}
 return {
  GetAttribute=function(_,key) return attributes[key] end,
  SetAttribute=function(_,key,value) attributes[key]=value end,
  Destroy=function() end,
 }
end
local checks=0
local function eq(actual,wanted,label)
 checks+=1
 assert(actual==wanted,label..": "..tostring(actual).." ~= "..tostring(wanted))
end
local function deep(actual,wanted,label)
 if typeof(wanted)~="table" then eq(actual,wanted,label);return end
 for k,v in pairs(wanted) do deep(actual[k],v,label.."."..tostring(k)) end
end
local ok,result=xpcall(function()
 local B=require(game.ServerScriptService.World.BossCombatService)
 local W=require(game.ServerScriptService.World.Stage1WallManager)
 local S=require(game.ServerScriptService.World.StageManager)
 local W2=require(game.ReplicatedStorage.Config.World2Config)
 local W2Boss=require(game.ReplicatedStorage.Config.World2BossConfig)
 local W2Wall=require(game.ServerScriptService.Config.World2WallConfig)
 local rows,world2,combat,lottery={},{},{},{}
 for stage=1,10 do
  local b,w=B.GetStageConfig(stage),W.GetStageConfig(stage)
  local row={stage=stage,recommendedLevel=b.RecommendedLevel,requiredStrength=b.RequiredStrength,bossHP=b.MaxHP,wallHP=w.Walls,wallBossHP=w.BossMaxHP}
  deep(row,expected.world1[stage],"World1."..stage)
  rows[stage]=row
  local entry=W2.GetStageConfig(stage)
  deep(entry,expected.world2[stage],"World2."..stage)
  eq(W2Boss.GetMaxHP(stage),entry.BossMaxHP,"World2 Boss")
  eq(W2Boss.GetRequiredStrength(stage),entry.RequiredStrength,"World2 Required")
  eq(W2Boss.GetRecommendedLevel(stage),entry.RecommendedLevel,"World2 Level")
  for index=1,4 do eq(W2Wall.GetMaxHP(stage,index),entry.Walls[index],"World2 Wall") end
  world2[stage]=entry

  local player=newProbePlayer()
  local boss=Instance.new("Model")
  player:SetAttribute("Strength",b.RequiredStrength)
  S.InitializePlayer(player,stage)
  W.InitializePlayer(player,stage)
  eq(S.GetCurrentStageNumber(player),stage,"Start stage")
  local hits,carry,total=0,0,0
  for _,hp in ipairs(w.Walls) do total+=hp end
  while not W.IsBossUnlockedForStage(player,stage) do
   local _,_,remaining=W.ApplyDamageForStage(player,stage,b.RequiredStrength)
   hits+=1;carry=remaining
   assert(hits<100,"Wall loop limit")
  end
  eq(hits,math.ceil(total/b.RequiredStrength),"Wall hits")
  eq(carry,hits*b.RequiredStrength-total,"Wall overflow")
  local wallSnapshot=W.GetSnapshotForStage(player,stage)
  eq(wallSnapshot.Current,5,"Boss unlocked")
  for index=1,4 do eq(wallSnapshot.Gauges[index],0,"Wall cleared") end
  B.QueueDamage(player,boss,stage,b.MaxHP,carry)
  local encounter=B.Begin(player,boss,stage)
  eq(encounter.Route,"LEVEL_DAMAGE","Normal combat")
  eq(encounter.HP,b.MaxHP-carry,"Boss carry")
  local startHP=encounter.HP
  local first=B.Attack(player)
  eq(first,"Active","First attack")
  local savedHP=encounter.HP
  B.Cancel(player)
  local resumed=B.Begin(player,boss,stage)
  eq(resumed,encounter,"Resume same encounter")
  eq(resumed.HP,savedHP,"Resume HP")
  local status=first
  while status=="Active" do status=B.Attack(player) end
  eq(status,"Win","Boss win")
  eq(encounter.Attacks,math.ceil(startHP/b.RequiredStrength),"Boss hits")
  local advanced=S.ClearStage(player,stage)
  eq(advanced,true,"Stage clear")
  if stage<10 then eq(S.GetCurrentStageNumber(player),stage+1,"Next stage")
  else eq(S.GetState(player).WorldComplete,true,"World complete") end
  combat[stage]={stage=stage,wallHits=hits,carry=carry,bossStartHP=startHP,bossHits=encounter.Attacks,nextStage=S.GetCurrentStageNumber(player),worldComplete=S.GetState(player).WorldComplete}
  B.Reset(player)

  player:SetAttribute("Strength",b.RequiredStrength*.5)
  local miss=B.Begin(player,boss,stage)
  eq(miss.Route,"LOTTERY_MISS","Zero chance route")
  eq(miss.Chance,0,"Zero chance")
  local missResult
  for i=1,B.MaxAttackCount do missResult=B.Attack(player) end
  eq(missResult,"Lose","Five-hit miss")
  B.Reset(player)
  player:SetAttribute("Strength",b.RequiredStrength*.99)
  local won=false
  for attempt=1,64 do
   local e=B.Begin(player,boss,stage)
   if e.Route=="LOTTERY_WIN" then
    for i=1,B.MaxAttackCount do
     local outcome=B.Attack(player)
     eq(outcome,i==B.MaxAttackCount and "Win" or "Active","Five-hit lottery win")
    end
    won=true;break
   end
   B.Reset(player)
  end
  eq(won,true,"Lottery win route exercised")
  B.Reset(player)
  player:Destroy();boss:Destroy()
 end
 local cases={{0,0},{.599999,0},{.6,.25},{.699999,.25},{.7,.5},{.799999,.5},{.8,.8},{.849999,.8},{.85,.85},{.899999,.85},{.9,.9},{.949999,.9},{.95,.95},{.999999,.95},{1,0},{2,0}}
 for _,case in ipairs(cases) do
  eq(B.GetStrengthRatioWinChance(case[1]),case[2],"Lottery boundary")
  table.insert(lottery,{ratio=case[1],chance=B.GetStrengthRatioWinChance(case[1])})
 end
 local player=newProbePlayer()
 S.InitializePlayer(player,6);W.InitializePlayer(player,6)
 for i=1,5 do
  eq(S.IsStageSkipped(player,i),true,"Skipped stage")
  eq(W.GetSnapshotForStage(player,i).Skipped,true,"Skipped wall")
 end
 eq(S.ClearStage(player,7),false,"Out-of-order rejected")
 eq(S.GetCurrentStageNumber(player),6,"Order preserved")
 eq(W.GetSnapshotForStage(player,6).Current,1,"Skip target wall")
 W.ApplyDamageForStage(player,6,-100)
 eq(W.GetGaugeForStage(player,6,1),expected.world1[6].wallHP[1],"Negative damage ignored")
 player:Destroy()
 return {world1=rows,world2=world2,combat=combat,lottery=lottery,checks=checks}
end,debug.traceback)
script:SetAttribute("Success",ok)
script:SetAttribute("Result",HttpService:JSONEncode(ok and result or {error=tostring(result),checks=checks}))
script:SetAttribute("Done",true)
