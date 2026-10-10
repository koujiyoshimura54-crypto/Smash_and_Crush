-- Purchased Chill Octopus entry; server-authorized Developer Product prompts only.
-- Purchase completion only unlocks. Saved receipt notices invoke the existing Hatch.
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
local generation=0
local promptConnection=nil
local boundPrompt=nil
local requestRemote
local function boundedCall(callback)
 local done,ok,value=false,false,nil
 task.spawn(function()
  local success,result=pcall(callback)
  if not done then ok=success;value=result;done=true end
 end)
 local deadline=os.clock()+15
 while not done and os.clock()<deadline do task.wait(.05) end
 if not done then done=true;return false,"RequestTimeout" end
 return ok,value
end
local purchaseBusy=false
local priceReady=false
local offeredVersion
local buyControl,availability
local unavailableReason="Loading price and eligibility..."
local transientMessage
local messages={
 LocalStudioUnsupported="Open the published Cloud place to check purchases",
 ServerUnavailable="Purchase server unavailable. Reopen to retry.",RequestTimeout="Purchase request timed out. Reopen to retry.",
 SessionOwnershipLost="Player session unavailable. Rejoin to retry.",PetModelUnavailable="Pet display unavailable",OfferChanged="Offer changed. Reopen to retry.",
 PaidRandomRestricted="Unavailable in your region",PolicyUnavailable="Eligibility unavailable. Reopen to retry.",
 PriceUnavailable="Price unavailable. Reopen to retry.",WrongExperience="Unavailable in this experience",
 ProductAssociationUnavailable="Product unavailable",DataNotLoaded="Player data is loading",
 DataSaving="Saving pets. Please wait.",PurchaseBusy="Purchase prompt already open",
 PromptFailed="Purchase prompt failed. Please try again.",TooFarFromEgg="Move closer to Limited Egg 01",
 PleaseWait="Please wait, then try again.",PurchasesUnavailable="Purchases unavailable",
}
local function updatePurchaseUI()
 if not buyControl or not availability then return end
 local enabled=priceReady and not purchaseBusy and offeredVersion==Config.RollVersion
 -- Keep input connected so a denied click can explain its reason; M.purchase gates prompting.
 buyControl.Active=true;buyControl.Interactable=true;buyControl.Selectable=true;buyControl.AutoButtonColor=enabled
 buyControl:SetAttribute("PurchaseAllowed",enabled)
 availability.Text=purchaseBusy and "Waiting for purchase confirmation..." or (priceReady and (transientMessage or "1 Pet") or unavailableReason)
end
function M.purchase()
 print("[LimitedEgg01] click",priceReady,purchaseBusy,requestRemote~=nil)
 if purchaseBusy or not priceReady or not active or not requestRemote then
  updatePurchaseUI();warn("[LimitedEgg01] blocked: "..(purchaseBusy and "PurchaseBusy" or unavailableReason))
  return false,"Unavailable"
 end
 purchaseBusy=true;updatePurchaseUI()
 local ok,response=boundedCall(function() return requestRemote:InvokeServer("Purchase",offeredVersion) end)
 if not ok or type(response)~="table" or not response.ok then
  purchaseBusy=false
  local reason=ok and type(response)=="table" and response.reason or (response=="RequestTimeout" and "RequestTimeout" or "PromptFailed")
  warn("[LimitedEgg01] purchase rejected: "..tostring(reason))
  unavailableReason=messages[reason] or "Purchase unavailable. Reopen to retry."
  local blocked=reason=="PolicyUnavailable" or reason=="PaidRandomRestricted" or reason=="PriceUnavailable"
   or reason=="WrongExperience" or reason=="ProductAssociationUnavailable" or reason=="PurchasesUnavailable"
  if blocked then priceReady=false end
  transientMessage=unavailableReason;updatePurchaseUI()
  -- Failure/cancellation never awards a Pet or starts a Hatch.
  return false,reason
 end
 print("[LimitedEgg01] prompt request accepted")
 return true
end
local function acknowledge(id)
 for _=1,5 do
  if not started or not requestRemote or not Players.LocalPlayer or not Players.LocalPlayer.Parent then return end
  local ok,response=boundedCall(function() return requestRemote:InvokeServer("Acknowledge",id) end)
  if ok and type(response)=="table" and response.ok then return end
  task.wait(1)
 end
end

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
  if amount then amount.Text=price and string.format("%g Robux / 1 Pet",price) or "Unavailable / 1 Pet";amount.AutoLocalize=false end
 end
