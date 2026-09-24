local T={}
function T.Run()
 local source=game.ServerScriptService.Systems.Debug.StudioDebugService.Source
 local results={}
 local function check(name,fn) fn();table.insert(results,"PASS "..name) end
 local disabled=source:gsub('game:GetService%("RunService"%)','{IsStudio=function() return false end}')
 check("Published server exits before dependencies and denies every command",function()
  local service=assert(loadstring(disabled))()
  for _,message in ipairs({"/resetdata","/setstrength 360","/setstage 5"}) do
   local ok,code=service.Execute({},message);assert(not ok and code=="StudioOnly")
  end
 end)
 local template=source
 for _,name in ipairs({"RunService","Players","DataStoreService"}) do
  template=template:gsub('game:GetService%("'..name..'"%)',"D."..name)
 end
 for _,name in ipairs({"PlayerDataService","StrengthManager","EnemyManager","TrainingManager","TrophyRewardService","StageSkipService","ItemPurchaseService"}) do
  template=template:gsub("require%(script.Parent."..name.."%)","D."..name)
 end
 template=template:gsub("local RESET_SAVED_DATA=false","local RESET_SAVED_DATA=true") -- isolated storage only
 local factory=assert(loadstring("return function(D) local workspace=D.World; local realTypeof=typeof;local function typeof(v) if type(v)=='table' and v.TestPlayer then return 'Instance' end return realTypeof(v) end\n"..template.." end"))()
 local function fixture()
  local D={};D.RunService={IsStudio=function() return true end};D.Players={}
  local p={TestPlayer=true,UserId=101,Parent=D.Players,Values={Strength=1000,Win=50,RebirthCount=4}}
  function p:IsA(n) return n=="Player" end
  function p:GetAttribute(n) return self.Values[n] end
  function p:SetAttribute(n,v) self.Values[n]=v end
  local root={Anchored=false,Parent=true}
  local hum={Health=100,MaxHealth=100,HipHeight=2}
  p.Character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return hum end,
   GetBoundingBox=function() return CFrame.new(),Vector3.new(4,6,4) end,
   PivotTo=function(_,cf) D.Position=cf end,GetDescendants=function() return {} end}
  local data={Strength=1000,Win=50,RebirthCount=4,TotalStrengthEarned=1000,DailyStrengthEarned=500,DailyDate="old",
   OwnedDumbbells={NORMAL_01=true},EquippedDumbbell="NORMAL_01",OwnedItems={PROTEIN_COMMON_FIRE=3},EquippedItems={Protein="PROTEIN_COMMON_FIRE",Glove="",TrainingBelt=""}}
  D.Session={Loaded=true,Saving=false,Data=data}
  D.Stored=table.clone(data);D.Stored.FutureField="preserved";D.Meta={ItemReceiptId="receipt"};D.Users={101}
  D.PlayerDataService={
   Get=function() return D.Session end,Today=function() return "2026-09-09" end,
   SetWin=function(_,v) D.Session.Data.Win=v;p:SetAttribute("Win",v) end,
   SetRebirthCount=function(_,v) D.Session.Data.RebirthCount=v;p:SetAttribute("RebirthCount",v) end,
   Reset=function(_,player)
    D.Session.Saving=true;D.Session.Loaded=false
    local fresh={Strength=0,RebirthCount=0,TotalStrengthEarned=0,DailyStrengthEarned=0,DailyDate="2026-09-09",
     Win=0,OwnedDumbbells={},EquippedDumbbell="",OwnedItems={},EquippedItems={Protein="",Glove="",TrainingBelt=""},ResetToken="reset"}
    if D.Fail then D.Session.Loaded=true;D.Session.Saving=false;return false,"simulated failure" end
    local nextValue=table.clone(D.Stored);for k,v in pairs(fresh) do nextValue[k]=v end
    D.Stored=nextValue;D.Session.Data=fresh;D.Session.Loaded=true;D.Session.Saving=false;D.Session.Data.Dirty=true
    return true,fresh
   end}
  D.StrengthManager={ResetGainRemainder=function() D.Remainder=0 end,
   CalculateLevel=function(v) local t={0,20,40,65,95,130,170,220,280,360};local level=1;for i=2,10 do if v<t[i] then return level end;level=i end;while v>=10*level^2 do level+=1 end;return level end,
   SetStrength=function(_,v) D.Session.Data.Strength=v;p:SetAttribute("Strength",v);p:SetAttribute("Level",D.StrengthManager.CalculateLevel(v)) end}
  D.EnemyManager={IsReady=function() return true end,StartRun=function(_,n) D.Stage=n end}
  D.TrainingManager={StopTraining=function() D.Stopped=true end}
  D.TrophyRewardService={GetLobbySpawn=function() return {CFrame=CFrame.new(),Size=Vector3.new(10,1,10)} end}
  D.StageSkipService={TryLock=function() return true end,Unlock=function() D.Unlocked=true end,
   ApplyLocked=function(_,stage) D.Stage=stage;return true,"Moved" end}
  D.ItemPurchaseService={GetPending=function() return D.Intent end}
  D.World={FindFirstChild=function() return nil end}
  D.DataStoreService={GetDataStore=function(_,name)
   assert(name=="PlayerData_v1")
   return {UpdateAsync=function(_,key,fn)
    assert(key=="Player_101" and not D.Session.Loaded and D.Session.Saving)
    if D.Fail then error("simulated failure") end
    local nextValue,users,meta=fn(D.Stored,{GetUserIds=function() return D.Users end,GetMetadata=function() return D.Meta end})
    D.Stored=nextValue;assert(users==D.Users and meta==D.Meta);return nextValue
   end}
  end,GetOrderedDataStore=function() return {SetAsync=function(_,key,v) assert(key=="101" and v==0) end} end}
  return factory(D),D,p
 end
 check("setstrength delegates to shared setter/level logic; malformed numbers and unloaded data rejected",function()
  local service,D,p=fixture()
  for _,n in ipairs({0,360,10000}) do assert(service.Execute(p,"/setstrength "..n));assert(p:GetAttribute("Strength")==n and p:GetAttribute("Level")==D.StrengthManager.CalculateLevel(n)) end
  for _,s in ipairs({"/setstrength -1","/setstrength nan","/setstrength inf","/setstrength 1e999","/setstrength 5 extra","/setstrength"}) do assert(not service.Execute(p,s)) end
  D.Session.Loaded=false;assert(not service.Execute(p,"/setstrength 360"))
 end)
 check("setstage validates 1-10, uses existing stage APIs and spends no Win",function()
  local service,D,p=fixture()
  for n=1,10 do assert(service.Execute(p,"/setstage "..n));assert(D.Stage==n and p:GetAttribute("Win")==50) end
  for _,s in ipairs({"/setstage 0","/setstage 11","/setstage 1.5","/setstage bad"}) do assert(not service.Execute(p,s)) end
 end)
 check("reset clears current player schema, mirrors, equipment and counters; preserves store metadata; returns Stage1",function()
  local service,D,p=fixture();assert(service.Execute(p,"/resetdata"))
  local s=D.Session
  assert(s.Loaded and not s.Saving and D.Stage==1 and D.Stopped and D.Remainder==0)
  for _,k in ipairs({"Strength","RebirthCount","Win","TotalStrengthEarned","DailyStrengthEarned"}) do assert(s.Data[k]==0 and D.Stored[k]==0 and p:GetAttribute(k)==0) end
  assert(p:GetAttribute("Level")==1 and next(s.Data.OwnedItems)==nil and next(s.Data.OwnedDumbbells)==nil)
  assert(s.Data.EquippedDumbbell=="" and s.Data.EquippedItems.Protein=="" and s.Data.EquippedItems.Glove=="" and s.Data.EquippedItems.TrainingBelt=="")
  assert(D.Stored.FutureField=="preserved" and D.Meta.ItemReceiptId=="receipt" and s.Data.DailyDate=="2026-09-09")
 end)
 check("reset refuses pending saves/purchases; write failure restores lock and keeps local inventory",function()
  local service,D,p=fixture()
  D.Session.Saving=true;assert(not service.Execute(p,"/resetdata"));D.Session.Saving=false
  D.Intent={};assert(not service.Execute(p,"/resetdata"));D.Intent=nil
  D.Fail=true;assert(not service.Execute(p,"/resetdata"))
  assert(D.Session.Loaded and not D.Session.Saving and D.Session.Data.Strength==1000 and D.Stored.Win==50)
 end)
 return table.concat(results,"\n")
end
return T
