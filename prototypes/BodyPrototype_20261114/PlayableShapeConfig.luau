-- Prototype-only proportions; never writes to the normal MuscleScaleConfig.
local C = {}
C.Progress = {0, 0.20, 0.36, 0.50, 0.62, 0.72, 0.80, 0.87, 0.925, 0.97, 1}
C.Shapes = {
 UpperTorso = {Vector3.new(0.30,0.38,0.24), Vector3.new(0.60,0.62,0.55)},
 LowerTorso = {Vector3.new(0.32,0.38,0.30), Vector3.new(0.52,0.62,0.48)},
 UpperArm = {Vector3.new(0.16,0.32,0.16), Vector3.new(0.48,0.52,0.45)},
 LowerArm = {Vector3.new(0.18,0.35,0.18), Vector3.new(0.41,0.57,0.39)},
 Hand = {Vector3.new(0.42,0.36,0.38), Vector3.new(0.60,0.50,0.54)},
 UpperLeg = {Vector3.new(0.25,0.42,0.25), Vector3.new(0.50,0.65,0.47)},
 LowerLeg = {Vector3.new(0.27,0.43,0.27), Vector3.new(0.46,0.63,0.44)},
 Foot = {Vector3.new(0.50,0.43,0.48), Vector3.new(0.65,0.60,0.65)},
 HumanoidRootPart = {Vector3.new(0.40,0.40,0.40), Vector3.new(0.50,0.62,0.50)},
}
function C.GetScale(name, stage)
 local key = name:gsub("^Left", ""):gsub("^Right", "")
 local endpoints = C.Shapes[key]
 if not endpoints then return Vector3.one end
 return endpoints[1]:Lerp(endpoints[2], C.Progress[stage+1] or 0)
end
function C.GetDumbbellScale(stage)
 return 0.50 + 0.25 * (C.Progress[stage+1] or 0)
end
return C
