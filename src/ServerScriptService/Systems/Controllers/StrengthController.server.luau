local Players=game:GetService("Players")
local StrengthManager=require(game.ServerScriptService.Services:WaitForChild("StrengthManager"))
local connections=setmetatable({}, {__mode="k"})
local function setup(player)
 StrengthManager.InitializePlayer(player)
 StrengthManager.UpdateLevel(player)
 if not connections[player] then
  connections[player]=player:GetAttributeChangedSignal("Strength"):Connect(function()
   StrengthManager.UpdateLevel(player)
  end)
 end
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player) connections[player]=nil end)
for _,player in Players:GetPlayers() do setup(player) end