end
function M.close()
 active=nil
 buyControl=nil;availability=nil;priceReady=false;offeredVersion=nil;transientMessage=nil
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
  buy.Main.Amount.Text="--";buy.Main.Amount.AutoLocalize=false
  for _,x in buy:GetDescendants() do
   if x:IsA("GuiButton") then x.Active=false;x.Interactable=false;x.Selectable=false;x.AutoButtonColor=false end
  end
  buyControl=buy.Button
  availability=label(nameDonor,opens,"Availability","Loading price and eligibility...",UDim2.fromOffset(75,58),UDim2.fromOffset(550,22))
  buyControl.Visible=true;buyControl.ZIndex=200
  sheet:Add(buyControl.Activated:Connect(M.purchase))
  print("[LimitedEgg01] button connected",buyControl:GetFullName())
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
  priceReady=false;offeredVersion=nil;unavailableReason="Loading price and eligibility...";updatePurchaseUI()
  if fetchPrice~=false then task.spawn(function()
   local success,product=boundedCall(function() return Marketplace:GetProductInfoAsync(Config.ProductId,Enum.InfoType.Product) end)
   local offered,offer=boundedCall(function()
    local deadline=os.clock()+10
    while not requestRemote and started and active==gui and os.clock()<deadline do task.wait(.05) end
    if not requestRemote then return {ok=false,reason="ServerUnavailable"} end
    return requestRemote:InvokeServer("Offer")
   end)
   if active~=gui or not gui.Parent then return end
   local valid=success and type(product)=="table" and product.ProductId==Config.ProductId and product.IsForSale==true
    and type(product.PriceInRobux)=="number" and product.PriceInRobux>0 and product.PriceInRobux<math.huge
   if valid then
    buy.Main.Amount.Text=string.format("\u{E002} %g",product.PriceInRobux)
    gui:SetAttribute("PriceSource","Marketplace");setBoard(product.PriceInRobux)
   else gui:SetAttribute("PriceSource","Unavailable");setBoard(nil) end
   if valid and offered and type(offer)=="table" and offer.ok and offer.ProductId==Config.ProductId
    and offer.TableVersion==Config.RollVersion then
    priceReady=true;offeredVersion=offer.TableVersion
   else
    local reason=not valid and "PriceUnavailable" or (offered and type(offer)=="table" and offer.reason or "PurchasesUnavailable")
    unavailableReason=messages[reason] or "Purchase unavailable. Reopen to retry."
   end
   print("[LimitedEgg01] offer",priceReady,priceReady and "Allowed" or unavailableReason)
   updatePurchaseUI()
  end) else
   unavailableReason="Purchases unavailable";updatePurchaseUI()
  end
 end,debug.traceback)
 if not ok then M.close();error(err) end
 return gui
end

local function bind(prompt)
 if prompt==boundPrompt then return end
 if promptConnection then promptConnection:Disconnect() end
 boundPrompt=prompt
 prompt.ActionText="View Pets";prompt.ObjectText=Config.Name
 prompt.AutoLocalize=false;setBoard(nil)
 promptConnection=prompt.Triggered:Connect(function(player)
  local localPlayer=Players.LocalPlayer
  if not localPlayer or (player and player~=localPlayer) then return end
  M.show(localPlayer:WaitForChild("PlayerGui"))
 end)
end
function M.stop()
 M.close();lifetime:Cleanup()
 if promptConnection then promptConnection:Disconnect();promptConnection=nil end
 boundPrompt=nil;started=false;generation+=1;requestRemote=nil
end
function M.start()
 if started then return end started=true;generation+=1
 local currentGeneration=generation
 lifetime:Add(Marketplace.PromptProductPurchaseFinished:Connect(function(userId,productId)
  local player=Players.LocalPlayer
  if player and userId==player.UserId and productId==Config.ProductId then
   purchaseBusy=false;transientMessage=nil;updatePurchaseUI()
  end
 end))
 task.spawn(function()
  if not Players.LocalPlayer then return end
  local remotes=RS:WaitForChild("Remotes",10)
  local folder=remotes and remotes:WaitForChild("GameRemotes",10)
  local request=folder and folder:WaitForChild("LimitedEggPurchase",10)
  local notice=folder and folder:WaitForChild("LimitedEggCommitted",10)
  if not started or generation~=currentGeneration then return end
  if not request or not request:IsA("RemoteFunction") or not notice or not notice:IsA("RemoteEvent") then
   unavailableReason=messages.ServerUnavailable;updatePurchaseUI();warn("[LimitedEgg01] remotes unavailable");return
  end
  print("[LimitedEgg01] client remotes ready",game.PlaceId)
  requestRemote=request
  lifetime:Add(notice.OnClientEvent:Connect(function(result)
   local ok,accepted,reason=pcall(function()
    if type(result)~="table" or result.Saved~=true or result.Status~="Granted" then return false,"NotCommitted" end
    M.close()
    return require(script.Parent.HatchClient).playCommittedLimited(result)
   end)
   task.spawn(function() require(script.Parent.PetClient).refresh() end)
   if ok and (accepted or reason=="AlreadyShown") then task.spawn(acknowledge,result.PurchaseId)
   elseif not ok then warn("Limited Egg presentation failed; saved Pet retained: "..tostring(accepted)) end
  end))
  boundedCall(function() return request:InvokeServer("Ready") end)
 end)
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
