-- Purchased Chill Octopus entrance, Phase 2 display only.
-- No purchased Data, GamePass prompt, equip Remote, receipt or reward path.
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local Input=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Janitor=require(RS.Packages.Janitor)
local Config=require(RS.Config.LimitedEggConfig)
local Viewport=require(RS.Modules.LimitedPetViewport)
local M={}
local lifetime=Janitor.new()
local sheet=Janitor.new()
local active=nil
local started=false
local promptConnection=nil
local boundPrompt=nil

local function stripScripts(root)
 for _,x in root:GetDescendants() do if x:IsA("LuaSourceContainer") then x:Destroy() end end
end
local function label(donor,parent,name,text,position,size)
 local x=donor:Clone();x.Name=name;x.Parent=parent
 x.Text=text;x.AutoLocalize=false;x.AnchorPoint=Vector2.zero
 x.Position=position;x.Size=size;x.Visible=true;x.TextScaled=true;x.ZIndex=5
 return x
end
local function setBoard(price)
 local model=workspace:FindFirstChild(Config.Entrance)
 if not model then return end
 local board=model:FindFirstChild("BillboardGui")
 if board then
  board.Adornee=model.PrimaryPart
  local title=board:FindFirstChild("AlwaysBetter")
  if title then title.Text=Config.Name;title.AutoLocalize=false end
  local amount=board:FindFirstChild("Price")
  if amount then amount.Text=string.format("%g Robux / 1 Pet",price);amount.AutoLocalize=false end
 end
end
function M.close()
 active=nil
 sheet:Cleanup()
end

