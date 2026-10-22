-- Approved 2026-10-22. Locomotion never changes pursuit/combat tuning.
local r15="rbxassetid://507777826"
local stages={
 [1]={Walk=r15,Retarget="R15ToR6",RetargetWeight=.5,Rig="SCP096"},
 [3]={Walk=r15,Rig="R15"},
 [5]={Walk=r15,Rig="SCP049",IntroPath={"AnimSaves","Idle"}},
 [8]={Walk="rbxassetid://125749145",Rig="R6"},
 [10]={Walk=r15,Rig="R15"},
}
for _,row in stages do table.freeze(row) end
return table.freeze({Stages=table.freeze(stages),LoadTimeout=8,MaxIntroDuration=30,
 MoveThreshold=.15,FadeTime=.12,ReferenceSpeed=16,ReferenceLegLength=4})
