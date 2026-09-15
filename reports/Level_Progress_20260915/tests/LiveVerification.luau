if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local P=require(game.ReplicatedStorage.Modules.LevelProgression)
local R=require(game.ReplicatedStorage.Config.LevelRequirements)
local Boss=require(game.ServerScriptService.World.BossCombatService)
local Http=game:GetService("HttpService")
local p=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
while not Data.IsLoaded(p) do task.wait(.1)end
local function snap()
 local d=Data.Get(p).Data
 return {Strength=d.Strength,Level=d.Level,LevelProgress=d.LevelProgress,RebirthCount=d.RebirthCount,Win=d.Win,HighestUnlockedWorld=d.HighestUnlockedWorld}
end
local function result(value)script:SetAttribute("Results",Http:JSONEncode(value))end
result({Loaded=snap()})
script:SetAttribute("Ready",true)
local busy=false
script:GetAttributeChangedSignal("Command"):Connect(function()
 if busy then return end busy=true
 local command=script:GetAttribute("Command")
 local ok,res=pcall(function()
  if command=="ResetCase" then
   local d=Data.Get(p).Data
   d.Level,d.LevelProgress=60,0
   Strength.SetStrength(p,3000000);Strength.UpdateLevel(p)
   return snap()
  elseif command=="RebirthCase" then
   local d=Data.Get(p).Data
   d.Level,d.LevelProgress=10,7
   Strength.SetStrength(p,1);Strength.UpdateLevel(p)
   return snap()
  elseif command=="Gain500K" then
   local before=snap()
   assert(Strength.AddRewardStrength(p,500000))
   local after=snap()
   assert(after.Strength==before.Strength+500000 and after.Level==60 and after.LevelProgress==500000)
   assert(Data.Save(p))
   return {Before=before,After=after,Saved=true}
  elseif command=="Gain2_5M" then
   local before=snap();assert(Strength.AddRewardStrength(p,2500000))
   local after=snap();assert(after.Strength==6000000 and after.Level==61 and after.LevelProgress==0)
   assert(Data.Save(p))
   return {Before=before,After=after,Saved=true}
  elseif command=="MultiLevel" then
   local gain=R.GetRequiredStrength(61)+R.GetRequiredStrength(62)+123
   local before=snap();assert(Strength.AddRewardStrength(p,gain))
   local after=snap();assert(after.Level==63 and after.LevelProgress==123 and after.Strength==before.Strength+gain)
   assert(Data.Save(p))
   return {Before=before,After=after,Saved=true}
  elseif command=="Combat" then
   Boss.Reset(p)
   local old=p:GetAttribute("EquippedGlove")
   local s=Boss.Begin(p,{},6)
   assert(s.BattleStartStrength==Strength.GetStrength(p) and s.PlayerLevel==Strength.GetLevel(p))
   local expected=s.BattleStartStrength*(1+s.GloveBonus)
   assert(s.BattleDamage==expected)
   local hp=s.HP;Boss.Attack(p);assert(s.HP==math.max(0,hp-expected));Boss.Reset(p)
   return {Strength=Strength.GetStrength(p),Level=Strength.GetLevel(p),Damage=expected}
  elseif command=="Save" then assert(Data.Save(p));return {Saved=snap()}
  elseif command=="Snapshot" then return snap()
  end
  error("Unknown test command")
 end)
 result({Command=command,Pass=ok,Result=ok and res or tostring(res)})
 busy=false
end)

