local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local config=require(RS.Config:WaitForChild("SizeChangeConfig"))
local remote=RS.Remotes:WaitForChild("SizeChangeRequest")
local gui=Instance.new("ScreenGui");gui.Name="SizeChangeGui";gui.ResetOnSpawn=false;gui.DisplayOrder=35;gui.IgnoreGuiInset=false;gui.Parent=player:WaitForChild("PlayerGui")
local icon=Instance.new("ImageButton");icon.Name="SizeButton";icon.Image="rbxassetid://102391895593726";icon.BackgroundColor3=Color3.fromRGB(75,54,125);icon.Size=UDim2.fromOffset(48,48);icon.Position=UDim2.fromOffset(12,70);icon.Visible=false;icon.AutoButtonColor=true;icon.Parent=gui
Instance.new("UICorner",icon).CornerRadius=UDim.new(.2,0)
local panel=Instance.new("Frame");panel.Name="SizePanel";panel.BackgroundColor3=Color3.fromRGB(31,24,55);panel.Size=UDim2.fromOffset(220,330);panel.Position=UDim2.fromOffset(68,70);panel.Visible=false;panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
local padding=Instance.new("UIPadding",panel);padding.PaddingTop=UDim.new(0,10);padding.PaddingBottom=UDim.new(0,10);padding.PaddingLeft=UDim.new(0,10);padding.PaddingRight=UDim.new(0,10)
local layout=Instance.new("UIGridLayout",panel);layout.CellSize=UDim2.fromOffset(94,46);layout.CellPadding=UDim2.fromOffset(8,6);layout.SortOrder=Enum.SortOrder.LayoutOrder
local buttons={};local pending=false
local function refresh()
 local unlocked=(tonumber(player:GetAttribute("RebirthCount")) or 0)>=config.RequiredRebirth
 icon.Visible=unlocked;if not unlocked then panel.Visible=false end
 local selected=tonumber(player:GetAttribute("SelectedSizeTier")) or 0
 for tier,button in pairs(buttons) do button.BackgroundColor3=tier==selected and Color3.fromRGB(255,184,54) or Color3.fromRGB(95,68,154) end
end
for tier=0,10 do
 local button=Instance.new("TextButton");button.Name=tier==0 and "AUTO" or "SIZE"..tier;button.Text=tier==0 and "AUTO" or "SIZE "..tier;button.AutoLocalize=false;button.TextColor3=Color3.new(1,1,1);button.TextScaled=true;button.Font=Enum.Font.GothamBold;button.LayoutOrder=tier;button.Parent=panel;Instance.new("UICorner",button).CornerRadius=UDim.new(0,8);buttons[tier]=button
 button.Activated:Connect(function() if pending then return end;pending=true;remote:FireServer(tier) end)
end
local status=Instance.new("TextLabel");status.Name="Status";status.AutoLocalize=false;status.Text="";status.TextColor3=Color3.fromRGB(255,220,90);status.BackgroundTransparency=1;status.Size=UDim2.fromOffset(196,38);status.LayoutOrder=20;status.TextWrapped=true;status.TextScaled=true;status.Parent=panel
icon.Activated:Connect(function() panel.Visible=not panel.Visible end)
remote.OnClientEvent:Connect(function(result) pending=false;if typeof(result)~="table" then return end
 if result.Code=="NotEnoughWin" then status.Text="NOT ENOUGH WIN (500)" elseif result.Code=="Success" then status.Text=result.Tier==0 and "AUTO" or "SIZE "..tostring(result.Tier) elseif result.Code=="SameSize" then status.Text="SELECTED" elseif result.Code=="Busy" then status.Text="PLEASE WAIT" else status.Text="CHANGE FAILED" end;refresh()
end)
player:GetAttributeChangedSignal("RebirthCount"):Connect(refresh);player:GetAttributeChangedSignal("SelectedSizeTier"):Connect(refresh);refresh()
local strengthGui=player.PlayerGui:WaitForChild("StrengthGui")
RunService.RenderStepped:Connect(function()
 local left=strengthGui:FindFirstChild("HUD") and strengthGui.HUD:FindFirstChild("LeftHUD")
 if not left then return end
 local p,s=left.AbsolutePosition,left.AbsoluteSize
 local x=math.clamp(p.X,8,math.max(8,gui.AbsoluteSize.X-56))
 local y=math.clamp(p.Y+s.Y+8,8,math.max(8,gui.AbsoluteSize.Y-56))
 icon.Position=UDim2.fromOffset(x,y)
 local panelX=math.clamp(x+56,8,math.max(8,gui.AbsoluteSize.X-panel.AbsoluteSize.X-8))
 local panelY=math.clamp(y,8,math.max(8,gui.AbsoluteSize.Y-panel.AbsoluteSize.Y-8))
 panel.Position=UDim2.fromOffset(panelX,panelY)
end)
