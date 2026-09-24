local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Config=require(RS.Config:WaitForChild("RebirthConfig"))
local MultiplierConfig=require(RS.Config:WaitForChild("RebirthMultiplierConfig"))
local request=RS.Remotes:WaitForChild("RebirthRequest")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local button=menu:WaitForChild("RebirthButton")
local badge=button:WaitForChild("ReadyBadge")
-- Visuals are authored in StarterGui.StrengthGui.RebirthPanel.
local panel=gui:WaitForChild("RebirthPanel")
local top=panel:WaitForChild("Top")
local holder=panel:WaitForChild("Holder")
local current=holder:WaitForChild("CurrentCard")
local after=holder:WaitForChild("AfterCard")
local progress=panel:WaitForChild("RebirthProgress")
local rebirth=panel:WaitForChild("RebirthConfirmButton")
local fill=panel:WaitForChild("RebirthLevelBar"):WaitForChild("Fill")
local close=top:WaitForChild("Close")
panel.Visible=false

local function level() return tonumber(player:GetAttribute("Level")) or 1 end
local function count() return math.max(0,math.floor(tonumber(player:GetAttribute("RebirthCount")) or 0)) end
local function multiplier(n) return MultiplierConfig.GetMultiplier(n) end
local function refresh()
 local value=level()
 local n=count()
 local maxed=Config.IsWorld1Max(n)
 local req=Config.GetRequiredLevel(n)
 local can=not maxed and req~=nil and value>=req
 badge.Visible=can
 fill.Size=UDim2.fromScale((maxed or can) and 1 or (req and req>0 and math.clamp(value/req,0,1) or 0),1)
 progress.Text=maxed and "WORLD 1 MAX" or ("REQUIRED LEVEL  Lv %s  •  Lv %d / %s"):format(tostring(req or "N/A"),value,tostring(req or "N/A"))
 local cr=current:FindFirstChild("RewardText",true)
 local ar=after:FindFirstChild("RewardText",true)
 if cr then cr.Text=("x%.1f"):format(multiplier(n)) end
 if ar then ar.Text=maxed and "MAX" or ("x%.1f"):format(multiplier(n+1)) end
 local label=rebirth:FindFirstChild("TextLabel",true)
 if label then label.Text=maxed and "MAX" or "REBIRTH!" end
 rebirth.Interactable=can
 rebirth.Active=can
 rebirth.AutoButtonColor=can
end
button.Activated:Connect(function() panel.Visible=not panel.Visible; refresh() end)
close.Activated:Connect(function() panel.Visible=false end)
rebirth.Activated:Connect(function()
 refresh()
 if rebirth.Active then request:FireServer("Request") end
end)
request.OnClientEvent:Connect(function(d)
 if d.Type=="Success" then panel.Visible=true; refresh()
 elseif d.Type=="Denied" then panel.Visible=true; refresh() end
end)
player:GetAttributeChangedSignal("Level"):Connect(refresh)
player:GetAttributeChangedSignal("RebirthCount"):Connect(refresh)
refresh()