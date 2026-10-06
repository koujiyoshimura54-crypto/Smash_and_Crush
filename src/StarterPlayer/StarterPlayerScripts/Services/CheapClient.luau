-- Purchased Trophy presentation; only legacy GamePassService authorizes benefits.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local PromptService=game:GetService("ProximityPromptService")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(RS.Config:WaitForChild("WorldPassConfig"))
local Prices=require(RS.Modules:WaitForChild("MarketplacePrice"))
local player=Players.LocalPlayer
local remote=RS.Remotes:WaitForChild("World1DoubleWinPrompt")
local M={}
local started=false
local asking=false
local renderVersion=0
local function equipment()
 local model=workspace:FindFirstChild("Trophy")
 if not model or not model:IsA("Model") then return end
 local buy=model:FindFirstChild("Buy")
 local prompt=buy and buy:FindFirstChildWhichIsA("ProximityPrompt")
 return model,buy,prompt
end
local function refresh()
 renderVersion+=1
 local version=renderVersion
 local model,_,prompt=equipment()
 if not model or not prompt then return end
 local world=Config.GetWorld(game.PlaceId)
 local verified=player:GetAttribute("WinPassOwnershipVerified")==true
 local passId=Config.GetNextWinPassId(world,player:GetAttribute("HasWorld1DoubleWin")==true,player:GetAttribute("HasWorld1TripleWin")==true)
 local owned=world=="World1" and player:GetAttribute("HasWorld1TripleWin")==true
 local title=owned and "Owned" or (passId==Config.GetTripleWinPassId("World1") and "x3 Wins" or "x2 Wins")
 local busy=asking or player:GetAttribute("WinPassPromptBusy")==true
 prompt.ActionText=title
 prompt.ObjectText=owned and "" or "Buy"
 prompt.Enabled=world=="World1" and verified and passId~=nil and not busy
 local board=model:FindFirstChild("BillboardGui")
 if not board then return end
 board.Adornee=model:FindFirstChild("PartMain")
 local label=board:FindFirstChild("Text")
 local price=board:FindFirstChild("Price")
 if label and label:IsA("TextLabel") then label.Text=title end
 if not price or not price:IsA("TextLabel") then return end
 price.Text=owned and "" or "..."
 if owned or not passId then return end
 task.spawn(function()
  local amount,source=Prices.Get(passId,Enum.InfoType.GamePass,nil)
  if version~=renderVersion or not price.Parent then return end
  price:SetAttribute("PriceSource",source)
  price.Text=amount~=nil and ("ONLY "..utf8.char(0xE002)..tostring(amount).."!") or "Price unavailable"
 end)
end
function M.start()
 if started then return end
 started=true
 PromptService.PromptTriggered:Connect(function(prompt,who)
  local _,_,actual=equipment()
  if who~=player or prompt~=actual or asking or player:GetAttribute("WinPassPromptBusy")==true then return end
  if player:GetAttribute("WinPassOwnershipVerified")~=true or player:GetAttribute("HasWorld1TripleWin")==true then return end
  asking=true
  refresh()
  local ok=pcall(function() remote:FireServer("TrophyPrompt") end)
  if not ok then asking=false;refresh() end
  task.delay(5,function()
   if asking and player:GetAttribute("WinPassPromptBusy")~=true then asking=false;refresh() end
  end)
 end)
 PromptService.PromptShown:Connect(function(prompt)
  local _,_,actual=equipment()
  if prompt==actual then refresh() end
 end)
 remote.OnClientEvent:Connect(function(action,ok)
  if action~="WinPassPromptResult" then return end
  if not ok then asking=false;refresh() end
 end)
 Marketplace.PromptGamePassPurchaseFinished:Connect(function(who,id)
  if who~=player or (id~=Config.GetDoubleWinPassId("World1") and id~=Config.GetTripleWinPassId("World1")) then return end
  asking=false;refresh()
 end)
 for _,attribute in ipairs({"HasWorld1DoubleWin","HasWorld1TripleWin","WinPassOwnershipVerified","WinPassPromptBusy"}) do
  player:GetAttributeChangedSignal(attribute):Connect(function()
   if player:GetAttribute("WinPassPromptBusy")~=true then asking=false end
   refresh()
  end)
 end
 workspace.ChildAdded:Connect(function(child) if child.Name=="Trophy" then refresh() end end)
 refresh()
end
return M
