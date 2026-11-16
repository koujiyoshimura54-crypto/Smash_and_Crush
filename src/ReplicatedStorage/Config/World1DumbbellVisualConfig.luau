-- Visuals only; no item economy, equipment, or save data lives here.
-- Edit values here, then start a NEW Play/server to reload this ModuleScript.
-- Template is a child of ServerStorage.World1DumbbellModels.
-- Lengths/offsets are studs. Rotations are degrees in the model/hand local frame.
-- HeldLength keeps the 2-stud bar-axis width. HeldThicknessMultiplier=1
-- preserves the source cross-section; thickness tuning never changes local X.
-- BodyThickness adds nothing at/below normal height; at double height it reaches
-- MaxMultiplier. Existing character/body scale remains separate and unchanged.
-- GripOffset adjusts the handle center relative to the hand, after body scaling.
local items = {
 NORMAL_01 = {
  Template="NORMAL_01", SourceUUID="a88c0024-1595-4271-9fcd-431e840fcf95",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_02 = {
  Template="NORMAL_02", SourceUUID="fb3a75b8-70a5-4f8e-a943-4361a85dfb47",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_03 = {
  Template="NORMAL_03", SourceUUID="5f42bf33-1673-4cd7-b611-3f092cae80b1",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_04 = {
  Template="NORMAL_04", SourceUUID="e2eea638-64b6-4800-8c5d-ab57ca813c8a",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_05 = {
  Template="NORMAL_05", SourceUUID="existing",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_06 = {
  Template="NORMAL_06", SourceUUID="4a01d4c0-a254-4af4-86fa-1f599ed18a73",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_07 = {
  Template="NORMAL_07", SourceUUID="664a0906-864b-4752-9f22-be7769f00df7",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_08 = {
  Template="NORMAL_08", SourceUUID="4a3ad0b8-f756-4462-a3d9-f8bebf800217",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_09 = {
  Template="NORMAL_09", SourceUUID="1d429733-b5b6-48b1-9b48-f9d08a9de8b7",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_10 = {
  Template="NORMAL_10", SourceUUID="9d34e00c-6acc-46d0-9e54-e2b0bdca123d",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_11 = {
  Template="NORMAL_11", SourceUUID="8cee376d-7bdb-4d1a-92c3-234c25a0206e",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
 NORMAL_12 = {
  Template="NORMAL_12", SourceUUID="3267a786-95a1-4f0e-88e0-2fdc600b8f98",
  DisplayLength=4.8, DisplayRotation=Vector3.new(0,0,0), DisplayOffset=Vector3.new(0,8.4,0),
  HeldLength=2, HeldThicknessMultiplier=1, HeldRotation=Vector3.new(0,0,0), GripOffset=Vector3.new(0,0,0),
 },
}
for _,row in items do table.freeze(row) end
return table.freeze({
 Items=table.freeze(items),
 LibraryName="World1DumbbellModels",
 ExhibitName="World1DumbbellExhibit",
 BodyThickness=table.freeze({BaseHeightRatio=1,FullHeightRatio=2,MaxMultiplier=1.5}),
 HandOffset=Vector3.new(0,-0.15,0), -- Existing non-prototype hand-center offset.
})
