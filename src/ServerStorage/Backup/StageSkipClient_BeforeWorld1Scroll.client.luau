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
local open=player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui"):WaitForChild("LeftMenu"):WaitForChild("SkipButton")
local panel=Instance.new("Frame")
panel.Name="Panel" panel.BackgroundColor3=Color3.fromRGB(25,29,38)
panel.BorderSizePixel=0 panel.Visible=false panel.Parent=gui
local title=text("TextLabel","Title",panel,UDim2.new(1,-62,0,40),UDim2.fromOffset(12,0),"Stage Skip")
title.BackgroundTransparency=1 title.TextXAlignment=Enum.TextXAlignment.Left title.TextSize=20
local close=text("TextButton","CloseButton",panel,UDim2.fromOffset(34,30),UDim2.new(1,-42,0,5),"X")
local list=Instance.new("ScrollingFrame")
list.Name="Stages" list.Position=UDim2.fromOffset(10,46) list.Size=UDim2.new(1,-20,1,-90)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=5
list.CanvasSize=UDim2.fromOffset(0,9*54) list.Parent=panel
local layout=Instance.new("UIListLayout") layout.Padding=UDim.new(0,6) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=list
local status=text("TextLabel","Status",panel,UDim2.new(1,-20,0,36),UDim2.new(0,10,1,-38),"Choose a Stage for this Run")
status.BackgroundTransparency=1 status.TextWrapped=true status.TextSize=13
local pending=false
local function request(action,stage)
 if pending then return end
 pending=true
 status.Text="Processing..."
 remote:FireServer(action,stage)
end
for stage=2,10 do
 local entry=Config.Get(stage)
 local row=Instance.new("Frame")
 row.Name="Stage"..stage row.Size=UDim2.new(1,-7,0,48) row.BackgroundTransparency=1 row.LayoutOrder=stage row.Parent=list
 local name=text("TextLabel","StageLabel",row,UDim2.new(.23,0,1,0),UDim2.new(),"Stage "..stage)
 name.BackgroundTransparency=1 name.TextXAlignment=Enum.TextXAlignment.Left
 local win=text("TextButton","WinButton",row,UDim2.new(.37,-4,1,0),UDim2.new(.23,0,0,0),"Winで開始\n"..entry.RequiredWin.." Win")
 win.BackgroundColor3=Color3.fromRGB(57,76,53)
 local robux=text("TextButton","RobuxButton",row,UDim2.new(.4,-4,1,0),UDim2.new(.60,0,0,0),"Robuxで開始\n"..entry.RobuxPrice.." R$")
 robux.BackgroundColor3=Color3.fromRGB(49,64,93)
 win.Activated:Connect(function() request("Win",stage) end)
 robux.Activated:Connect(function() request("Robux",stage) end)
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
 if view.X<700 then
  panel.AnchorPoint=Vector2.zero
  panel.Position=UDim2.fromOffset(16,184)
  panel.Size=UDim2.fromOffset(math.max(240,view.X-32),math.max(130,view.Y-210))
 else
  panel.AnchorPoint=Vector2.new(1,0)
  panel.Position=UDim2.new(1,-16,0,16)
  panel.Size=UDim2.fromOffset(420,math.min(580,view.Y-52))
 end
end)
