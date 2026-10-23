-- Approved imported body clips. Speeds are independent and editable here.
-- This config affects only World2 Stage1; damage remains in BossAttackService.
local clips={
 GetUp_Panic={Name="GetUp_Panic_BodyBones",Speed=2,Looped=false},
 Panic={Name="Panic_BodyBones",Speed=2,Looped=false},
 Running={Name="Running_BodyBones",Speed=1,Looped=true},
 AttackRunStart={Name="AttackRunStart_BodyBones",Speed=1,Looped=false},
 AttackRun={Name="AttackRun_BodyBones",Speed=1,Looped=true},
}
for _,clip in clips do table.freeze(clip) end
return table.freeze({Clips=table.freeze(clips),Folder="BodyClips",BoneCount=73,
 -- Keep authored vertical crouching. Planar root motion never moves the actor.
 RemovePlanarRootMotion=true})
