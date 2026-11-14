local M={}
M.NORMAL_SCALE=Vector3.one
M.LEVEL_THRESHOLDS={2,4,8,16,32,50,70,90,115,140}
M.MAX_STAGE=#M.LEVEL_THRESHOLDS
M.UPPER_ARM_SCALES={1.40,1.75,2.05,2.30,2.50,2.60,2.68,2.74,2.78,2.80}
M.MUSCLE_GROWTH_FACTORS={}
for stage,scale in ipairs(M.UPPER_ARM_SCALES) do
 M.MUSCLE_GROWTH_FACTORS[stage]=(scale-1)/0.15
end
M.HEIGHT_SCALES={1.20,1.38,1.54,1.68,1.80,1.88,1.93,1.97,1.99,2.00}
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
function M.GetMuscleStage(level)
 if typeof(level)~="number" or level~=level or level==math.huge or level==-math.huge then return 0 end
 local stage=0
 for index,threshold in ipairs(M.LEVEL_THRESHOLDS) do
  if level<threshold then break end
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
