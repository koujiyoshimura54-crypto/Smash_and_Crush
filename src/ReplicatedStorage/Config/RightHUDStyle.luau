-- Right-side entry UI only. Reference: 小さくなった英語購入バナー.png
-- The adopted image already includes the 70% reduction; do not reduce again.
return table.freeze({
 RewardSizeRatio=1/3, RewardMinTouch=44, RewardGap=12, RewardRight=12,
 BadgeDesignSize=24, BadgeImageScale=1.5, BadgeMaxRotation=10,
 BannerWidth=225, BannerHeight=80, BannerGap=50,
 BannerTopRatio=245/905, BannerRightRatio=38/1738,
 BannerMinScale=.68, BannerMaxScale=1.05,
 PriceHeight=26, PriceGap=5,
 Font=Enum.Font.FredokaOne, TextColor=Color3.new(1,1,1),
 OutlineColor=Color3.fromRGB(15,9,3), Border=5, TextStroke=3,
 Gold={Color3.fromRGB(255,245,137),Color3.fromRGB(255,186,30),Color3.fromRGB(230,137,5)},
 Rainbow={Color3.fromRGB(255,84,79),Color3.fromRGB(255,222,57),Color3.fromRGB(110,235,100),Color3.fromRGB(72,181,255),Color3.fromRGB(207,99,255)},
})
