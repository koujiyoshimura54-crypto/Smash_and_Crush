local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local Shop=require(game.ServerScriptService.Services.ShopRewardService)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Config=require(RS.Config.ShopProductConfig)
local function remote(name,class)
 local r=RS.Remotes:FindFirstChild(name)
 if not r then r=Instance.new(class);r.Name=name;r.Parent=RS.Remotes end
 assert(r.ClassName==class);return r
end
local request=remote("ShopPurchaseRequest","RemoteEvent")
local state=remote("ShopRewardState","RemoteFunction")
local last=setmetatable({}, {__mode="k"})
local function publish(p,success,code)
 if p.Parent~=Players then return end
 request:FireClient(p,{Success=success,Code=code,State=Shop.GetState(p)})
 local aura=require(game.ServerScriptService.Services.AuraService)
 RS.Remotes.AuraPurchaseRequest:FireClient(p,{State={Loaded=Data.IsLoaded(p),OwnedAuras=aura.GetOwnedAuras(p) or {},EquippedAura=aura.GetEquippedAura(p) or ""}})
end
state.OnServerInvoke=function(p)return Shop.GetState(p)end
request.OnServerEvent:Connect(function(p,key)
 local now=os.clock()
 if last[p] and now-last[p]<.5 then return end
 last[p]=now
 local ok,code=Shop.Prompt(p,key)
 publish(p,ok,code)
end)
local function tag(p,character)
 local head=character:FindFirstChild("Head")
 if not head then return end
 local shopState=Shop.GetState(p)
 local owned=shopState.GamePassEffectsEnabled and shopState.Products.VIP.Owned
 local label=head:FindFirstChild("ShopVIPTag")
 if not owned then if label then label:Destroy() end;return end
 if not label then
  label=Instance.new("BillboardGui");label.Name="ShopVIPTag";label.Size=UDim2.fromOffset(100,28)
  label.StudsOffset=Vector3.new(0,3,0);label.MaxDistance=80;label.AlwaysOnTop=true
  local text=Instance.new("TextLabel");text.Name="Label";text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1
  text.Font=Enum.Font.GothamBold;text.TextSize=20;text.TextColor3=Config.Auras.VIP.Tint;text.TextStrokeTransparency=.3
  text.Parent=label;label.Parent=head
 end
 label.Label.Text=Config.Get("VIP").Tag
end
local function bind(p)
 p:GetAttributeChangedSignal("HasShopVIP"):Connect(function()if p.Character then tag(p,p.Character)end end)
 p.CharacterAdded:Connect(function(character)
  if character:WaitForChild("Head",10) and p.Character==character then tag(p,character)end
 end)
 task.spawn(function()
  while p.Parent==Players and not Data.IsLoaded(p) do task.wait(.25)end
  while p.Parent==Players do
   Shop.Refresh(p);publish(p)
   if p.Character then tag(p,p.Character)end
   task.wait(15)
  end
 end)
end
Marketplace.PromptGamePassPurchaseFinished:Connect(function(p,id,purchased)
 if not Config.ForPass(id) or not purchased then return end
 task.spawn(function()
  for attempt=1,5 do
   if p.Parent~=Players then return end
   Shop.Refresh(p);publish(p)
   local key=Config.ForPass(id);local state=Shop.GetState(p).Products[key]
   if state and state.Owned and state.Granted then return end
   task.wait(attempt)
  end
 end)
end)
Marketplace.PromptProductPurchaseFinished:Connect(function(userId)
 local p=Players:GetPlayerByUserId(userId)
 if p then publish(p)end
end)
Players.PlayerAdded:Connect(bind)
for _,p in ipairs(Players:GetPlayers())do bind(p)end
Players.PlayerRemoving:Connect(function(p)last[p]=nil end)
