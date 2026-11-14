-- World1 Stage1 Ballerina only. 1.0 restores the original animation amplitude.
return {
 Amplitude=2.0,
 WalkAnimationId="rbxassetid://101135921440052",
 GroundFit=true, -- Fit the cosmetic rig to the visible path, not the hidden Floor.
 -- Cycle centers of the existing Walk, in unscaled animation space.
 -- Preserve its fixed shoulder pose, bent knees and lowered torso.
 Centers={
  Torso=CFrame.new(0,-0.0733333,0),
  Head=CFrame.identity,
  ["Arm.L"]=CFrame.fromAxisAngle(Vector3.new(-0.025141,-0.045863,0.998631).Unit,1.048252),
  ["Arm.R"]=CFrame.fromAxisAngle(Vector3.new(-0.025141,0.045863,-0.998631).Unit,1.048252),
  ["Leg.L"]=CFrame.fromAxisAngle(Vector3.new(0.999958,0,0.009145).Unit,0.401012),
  ["Leg.R"]=CFrame.fromAxisAngle(Vector3.new(0.999958,0,-0.009145).Unit,0.401013),
  ["Leg.L.001"]=CFrame.fromAxisAngle(Vector3.new(-0.999730,-0.000058,-0.023218).Unit,0.778854),
  ["Leg.R.001"]=CFrame.fromAxisAngle(Vector3.new(-0.999730,0.000058,0.023217).Unit,0.778854),
 },
}
