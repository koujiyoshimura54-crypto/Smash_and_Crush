-- Approved 2026-10-22. Locomotion never changes pursuit/combat tuning.
local r15="rbxassetid://507777826"
local stages={
 [1]={Rig="SCP096Skin",MinBones=73},
 [2]={Rig="SCP023",MinMotors=6,Gait={Period=1,ReferenceSpeed=19,Amplitude=.70,Stance=.60,GroundLimit=.65}},
 [3]={Walk=r15,Rig="R15"},
 [4]={Rig="SCP058",MinMotors=13,Gait={Period=.75,ReferenceSpeed=21,Stride=1.05,Lift=.55,Stance=.62,GroundLimit=.40}},
 [5]={Walk=r15,Rig="SCP049",IntroPath={"AnimSaves","Idle"}},
 [6]={Rig="SCP173",MinMotors=5,Gait={Period=.8,ReferenceSpeed=23,Amplitude=.70,ArmAmplitude=.95,Stance=.60,GroundLimit=.55}},
 [7]={Rig="SCP939",MinMotors=13,Gait={Period=1,ReferenceSpeed=24,Amplitude=1.35,GroundLimit=1.25,ClipPath={"AnimSaves","939walk"}}},
 [8]={Walk="rbxassetid://125749145",Rig="R6"},
 [9]={Rig="SCP682Skin",MinMotors=0,Gait={Period=.32,ReferenceSpeed=26,Stride=2.7,Lift=1.1,Stance=.58}},
 [10]={Walk=r15,Rig="R15"},
}
for _,row in stages do if row.Gait then table.freeze(row.Gait) end;table.freeze(row) end
return table.freeze({Stages=table.freeze(stages),LoadTimeout=8,MaxIntroDuration=30,
 MoveThreshold=.15,FadeTime=.12,ReferenceSpeed=16,ReferenceLegLength=4})
