-- Passive visuals. No remotes, rewards, purchases, notifications or menu control.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS.Config.OfflineRewardUIConfig)
local Style = require(RS.Config.StrengthHUDStyle)
local M = {}
local function make(class, name, parent, properties)
	local x = Instance.new(class); x.Name = name
	for k, v in pairs(properties or {}) do x[k] = v end
	x.Parent = parent; return x
end
local function rect(x, r)
	x.AnchorPoint = Vector2.zero
	x.Position = UDim2.fromOffset(r[1], r[2]); x.Size = UDim2.fromOffset(r[3], r[4])
end
local function stroke(x, size, color)
	return make("UIStroke", "Outline", x, {Color=color, Thickness=size,
		StrokeSizingMode=Enum.StrokeSizingMode.FixedSize})
end
local function label(parent, name, text, size, color)
	local x = make("TextLabel", name, parent, {BackgroundTransparency=1, Text=text,
		Font=Style.Font, TextSize=size, TextColor3=color, TextScaled=true, TextWrapped=false,
		AutoLocalize=false, Active=false, Interactable=false, Selectable=false, ZIndex=53})
	make("UITextSizeConstraint", "TextLimit", x, {MaxTextSize=size, MinTextSize=1})
	stroke(x, C.Exit.Stroke, C.Exit.StrokeColor)
	return x
end
function M.EnsureNotify(panel)
	local existing = panel:FindFirstChild("NotifyRow")
	if existing then M.StyleNotify(existing.Button);return existing.Button end
	local n = C.Notify
	local row = make("Frame", "NotifyRow", panel, {BackgroundTransparency=1, Visible=false,
		Active=false, ZIndex=52})
	local button = make("TextButton", "Button", row, {Text="", AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.fromScale(.5,0), Size=UDim2.fromOffset(n.Width,n.Height),
		BackgroundColor3=n.Color, BorderSizePixel=0, ZIndex=59, AutoButtonColor=true})
	make("UICorner", "Corner", button, {CornerRadius=UDim.new(0,n.Radius)})
	local edge=stroke(button,n.Stroke,n.StrokeColor); edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	local text=label(button,"Title","NOTIFY ME",n.TextSize,n.TextColor)
	text.Position=UDim2.fromScale(.23,.06);text.Size=UDim2.fromScale(.72,.88);text.ZIndex=60
	text.Outline.Thickness=1.5
	-- A native white bell silhouette: no uploaded icon, emoji or screenshot texture.
	local bell=make("Frame","Bell",button,{BackgroundTransparency=1,Position=UDim2.fromScale(.065,.22),Size=UDim2.fromScale(.12,.56),ZIndex=60})
	for _,part in ipairs({{"Top",.42,0,.16,.18},{"Dome",.2,.12,.6,.64},{"Rim",.07,.68,.86,.14},{"Clapper",.38,.81,.24,.18}}) do
		local f=make("Frame",part[1],bell,{BackgroundColor3=n.TextColor,BorderSizePixel=0,
			Position=UDim2.fromScale(part[2],part[3]),Size=UDim2.fromScale(part[4],part[5]),ZIndex=60})
		make("UICorner","Round",f,{CornerRadius=UDim.new(.5,0)})
	end
	M.StyleNotify(button)
	return button
end
function M.StyleNotify(button)
	local n=C.Notify
	button.BackgroundColor3=n.Color;button.Corner.CornerRadius=UDim.new(0,n.Radius)
	button.Outline.Color=n.StrokeColor;button.Outline.Thickness=n.Stroke
	button.Title.TextColor3=n.TextColor;button.Title.TextSize=n.TextSize;button.Title.TextLimit.MaxTextSize=n.TextSize
	for _,part in ipairs(button.Bell:GetChildren()) do if part:IsA("Frame") then part.BackgroundColor3=n.TextColor end end
end
function M.LayoutReward(panel, w, h)
	local o,n=Style.Offline,C.Notify
	local row=panel:FindFirstChild("NotifyRow")
	local widthFit=math.min(1,math.max(1,w-o.MarginX)/o.Width)
	local available=math.max(1,h-o.MarginY)
	local height,scale=o.Height,math.min(widthFit,available/o.Height)
	if row and row.Visible then
		local fixed=o.Height+n.Gap+n.BottomPadding
		scale=math.max(.05,math.min(widthFit,available/(fixed+n.Height),(available-n.MinTapPixels)/fixed))
		-- UDim offsets are integer pixels; round upward to retain the hit minimum.
		local buttonHeight=math.max(n.Height,math.ceil(n.MinTapPixels/scale))
		height=fixed+buttonHeight
		row.Position=UDim2.fromOffset(0,o.Height+n.Gap)
		row.Size=UDim2.fromOffset(o.Width,buttonHeight)
		row.Button.Size=UDim2.fromOffset(n.Width,buttonHeight)
	end
	panel.Size=UDim2.fromOffset(o.Width,height)
	panel.RewardScale.Scale=scale
