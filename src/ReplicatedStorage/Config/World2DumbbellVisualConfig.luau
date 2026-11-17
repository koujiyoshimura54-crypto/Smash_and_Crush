-- World2 geometry only. Exact ItemIds are independent of World1 grades.
-- Change these values then start a NEW Play/server (ModuleScript require cache).
-- Template: child of ServerStorage.World2DumbbellModels. Lengths/offsets: studs.
-- Rotation vectors: local-axis degrees. GripOffset: hand-local grip correction.
-- HeldLength=2 controls bar-axis width. Extra thickness affects Y/Z only;
-- the existing BodyPrototype overall scale is applied separately, from a fresh clone.
local items={
 W2_NORMAL_01={
  Template="W2_NORMAL_01",SourceUUID="be9de5d1-da96-4257-b9fa-0e9cfc268e96",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_02={
  Template="W2_NORMAL_02",SourceUUID="699aff5d-dfc7-47af-8c04-3d2fc97fbd2d",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_03={
  Template="W2_NORMAL_03",SourceUUID="c29ae88b-713b-40c8-a674-7cc619ae9784",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_04={
  Template="W2_NORMAL_04",SourceUUID="325c88e5-35ce-4599-abbc-d6add5edffa0",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_05={
  Template="W2_NORMAL_05",SourceUUID="129491e9-6098-49c1-85c7-bb7dda049030",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_06={
  Template="W2_NORMAL_06",SourceUUID="15b4b34a-ee7b-4724-a23d-840821ad4b01",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_07={
  Template="W2_NORMAL_07",SourceUUID="6f4d6c73-89cb-4430-a575-6c6cdf56fdd4",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_08={
  Template="W2_NORMAL_08",SourceUUID="c0336e3e-4fa8-4e1b-8c0d-8ec6e1aa5dc5",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_09={
  Template="W2_NORMAL_09",SourceUUID="1d5bb350-b333-46b5-97b0-f61929c85f98",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_10={
  Template="W2_NORMAL_10",SourceUUID="45523401-b6e5-40be-886e-87653b1ca616",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_11={
  Template="W2_NORMAL_11",SourceUUID="850c42fe-67c0-4846-9611-d1d1e7b1c6c0",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
 W2_NORMAL_12={
  Template="W2_NORMAL_12",SourceUUID="1f4b4e93-389d-433a-a119-495af875a4b4",
  DisplayLength=7.2,DisplayRotation=Vector3.zero,DisplayOffset=Vector3.new(0,4,0),
  HeldLength=2,HeldThicknessMultiplier=1,HeldRotation=Vector3.zero,GripOffset=Vector3.zero,
 },
}
for _,row in items do table.freeze(row)end
return table.freeze({
 Items=table.freeze(items),LibraryName="World2DumbbellModels",ExhibitName="World2DumbbellExhibit",
 -- Compact text block above the actual model top; sizes/gap are studs.
 ExhibitLabel=table.freeze({Width=9,Height=2.25,Gap=0.6}),
 BodyThickness=table.freeze({BaseHeightRatio=1,FullHeightRatio=2,MaxMultiplier=1.5}),
 HandOffset=Vector3.new(0,-0.15,0),
})
