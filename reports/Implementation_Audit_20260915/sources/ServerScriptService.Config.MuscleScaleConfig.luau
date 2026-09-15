local M={}
M.NORMAL_SCALE=Vector3.one
M.MUSCLE_THRESHOLDS={30,70,130,250,490,970,1930,3850,7690,15370}
M.MUSCLE_GROWTH_FACTORS={4,7,9,10,11,12,13,14,15,16}
M.HEIGHT_SCALES={1.20,1.35,1.50,1.70,1.90,2.15,2.40,2.70,3.00,3.50}
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