function M.show(parent,fetchPrice)
 if active and active.Parent==parent then return active end
 M.close()
 local gui=Instance.new("ScreenGui")
 gui.Name="LimitedEgg01Gui";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true
 gui.DisplayOrder=1000;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 sheet:Add(gui,"Destroy")
 local ok,err=xpcall(function()
  local original=RS.Assets.Templates.OpenEgg
  local purchased=game.StarterGui.ScreenGui.Menus
  local panel=original.Background:Clone();panel.Name="Background";stripScripts(panel)
  panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
  panel.Size=UDim2.fromOffset(700,550);panel.Visible=true;panel.Parent=gui
  local scale=Instance.new("UIScale");scale.Parent=panel
  local function fit()
   local size=gui.AbsoluteSize
   scale.Scale=math.min(1,math.max(1,size.X-24)/700,math.max(1,size.Y-24)/550)
  end
  sheet:Add(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
  local info=panel.Info
  info.Text=Config.Name;info.AutoLocalize=false;info.TextScaled=true
  info.AnchorPoint=Vector2.zero;info.Position=UDim2.fromOffset(60,16);info.Size=UDim2.fromOffset(580,44)
  local pets=panel.Pets
  for _,x in pets:GetChildren() do if x:IsA("UIGridStyleLayout") then x:Destroy() end end
  local seventh=pets["6"]:Clone();seventh.Name="7";seventh.Parent=pets
  local nameDonor=RS.Assets.Templates.PetInventory.Title
  for i,entry in Config.Entries do
   local card=pets[tostring(i)]
   card.Image="";card.Visible=true;card.AnchorPoint=Vector2.zero
   local column=(i-1)%4;local row=math.floor((i-1)/4)
   card.Position=UDim2.fromOffset(22+column*164+(row==1 and 82 or 0),78+row*178)
   card.Size=UDim2.fromOffset(156,172);card.ClipsDescendants=true;card.ZIndex=2
   local aspect=card:FindFirstChildOfClass("UIAspectRatioConstraint") if aspect then aspect:Destroy() end
   local button=card:FindFirstChild("Button")
   if button then button.Active=false;button.Interactable=false;button.Selectable=false;button.Visible=false end
   local percent=card.Percent
   percent.Text=string.format("%g%%",entry.Percent);percent.AutoLocalize=false
   percent.AnchorPoint=Vector2.zero;percent.Position=UDim2.fromOffset(4,148);percent.Size=UDim2.fromOffset(148,23)
   percent.TextScaled=true;percent.ZIndex=5;percent.TextXAlignment=Enum.TextXAlignment.Center
   local petName=label(nameDonor,card,"PetName",entry.Name,UDim2.fromOffset(4,124),UDim2.fromOffset(148,23))
   petName.TextXAlignment=Enum.TextXAlignment.Center
   -- Keep the purchased candidate container and its Percent child.
   local cleanup,view=Viewport.mount(card,entry.Name)
   view.Size=UDim2.new(1,0,0,122);sheet:Add(cleanup,true)
  end
  local opens=original.Opens:Clone();opens.Name="Opens";stripScripts(opens)
  for _,x in opens:GetChildren() do x:Destroy() end
  opens.AnchorPoint=Vector2.zero;opens.Position=UDim2.fromOffset(0,452);opens.Size=UDim2.fromOffset(700,88)
  opens.Parent=panel
  local buy=purchased.RestockShop.Main.Common.BuyRobux:Clone()
  buy.Name="Open1";stripScripts(buy);buy.AnchorPoint=Vector2.new(.5,0)
  buy.Position=UDim2.new(.5,0,0,0);buy.Size=UDim2.fromOffset(230,48);buy.Parent=opens
  buy.Main.Amount.Text=string.format("\u{E002} %g",Config.BasePrice);buy.Main.Amount.AutoLocalize=false
  for _,x in buy:GetDescendants() do
   if x:IsA("GuiButton") then x.Active=false;x.Interactable=false;x.Selectable=false;x.AutoButtonColor=false end
  end
  -- Intentionally no Activated handler and no purchase API in this module.
  label(nameDonor,opens,"Availability","1 Pet - Purchases unavailable",UDim2.fromOffset(75,58),UDim2.fromOffset(550,22))
  local close=purchased.Inventory.Exit:Clone();close.Name="Close";stripScripts(close)
  close.AnchorPoint=Vector2.zero;close.Position=UDim2.new(1,-56,0,14);close.Size=UDim2.fromOffset(42,42);close.Parent=panel
  sheet:Add(close.Button.Activated:Connect(M.close))
  sheet:Add(Input.InputBegan:Connect(function(input,processed)
   if not processed and input.KeyCode==Enum.KeyCode.Escape then M.close() end
  end))
  gui.Parent=parent;active=gui;fit()
  if Players.LocalPlayer then
  -- Proximity monitoring exists only while the candidate sheet is open.
  sheet:Add(RunService.Heartbeat:Connect(function()
  if not active then return end
  local player=Players.LocalPlayer;local character=player and player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local entrance=workspace:FindFirstChild(Config.Entrance)
  local part=entrance and entrance.PrimaryPart
  if not root or not part or (root.Position-part.Position).Magnitude>24 then M.close() end
 end))
  end
  sheet:Add(gui.Destroying:Connect(function() if active==gui then task.defer(M.close) end end))
  if fetchPrice~=false then task.spawn(function()
   local success,product=pcall(function() return Marketplace:GetProductInfoAsync(Config.ProductId,Enum.InfoType.Product) end)
   if active~=gui or not gui.Parent then return end
   if success and type(product)=="table" and type(product.PriceInRobux)=="number" then
    buy.Main.Amount.Text=string.format("\u{E002} %g",product.PriceInRobux)
    gui:SetAttribute("PriceSource","Marketplace");setBoard(product.PriceInRobux)
   else gui:SetAttribute("PriceSource","BasePrice") end
  end) end
 end,debug.traceback)
 if not ok then M.close();error(err) end
 return gui
end

local function bind(prompt)
 if prompt==boundPrompt then return end
 if promptConnection then promptConnection:Disconnect() end
 boundPrompt=prompt
 prompt.ActionText="View Pets";prompt.ObjectText=Config.Name
 prompt.AutoLocalize=false;setBoard(Config.BasePrice)
 promptConnection=prompt.Triggered:Connect(function(player)
  local localPlayer=Players.LocalPlayer
  if not localPlayer or (player and player~=localPlayer) then return end
  M.show(localPlayer:WaitForChild("PlayerGui"))
 end)
end
function M.stop()
 M.close();lifetime:Cleanup()
 if promptConnection then promptConnection:Disconnect();promptConnection=nil end
 boundPrompt=nil;started=false
end
function M.start()
 if started then return end started=true
 local function consider(x)
  if x:IsA("ProximityPrompt") and x.Parent and x.Parent.Name==Config.Entrance and x.Parent.Parent==workspace then bind(x) end
 end
 local model=workspace:FindFirstChild(Config.Entrance)
 if model then local prompt=model:FindFirstChild("ProximityPrompt") if prompt then consider(prompt) end end
 lifetime:Add(workspace.DescendantAdded:Connect(consider))
 lifetime:Add(workspace.DescendantRemoving:Connect(function(x)
  if x==boundPrompt then
   if promptConnection then promptConnection:Disconnect();promptConnection=nil end
   boundPrompt=nil;M.close()
  end
 end))

end
return M
