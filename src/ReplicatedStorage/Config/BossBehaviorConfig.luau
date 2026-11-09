-- Authoritative Boss -> Player behavior for both Worlds, Stage1..10.
-- Edit a single row below. HP/wall HP and Player action clocks remain elsewhere.
-- Speed: studs/sec. TurnResponse: exponential response/sec. AttackInterval: sec.
-- Width/Depth/HeightScale scale the body-relative hit envelope, never Parts.
-- Reach fields/AttackHeight/VerticalPadding are studs (ReachScale is a ratio).
-- AttackAngle is degrees before the preserved Speed-equipment modifier below.
local C={Worlds={
 [1]={
  [1]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [2]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [3]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [4]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [5]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [6]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [7]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [8]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [9]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [10]={Speed=16,TurnResponse=4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
 },
 [2]={
  [1]={Speed=18,TurnResponse=4.5,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [2]={Speed=19,TurnResponse=4.8,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [3]={Speed=20,TurnResponse=5.1,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [4]={Speed=21,TurnResponse=5.4,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [5]={Speed=22,TurnResponse=5.7,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [6]={Speed=23,TurnResponse=6,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [7]={Speed=24,TurnResponse=6.3,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [8]={Speed=25,TurnResponse=6.6,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [9]={Speed=26,TurnResponse=6.9,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
  [10]={Speed=27,TurnResponse=7.2,AttackInterval=1,Damage=25,
   WidthScale=1,DepthScale=0.9,HeightScale=1,ReachScale=0.25,MinReach=8,MaxReach=14,
   AttackAngle=104,AttackHeight=3.5,VerticalPadding=1},
 },
}}
-- Preserve live Speed equipment tuning: NONE104 / BOOST160 / PREMIUM210.
-- These multiply the Stage's angle; they do not change Player WalkSpeed.
C.SpeedModifiers={
 NONE={AttackAngleScale=1},
 SPEED_BOOST={AttackAngleScale=160/104},
 SPEED_PREMIUM={AttackAngleScale=210/104},
}
local positive={AttackInterval=true,WidthScale=true,DepthScale=true,HeightScale=true}
for world,stages in pairs(C.Worlds) do
 for stage=1,10 do
  local row=assert(stages[stage],"Missing Boss behavior stage")
  for key,value in pairs(row) do
   assert(typeof(value)=="number" and value==value and value<math.huge and value>=0,"Invalid Boss behavior "..key)
   assert(not positive[key] or value>0,"Boss behavior must be positive: "..key)
  end
  assert(row.MinReach<=row.MaxReach and row.AttackAngle<=360,"Invalid Boss attack bounds")
  table.freeze(row)
 end
 table.freeze(stages)
end
for _,entry in pairs(C.SpeedModifiers) do table.freeze(entry) end
table.freeze(C.SpeedModifiers);table.freeze(C.Worlds)
function C.Get(worldId,stage)
 local stages=assert(C.Worlds[worldId],"Invalid Boss World")
 return assert(stages[stage],"Invalid Boss Stage")
end
function C.GetAttackSettings(worldId,stage,speedId)
 local row=C.Get(worldId,stage)
 local modifier=C.SpeedModifiers[speedId] or C.SpeedModifiers.NONE
 return {ReachScale=row.ReachScale,MinReach=row.MinReach,MaxReach=row.MaxReach,
  AttackAngle=math.min(360,row.AttackAngle*modifier.AttackAngleScale),
  AttackHeight=row.AttackHeight,VerticalPadding=row.VerticalPadding}
end
return table.freeze(C)
