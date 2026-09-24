-- World1 completion unlocks this gate; travel remains deliberately unconnected.
return table.freeze({
 GateName="World2Gate",
 CompletionStage=10,
 RequiredWorld=2,
 Title="WORLD 2",
 LockedText="LOCKED\nClear World 1",
 UnlockedText="ENTER",
 Locked=table.freeze({Color=Color3.fromRGB(91,73,60),Material=Enum.Material.SmoothPlastic,Transparency=0.12,TextColor=Color3.fromRGB(255,239,208)}),
 Unlocked=table.freeze({Color=Color3.fromRGB(180,123,52),Material=Enum.Material.Neon,Transparency=0.22,TextColor=Color3.fromRGB(49,28,16)}),
})
