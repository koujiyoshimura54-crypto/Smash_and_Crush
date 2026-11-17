-- Display only. Item prices, gains, exhibit height and handheld models are separate.
return table.freeze({
 SizeMultiplier=2, -- Uniform label/text size relative to the original numeric display.
 TemplateSize=UDim2.fromScale(9,9), -- Base canvas before the size multiplier.
 ValueWidth=.95, ExhibitValueHeight=1.26, TemplateValueHeight=.14,
 Font=Enum.Font.FredokaOne,
 Color=Color3.fromRGB(255,157,36),
 OutlineColor=Color3.fromRGB(47,24,8),
 OutlineThickness=2,
 MaxTextSize=64,
 MinTextSize=1, -- Allow long abbreviated values to fit the existing label bounds.
})
