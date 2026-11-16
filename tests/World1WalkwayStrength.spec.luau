-- Execute the actual AutoTapService with table-only dependencies. This checks
-- routing, not production rewards, DataStore, or real Treadmill occupancy.
return function(source)
 local riding,training,combat=false,false,false
 local gain=0
 local player={attrs={}}
 local Players={}
 player.Parent=Players
 function player:GetAttribute(k) return self.attrs[k] end
 function player:IsA(k) return k=="Player" end
 local hum={Health=100,MoveDirection=Vector3.zero,GetState=function()return Enum.HumanoidStateType.Running end}
 local root={AssemblyLinearVelocity=Vector3.new(0,0,12)}
 player.Character={FindFirstChildOfClass=function()return hum end,FindFirstChild=function(_,name)return name=="HumanoidRootPart" and root end}
 local deps={
  FirstPlayAnalyticsService={Strength=function()end,AutoOn=function()end},
  PlayerDataService={Get=function()return {Loaded=true}end,IsAutoTapEnabled=function()return true end},
  StrengthManager={GetStrength=function()return gain end,AddStrength=function(_,amount)gain+=amount;return gain end},
  TrainingManager={GetOccupiedTreadmill=function()return training and {} or nil end},
  EnemyManager={TryManualAttack=function()return combat,combat and "Wall" or "NoCombat" end,
   TryAutomaticAttack=function()return combat,combat and "Wall" or "NoCombat" end},
  PlayerActionTiming={CanAct=function()return true end,RecordSuccess=function()end},
  TrainingConfig={BaseGain=1},World1WalkwayService={IsRiding=function()return riding end},
 }
 local Services=setmetatable({},{__index=function(_,k)return k end})
 local fakeGame={ServerScriptService={Services=Services,World={EnemyManager="EnemyManager"}},ReplicatedStorage={Config={TrainingConfig="TrainingConfig"}},GetService=function(_,name)return name=="Players" and Players end}
 local factory=assert(loadstring("return function(game,require)\n"..source.."\nend"))()
 local M=factory(fakeGame,function(k)return assert(deps[k],k)end)
 local results={}
 local function check(ok,name) results[#results+1]={Name=name,Passed=ok};assert(ok,name)end
 riding=true
 local ok,why=M.TryAutomatic(player)
 check(not ok and why=="NotWalking" and gain==0,"Passive carry gives no automatic walking Strength")
 check(M.HandleTap(player) and gain==1,"Manual tap still gains Strength during a ride")
 riding=false
 check(M.TryAutomatic(player) and gain==2,"Ordinary grounded walking still gains Strength")
 root.AssemblyLinearVelocity=Vector3.zero
 local idle=M.TryAutomatic(player)
 check(not idle and gain==2,"Idle normal floor still gives no automatic gain")
 training=true
 local accepted,reason=M.TryAutomatic(player)
 check(not accepted and reason=="Treadmill" and gain==2,"Treadmill remains routed to its own existing reward owner")
 training=false;combat=true;riding=true
 check(M.TryAutomatic(player) and gain==2,"Combat remains above the walking-only gate")
 return {Kind="Mocked dependency routing using actual Source",Checks=results}
end
