local RS=game:GetService("ReplicatedStorage")
local S=require(RS.Config.RewardedStrengthBoostStyle)
local C=require(RS.Config.RewardedStrengthBoostConfig)
local M={}
local function make(class,name,parent,props)
	local o=Instance.new(class);o.Name=name
	for k,v in pairs(props or {}) do o[k]=v end
	o.Parent=parent;return o
end
local function border(o,thickness,radius)
	make("UIStroke","Outline",o,{Color=Color3.new(),Thickness=thickness,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	if radius then make("UICorner","Corner",o,{CornerRadius=UDim.new(0,radius)}) end
end
local function label(parent,name,text,size,color,position,extent)
	local t=make("TextLabel",name,parent,{BackgroundTransparency=1,Text=text,Font=S.Font,TextSize=size,
		TextColor3=color,TextWrapped=false,Position=position,Size=extent,ZIndex=parent.ZIndex+1})
	make("UIStroke","TextOutline",t,{Color=Color3.new(),Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	return t
end
local function icon(parent,name,size,top)
	return make("ImageLabel",name,parent,{BackgroundTransparency=1,Image=S.ArmImage,ScaleType=Enum.ScaleType.Fit,
		AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,top),Size=UDim2.fromOffset(size,size),ZIndex=parent.ZIndex+1})
end
function M.Build(parent,refresh)
	local existing=parent:FindFirstChild("RewardedStrengthBoostGui")
	if existing and refresh then existing:Destroy();existing=nil end -- This module's own GUI only, once per Mount.
	if existing then return existing end
	local g=make("ScreenGui","RewardedStrengthBoostGui",parent,{ResetOnSpawn=false,DisplayOrder=S.DisplayOrder,
		ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	local e=S.Entry
	local entry=make("TextButton","Entry",g,{Text="",BackgroundTransparency=1,AutoButtonColor=false,
		Visible=false,Size=UDim2.fromOffset(e.Width,e.Height)})
	make("UIScale","Fit",entry,{Scale=1})
	label(entry,"Title",("×%g Strength"):format(1+C.TrainingBonus),e.TitleSize,S.White,UDim2.new(),UDim2.new(1,0,0,34))
	icon(entry,"Arm",e.IconSize,e.IconTop)
	label(entry,"Footer","FREE",e.FooterSize,S.Green,UDim2.new(0,0,1,-34),UDim2.new(1,0,0,34))
	local overlay=make("Frame","Overlay",g,{Visible=false,Active=true,BackgroundColor3=Color3.new(),BackgroundTransparency=.6,Size=UDim2.fromScale(1,1),ZIndex=10})
	local m=S.Modal
	local p=make("Frame","Panel",overlay,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromOffset(m.Width,m.Height),BackgroundColor3=S.PanelColor,BackgroundTransparency=S.PanelTransparency,ZIndex=11})
	border(p,m.Border,m.Radius);make("UIScale","Fit",p,{Scale=1})
	label(p,"Title","FREE BOOST",m.TitleSize,S.White,UDim2.fromOffset(12,m.TitleTop),UDim2.new(1,-24,0,m.TitleHeight))
	icon(p,"Arm",m.IconSize,m.IconTop)
	label(p,"Subtitle",("×%g Strength · %g MIN"):format(1+C.TrainingBonus,C.DurationSeconds/60),m.SubtitleSize,S.Yellow,UDim2.new(0,10,0,m.SubtitleTop),UDim2.new(1,-20,0,m.SubtitleHeight))
	local watch=make("TextButton","Watch",p,{Text="",BackgroundColor3=S.Green,AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,m.ButtonTop),Size=UDim2.fromOffset(m.ButtonWidth,m.ButtonHeight),ZIndex=12})
	border(watch,4,12)
	label(watch,"Title","WATCH AD",m.ButtonTextSize,S.White,UDim2.new(),UDim2.fromScale(1,1))
	local close=make("TextButton","Close",p,{Text="",BackgroundColor3=S.Red,AnchorPoint=Vector2.new(1,0),
		Position=UDim2.new(1,m.CloseInset,0,-m.CloseInset),Size=UDim2.fromOffset(m.CloseSize,m.CloseSize),ZIndex=14})
	border(close,4,10);label(close,"Title","X",40,S.White,UDim2.new(),UDim2.fromScale(1,1))
	return g
end
function M.Layout(g,leftBounds)
	local viewport=g.AbsoluteSize;local e,m=S.Entry,S.Modal
	local scale=math.clamp(math.min(viewport.X/1200,viewport.Y/700),e.MinScale,e.MaxScale)
	local right=leftBounds and leftBounds.Right or 302*scale
	local x=math.clamp(right+e.LeftGap,8,math.max(8,viewport.X-e.Width*scale-8))
	local y=e.Top
	for _=1,3 do for _,r in ipairs(leftBounds and leftBounds.Blocks or {}) do
		if x<r.X+r.W+6 and x+e.Width*scale>r.X-6 and y<r.Y+r.H+6 and y+e.Height*scale>r.Y-6 then y=r.Y+r.H+8 end
	end end
	g.Entry.Position=UDim2.fromOffset(x,y);g.Entry.Fit.Scale=scale
	local modalScale=math.max(.05,math.min(1,(viewport.X-2*m.Edge)/m.Width,(viewport.Y-2*m.Edge)/m.Height))
	g.Overlay.Panel.Fit.Scale=modalScale
	local closeSize=math.max(m.CloseSize,math.ceil(45/modalScale))
	g.Overlay.Panel.Close.Size=UDim2.fromOffset(closeSize,closeSize)
end
function M.Time(expires,now)
	local s=math.max(0,math.ceil(expires-now))
	return string.format("%02d:%02d",math.floor(s/60),s%60)
end
function M.BuildShop(holder,refresh)
	local old=holder:FindFirstChild("StrengthBoostProduct")
	if old and refresh then assert(old:GetAttribute("PurchaseKey")=="StrengthBoost");old:Destroy();old=nil end
	if old then return old end
	local template=holder:FindFirstChild("CardWin")
	if not template then return nil end
	local card=template:Clone();card.Name="StrengthBoostProduct"
	-- Display clone only: do not inherit scripts, old navigation or overlapping legacy Benefits labels.
	local keptBenefits
	for _,x in ipairs(card:GetDescendants()) do
		if x:IsA("LuaSourceContainer") or x.Name=="ResponsiveHitbox" then x:Destroy()
		elseif x.Name=="Benefits" and x:IsA("TextLabel") then
			if keptBenefits then x:Destroy() else keptBenefits=x end
		end
	end
	-- ShopProduct is excluded by EssentialStudShopClient's legacy generic purchase binder.
	card:SetAttribute("PurchaseKind","ShopProduct");card:SetAttribute("PurchaseKey","StrengthBoost");card:SetAttribute("ShopFeatured",false)
	card.LayoutOrder=7;card.Title.Text=C.ProductName;card.Icon.Image=S.ArmImage
	card.Title.TextScaled=true
	if keptBenefits then keptBenefits.Text=("+%g training multiplier • %g min"):format(C.TrainingBonus,C.DurationSeconds/60);keptBenefits.TextScaled=true;keptBenefits.Visible=true end
	for _,name in {"Owned","Gift"} do local x=card:FindFirstChild(name);if x then x.Visible=false;x.Active=false end end
	local button=card.PurchaseArea.Purchase
	button.Active=false;button.PriceTag.Text="..."
	card.Parent=holder;return card
end
return M
