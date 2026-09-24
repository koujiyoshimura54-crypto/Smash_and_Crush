local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Config:WaitForChild("WorldPassConfig"))
local player=Players.LocalPlayer
local gui=script.Parent
local button=gui:WaitForChild("DoubleWinButton")
local badge=button:WaitForChild("OwnedBadge")
local remote=RS.Remotes:WaitForChild("World1DoubleWinPrompt")
local isWorld1=Config.GetWorld(game.PlaceId)=="World1"
gui.Enabled=isWorld1
local function refresh()
 local owned=player:GetAttribute("HasWorld1DoubleWin")==true
 badge.Visible=owned
 button.AutoButtonColor=not owned
 button.ImageColor3=owned and Color3.fromRGB(150,150,150) or Color3.new(1,1,1)
 button.Active=not owned
end
player:GetAttributeChangedSignal("HasWorld1DoubleWin"):Connect(refresh)
button.Activated:Connect(function()
 if isWorld1 and player:GetAttribute("HasWorld1DoubleWin")~=true then remote:FireServer("Prompt") end
end)
refresh()
