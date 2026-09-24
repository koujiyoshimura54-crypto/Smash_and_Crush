local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(RS.Config:WaitForChild("StageSkipConfig"))
local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("StageSkip")
local gui=Instance.new("ScreenGui")
gui.Name="StageSkipGui"
gui.ResetOnSpawn=false
gui.DisplayOrder=30
gui.Parent=player:WaitForChild("PlayerGui")
local function text(class,name,parent,size,position,label)
 local x=Instance.new(class)
 x.Name=name x.Size=size x.Position=position
 x.BackgroundColor3=Color3.fromRGB(40,47,60)
 x.TextColor3=Color3.new(1,1,1)
 x.BorderSizePixel=0 x.Font=Enum.Font.GothamMedium x.TextSize=14 x.Text=label
 x.Parent=parent
 return x
end
local function style(object,color,radius)
 object.BackgroundColor3=color object.BorderSizePixel=0
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,radius or 12) corner.Parent=object
 local stroke=Instance.new("UIStroke") stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border stroke.Color=Color3.fromRGB(24,15,30) stroke.Thickness=3 stroke.Parent=object
end
local function image(parent,name,id,position,size)
 local icon=Instance.new("ImageLabel") icon.Name=name icon.Image=id icon.BackgroundTransparency=1
 icon.Position=position icon.Size=size icon.ScaleType=Enum.ScaleType.Fit icon.ZIndex=parent.ZIndex+1 icon.Parent=parent
 return icon
end
local function studs(parent,transparency)
 local pattern=image(parent,"StudPattern","rbxassetid://111868739606818",UDim2.new(),UDim2.fromScale(1,1))
 pattern.ZIndex=parent.ZIndex pattern.ScaleType=Enum.ScaleType.Tile pattern.TileSize=UDim2.fromOffset(48,48) pattern.ImageTransparency=transparency
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,12) corner.Parent=pattern
end
local function scaled(label,maxSize)
 label.Font=Enum.Font.GothamBlack label.TextScaled=true
 local limit=Instance.new("UITextSizeConstraint") limit.MinTextSize=10 limit.MaxTextSize=maxSize limit.Parent=label
end
local open=player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui"):WaitForChild("LeftMenu"):WaitForChild("SkipButton")
local panel=Instance.new("Frame")
panel.Name="Panel" panel.BackgroundColor3=Color3.fromRGB(25,29,38)
panel.BorderSizePixel=0 panel.Visible=false panel.Parent=gui
style(panel,Color3.fromRGB(164,79,218),16)
studs(panel,.84)
local title=text("TextLabel","Title",panel,UDim2.new(1,-82,0,48),UDim2.fromOffset(18,8),"WORLD 1 SKIP")
title.BackgroundTransparency=1 title.TextXAlignment=Enum.TextXAlignment.Left title.ZIndex=2 scaled(title,30)
local close=text("TextButton","CloseButton",panel,UDim2.fromOffset(38,38),UDim2.new(1,-50,0,12),"X")
close.ZIndex=3 style(close,Color3.fromRGB(235,48,83),9) scaled(close,28)
local list=Instance.new("ScrollingFrame")
list.Name="Stages" list.Position=UDim2.fromOffset(12,68) list.Size=UDim2.new(1,-24,1,-116)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=8
list.ScrollBarImageColor3=Color3.fromRGB(255,225,93)
list.ScrollingDirection=Enum.ScrollingDirection.Y list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.new() list.ClipsDescendants=true list.ZIndex=2 list.Parent=panel
local padding=Instance.new("UIPadding") padding.PaddingTop=UDim.new(0,4) padding.PaddingBottom=UDim.new(0,4) padding.PaddingLeft=UDim.new(0,4) padding.PaddingRight=UDim.new(0,14) padding.Parent=list
local layout=Instance.new("UIListLayout") layout.Name="StageListLayout" layout.Padding=UDim.new(0,12) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=list
local status=text("TextLabel","Status",panel,UDim2.new(1,-28,0,32),UDim2.new(0,14,1,-40),"Choose a Stage for this Run")
status.BackgroundTransparency=1 status.TextWrapped=true status.ZIndex=2 scaled(status,16)
local pending=false
local function request(action,stage)
 if pending then return end
 pending=true
 status.Text="Processing..."
 remote:FireServer(action,stage)
end
local rows={}
local function priceButton(row,name,price,asset,x,color)
 local button=text("TextButton",name,row,UDim2.new(.31,-8,.72,0),UDim2.fromScale(x,.14),"")
 button.ZIndex=4 style(button,color,10)
 image(button,"CurrencyIcon",asset,UDim2.fromScale(.06,.18),UDim2.fromScale(.3,.64))
 local value=text("TextLabel","Price",button,UDim2.fromScale(.58,.8),UDim2.fromScale(.38,.1),tostring(price))
 value.BackgroundTransparency=1 value.ZIndex=5 scaled(value,28)
 return button
end
for stage=2,10 do
 local entry=Config.Get(stage)
 local row=Instance.new("Frame")
 row.Name="Stage"..stage row.Size=UDim2.new(1,0,0,88) row.LayoutOrder=stage row.ZIndex=2 row.Parent=list
 row:SetAttribute("World",1) row:SetAttribute("Stage",stage)
 style(row,stage%2==0 and Color3.fromRGB(116,58,190) or Color3.fromRGB(136,65,205),12) studs(row,.9)
 local name=text("TextLabel","StageLabel",row,UDim2.new(.36,-12,1,-12),UDim2.fromOffset(12,6),"Stage "..stage)
 name.BackgroundTransparency=1 name.TextXAlignment=Enum.TextXAlignment.Left name.ZIndex=3 scaled(name,30)
 local win=priceButton(row,"WinButton",entry.RequiredWin,"rbxassetid://106494459783367",.37,Color3.fromRGB(255,200,53))
 local robux=priceButton(row,"RobuxButton",entry.RobuxPrice,"rbxasset://textures/ui/common/robux.png",.68,Color3.fromRGB(39,181,239))
 win.Activated:Connect(function() request("Win",stage) end)
 robux.Activated:Connect(function() request("Robux",stage) end)
 table.insert(rows,row)
end
open.Activated:Connect(function()
 if not Config.IsInLobby(player.Character) then return end
 panel.Visible=not panel.Visible
 if panel.Visible then status.Text="Choose a Stage for this Run" end
end)
close.Activated:Connect(function() panel.Visible=false end)
remote.OnClientEvent:Connect(function(result)
 pending=false
 status.Text=result.Message or ""
 if result.Success and not result.ProductId then panel.Visible=false end
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.2 then return end
 elapsed=0
 local inLobby=Config.IsInLobby(player.Character)
 -- Keep all three shared menu cards visible; preserve the lobby restriction.
 open.Active=inLobby
 if not inLobby then panel.Visible=false end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local view=gui.AbsoluteSize
 panel.AnchorPoint=Vector2.new(.5,.5)
 panel.Position=UDim2.fromScale(.5,.5)
 panel.Size=UDim2.fromOffset(math.min(660,math.max(240,view.X-28)),math.min(610,math.max(180,view.Y-28)))
 local rowHeight=view.X<450 and 76 or 88
 for _,row in ipairs(rows) do row.Size=UDim2.new(1,0,0,rowHeight) end
end)