end
function M.EnsureExit(parent, reward)
	local existing=parent:FindFirstChild("OfflineExitNotice")
	if existing then M.StyleExit(existing,reward);return existing end
	local e=C.Exit
	local gui=make("ScreenGui","OfflineExitNotice",parent,{Enabled=false,ResetOnSpawn=false,
		DisplayOrder=e.DisplayOrder,ScreenInsets=Enum.ScreenInsets.None,ClipToDeviceSafeArea=false,
		SafeAreaCompatibility=Enum.SafeAreaCompatibility.None,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	for _,name in ipairs({"TopBand","BottomBand"}) do
		local band=make("Frame",name,gui,{BackgroundColor3=e.BandColor,BackgroundTransparency=e.BandTransparency,
			BorderSizePixel=0,Active=false,Interactable=false,Selectable=false})
		label(band,"Text",name=="TopBand" and "DON’T GO YET!" or "EARN STRENGTH WHILE YOU’RE AWAY!",
			name=="TopBand" and e.TopTextSize or e.BottomTextSize,e.TextColor)
	end
	local center=make("Frame","Center",gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromOffset(e.Width,e.Height),BackgroundColor3=reward.BackgroundColor3,
		BackgroundTransparency=reward.BackgroundTransparency,BorderSizePixel=0,Active=false,Interactable=false})
	for _,name in ipairs({"Corner","Border"}) do
		local source=reward:FindFirstChild(name); if source then source:Clone().Parent=center end
	end
	make("UIScale","Fit",center)
	for _,item in ipairs({{"Title","DON’T GO YET!",e.Title,e.TitleSize,e.TextColor},
		{"Subtitle","Earn Strength while you’re away!",e.Subtitle,e.SubtitleSize,Color3.new(1,1,1)},
		{"Caption","OFFLINE REWARDS",e.Caption,e.CaptionSize,e.TextColor}}) do
		rect(label(center,item[1],item[2],item[4],item[5]),item[3])
	end
	-- Clone only passive artwork, never the claim/receipt LocalScript or buttons.
	for _,name in ipairs({"StrengthHalo","StrengthIcon"}) do
		local source=reward:FindFirstChild(name)
		if source then
			local x=source:Clone();x.Parent=center;rect(x,name=="StrengthIcon" and e.Icon or e.Halo)
			for _,d in ipairs(x:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then d:Destroy()
				elseif d:IsA("GuiObject") then d.Active=false;d.Interactable=false;d.Selectable=false end
			end
			x.Active=false;x.Interactable=false;x.Selectable=false
		end
	end
	M.StyleExit(gui,reward)
	return gui
end
function M.StyleExit(gui,reward)
	local e=C.Exit
	gui.DisplayOrder=e.DisplayOrder
	local function text(x,size,color)
		x.Font=Style.Font;x.TextSize=size;x.TextLimit.MaxTextSize=size;x.TextColor3=color
		x.Outline.Thickness=e.Stroke;x.Outline.Color=e.StrokeColor
	end
	for _,name in ipairs({"TopBand","BottomBand"}) do
		local band=gui[name];band.BackgroundColor3=e.BandColor;band.BackgroundTransparency=e.BandTransparency
		text(band.Text,name=="TopBand" and e.TopTextSize or e.BottomTextSize,e.TextColor)
	end
	local center=gui.Center;center.Size=UDim2.fromOffset(e.Width,e.Height)
	center.BackgroundColor3=reward.BackgroundColor3;center.BackgroundTransparency=reward.BackgroundTransparency
	text(center.Title,e.TitleSize,e.TextColor);rect(center.Title,e.Title)
	text(center.Subtitle,e.SubtitleSize,Color3.new(1,1,1));rect(center.Subtitle,e.Subtitle)
	text(center.Caption,e.CaptionSize,e.TextColor);rect(center.Caption,e.Caption)
	if center:FindFirstChild("StrengthIcon") then rect(center.StrengthIcon,e.Icon) end
	if center:FindFirstChild("StrengthHalo") then rect(center.StrengthHalo,e.Halo) end
end
function M.LayoutExit(gui, size, safe)
	local e=C.Exit
	local w,h=size.X,size.Y
	local top=math.max(0,safe.Min.Y);local bottom=math.max(0,h-safe.Max.Y)
	local bandHeight=math.clamp(h*e.BandHeightScale,e.BandMinHeight,e.BandMaxHeight)
	local a,b=gui.TopBand,gui.BottomBand
	a.Position=UDim2.fromOffset(0,0);a.Size=UDim2.fromOffset(w,top+bandHeight)
	b.Position=UDim2.fromOffset(0,h-bottom-bandHeight);b.Size=UDim2.fromOffset(w,bottom+bandHeight)
	local textW=math.max(1,safe.Width-2*e.SafeMargin)
	a.Text.Position=UDim2.fromOffset(safe.Min.X+e.SafeMargin,top)
	b.Text.Position=UDim2.fromOffset(safe.Min.X+e.SafeMargin,0)
	a.Text.Size=UDim2.fromOffset(textW,bandHeight);b.Text.Size=a.Text.Size
	local center=gui.Center
	center.Position=UDim2.fromOffset((safe.Min.X+safe.Max.X)/2,(safe.Min.Y+safe.Max.Y)/2)
	center.Fit.Scale=math.max(.05,math.min(1,(safe.Width-2*e.CenterMargin)/e.Width,
		(safe.Height-2*bandHeight-2*e.CenterMargin)/e.Height))
end
return M
