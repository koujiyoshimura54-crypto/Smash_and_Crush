-- Existing trophy unlock and local gate appearance; World3 remains unavailable.
return table.freeze({
 GateName="World2Gate",
 ContactInterval=.1, ContactPadding=.3, ExitPadding=.9, ExitDelay=.2,
 Worlds=table.freeze({
  table.freeze({Id=1,Name="World 1",Ready=true}),
  table.freeze({Id=2,Name="World 2",Ready=true}),
  -- Connect an official destination/unlock in WorldGateService before enabling.
  table.freeze({Id=3,Name="World 3",Ready=false}),
 }),
 CompletionStage=10,
 RequiredWorld=2,
 Title="WORLD 2",
 LockedText="LOCKED\nClear World 1",
 UnlockedText="ENTER",
 Locked=table.freeze({Color=Color3.fromRGB(91,73,60),Material=Enum.Material.SmoothPlastic,Transparency=0.12,TextColor=Color3.fromRGB(255,239,208)}),
 Unlocked=table.freeze({Color=Color3.fromRGB(180,123,52),Material=Enum.Material.Neon,Transparency=0.22,TextColor=Color3.fromRGB(49,28,16)}),
})
