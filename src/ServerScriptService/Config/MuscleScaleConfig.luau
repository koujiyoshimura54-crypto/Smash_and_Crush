local M={}
M.NORMAL_SCALE=Vector3.one
M.MUSCLE_THRESHOLDS={40,250,955,2840,7215,37315,196915,462965,30000000,150000000,700000000,2000000000,6000000000}
M.MAX_STAGE=#M.MUSCLE_THRESHOLDS
M.UPPER_ARM_SCALES={1.30,1.45,1.525,1.60,1.675,1.825,1.975,2.05,2.20,2.35,2.50,2.65,2.80}
M.MUSCLE_GROWTH_FACTORS={}
for stage,scale in ipairs(M.UPPER_ARM_SCALES) do
 M.MUSCLE_GROWTH_FACTORS[stage]=(scale-1)/0.15
end
M.HEIGHT_SCALES={1.10,1.175,1.25,1.35,1.45,1.70,2.00,2.15,2.40,2.65,2.95,3.25,3.55}
M.PART_SCALE_KEYS={
 UpperTorso="UpperTorso",LowerTorso="LowerTorso",
 LeftUpperArm="UpperArm",RightUpperArm="UpperArm",
 LeftLowerArm="LowerArm",RightLowerArm="LowerArm",
 LeftUpperLeg="UpperLeg",RightUpperLeg="UpperLeg",
 LeftLowerLeg="LowerLeg",RightLowerLeg="LowerLeg",
}
M.MUSCLE1_GROWTH={
 UpperTorso=Vector3.new(0.12,0,0.10),
 UpperArm=Vector3.new(0.15,0,0.15),
 LowerArm=Vector3.new(0.08,0,0.08),
 LowerTorso=Vector3.new(0.05,0,0.05),
 HeightOnly=Vector3.zero,
}
M.MUSCLE1_GROWTH.UpperLeg=M.MUSCLE1_GROWTH.UpperTorso*0.75
M.MUSCLE1_GROWTH.LowerLeg=M.MUSCLE1_GROWTH.UpperTorso*0.60
function M.GetMuscleStage(strength)
 if typeof(strength)~="number" then return 0 end
 local stage=0
 for index,threshold in ipairs(M.MUSCLE_THRESHOLDS) do
  if strength<threshold then break end
  stage=index
 end
 return stage
end
function M.GetHeightScale(stage)
 return M.HEIGHT_SCALES[stage] or 1
end
function M.GetPartScale(partName,stage)
 local key=M.PART_SCALE_KEYS[partName]
 local growth=key and M.MUSCLE1_GROWTH[key]
 local factor=M.MUSCLE_GROWTH_FACTORS[stage]
 if not growth or not factor then return M.NORMAL_SCALE end
 return Vector3.new(1+growth.X*factor,M.GetHeightScale(stage),1+growth.Z*factor)
end
return M
