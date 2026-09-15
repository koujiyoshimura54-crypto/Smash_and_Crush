local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(RS.Config:WaitForChild("StageSkipConfig"))
local MarketplacePrice=require(RS.Modules:WaitForChild("MarketplacePrice"))
local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("StageSkip")
-- Bind the StarterGui copy without overriding authored visual properties.
local playerGui=player:WaitForChild("PlayerGui")
local gui=playerGui:WaitForChild("StageSkipGui")
local panel=gui:WaitForChild("Panel")
local close=panel:WaitForChild("CloseButton")
local list=panel:WaitForChild("Stages")
local status=panel:WaitForChild("Status")
local open=playerGui:WaitForChild("StrengthGui"):WaitForChild("LeftMenu"):WaitForChild("SkipButton")
panel.Visible=false
local pending=false
local function request(action,stage)
 if pending then return end
 pending=true
 status.Text="Processing..."
 remote:FireServer(action,stage)
end
for stage=2,10 do
 local entry=Config.Get(stage)
 local row=list:WaitForChild("Stage"..stage)
 row:WaitForChild("StageLabel").Text="Stage "..stage
 local win=row:WaitForChild("WinButton")
 local robux=row:WaitForChild("RobuxButton")
 win:WaitForChild("Price").Text=tostring(entry.RequiredWin)
 robux:WaitForChild("Price").Text=tostring(entry.FallbackPrice)
 task.spawn(function()
  local price,source=MarketplacePrice.Get(entry.ProductId,Enum.InfoType.Product,entry.FallbackPrice)
  MarketplacePrice.Apply(robux.Price,price,source)
  robux:SetAttribute("PriceSource",source)
 end)
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
end)

