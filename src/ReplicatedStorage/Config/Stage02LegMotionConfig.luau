-- World1 Stage2 Tralalero only; 1.0 restores the original leg motion.
return {
 Amplitude=1.5,
 RigName="TralaleroTralalaRig",
 WalkAnimationId="rbxassetid://85312619327964",
 -- Time-weighted cycle centers from this Walk's 41 keys, before model scaling.
 -- Despite their names, Arms.* are the two front legs; .002 are independent shoes.
 -- UpTorso.007 is the independent rear shoe. Do not change the body or float weld.
 Joints={
  {Path={"UpTorso","Arms.L"},Center=CFrame.identity},
  {Path={"UpTorso","Arms.L","Arms.L.001"},Center=CFrame.new(0.000000000,0.000000000,0.000000000)*CFrame.fromAxisAngle(Vector3.new(-0.966805357,-0.254215436,0.025727700).Unit,0.026177698)},
  {Path={"Arms.L.002"},Center=CFrame.new(0.012852301,-0.041203021,0.050266190)*CFrame.fromAxisAngle(Vector3.new(-0.970206328,-0.005191288,0.242224550).Unit,0.026234171),Translate=true},
  {Path={"UpTorso","Arms.R"},Center=CFrame.identity},
  {Path={"UpTorso","Arms.R","Arms.R.001"},Center=CFrame.new(0.000000000,0.000000000,0.000000000)*CFrame.fromAxisAngle(Vector3.new(-0.966805357,0.254215436,-0.025727700).Unit,0.026177697)},
  {Path={"Arms.R.002"},Center=CFrame.new(-0.012864921,-0.041205891,0.050267517)*CFrame.fromAxisAngle(Vector3.new(-0.970206330,0.005191293,-0.242224541).Unit,0.026234144),Translate=true},
  {Path={"UpTorso.007"},Center=CFrame.new(0.000510288,0.000618861,0.017982938),Translate=true},
 },
}
