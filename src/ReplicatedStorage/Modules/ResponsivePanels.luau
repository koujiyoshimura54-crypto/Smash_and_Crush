-- Presentation-only responsive layout. No Config, data or Remote writes.
local RunService=game:GetService("RunService")
local HUD=require(script.Parent.HUDLayout)
local M={}
local bound=setmetatable({}, {__mode="k"})
-- Keep authored properties until the Instance is destroyed; engine-owned Instances
-- can lose weak Lua keys during collection even while still parented.
local originals={}
local function set(x,values,active)
 if not x then return end
 local saved=originals[x]
 if not saved then
  saved={};originals[x]=saved
  x.Destroying:Once(function()originals[x]=nil end)
 end
 for k,v in pairs(values) do
  if saved[k]==nil then saved[k]={x[k]} end
  if active then x[k]=v else x[k]=saved[k][1] end
 end
end
local function text(x,min,max)
 if not x then return end
 local limit=x:FindFirstChildOfClass("UITextSizeConstraint")
 if not limit then limit=Instance.new("UITextSizeConstraint");limit.Parent=x end
 set(limit,{MinTextSize=min,MaxTextSize=max},true)
 set(x,{TextScaled=true,TextWrapped=true},true)
end
local function aspect(x,w,h,active)
 local a=x:FindFirstChildOfClass("UIAspectRatioConstraint")
 if a then set(a,{AspectRatio=w/math.max(h,1)},active) end
end
function M.Small(gui)
 -- Touch controls require readable cards and tap targets even on a large tablet.
 -- Fit and HUD scales still depend on the available viewport, not device names.
 return gui.AbsoluteSize.X<1000 or gui.AbsoluteSize.Y<650 or #HUD.GetControls(gui.Parent)>0
end
function M.Fit(panel,gui)
 local d=panel:GetAttribute("ResponsiveDesignSize")
 if not d then return end
 local original=gui.AbsoluteSize
 local reserveTop=gui:GetAttribute("PanelReserveTop") or 0
 local reserveRight=gui:GetAttribute("PanelReserveRight") or 0
 local v=Vector2.new(original.X-reserveRight,original.Y-reserveTop)
 -- The authored design is the coordinate system. Never reshape its interior.
 local s=math.clamp(math.min(1,math.max(1,v.X-24)/d.X,math.max(1,v.Y-24)/d.Y),.05,1)
 local w,h=d.X,d.Y
 local u=panel:FindFirstChild("ResponsiveScale")
 if not u then u=Instance.new("UIScale");u.Name="ResponsiveScale";u.Parent=panel end
 u.Scale=s
 panel.Size=UDim2.fromOffset(w,h);panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromOffset(v.X/2,reserveTop+v.Y/2)
 aspect(panel,w,h,true)
 panel:SetAttribute("ResponsiveCompact",M.Small(gui))
end
local function header(panel,small,s)
 local top=panel:FindFirstChild("Top")
 if top then
  set(top,{AnchorPoint=Vector2.zero,Position=UDim2.new(),Size=UDim2.new(1,0,0,56/s)},small)
  local close=top:FindFirstChild("Close")
  if close then
   set(close,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8/s,0,6/s),Size=UDim2.fromOffset(44/s,44/s)},small)
   aspect(close,1,1,small)
  end
 end
end
local function inventory(panel,gui)
 local small=false -- Preserve authored geometry at every viewport.
 ;local s=panel.ResponsiveScale.Scale
 local short=gui.AbsoluteSize.Y<500
 set(panel.CloseButton,{Size=UDim2.fromOffset(44/s,44/s),Position=UDim2.new(1,-52/s,0,8/s)},small)
 set(panel.Title,{Position=UDim2.fromOffset(60/s,8/s),Size=UDim2.new(1,-116/s,0,40/s)},small)
 set(panel.InventoryTitleIcon,{Position=UDim2.fromOffset(16/s,12/s),Size=UDim2.fromOffset(32/s,32/s)},small)
 local tabs=panel.Tabs;local content=panel.Content
 set(tabs,{Position=UDim2.fromOffset(10/s,(short and 54 or 58)/s),Size=UDim2.new(1,-20/s,0,(short and 44 or 52)/s)},small)
 aspect(tabs,HUD.GetLocalSize(tabs).X,(short and 44 or 52)/s,small)
 set(content,{Position=UDim2.fromOffset(12/s,(short and 104 or 120)/s),Size=UDim2.new(1,-24/s,1,-(short and 116 or 132)/s)},small)
 for _,b in ipairs(tabs:GetChildren()) do if b:IsA("GuiButton") then
  local x={Dumbbells=0,Items=.24,Merge=.43,Aura=.62,Speed=.81}
  set(b,{Position=UDim2.new(x[b.Name] or 0,2/s,0,0),Size=UDim2.new(b.Name=="Dumbbells" and .24 or .19,-4/s,1,0)},small)
  local icon=b:FindFirstChild("Icon");local label=b:FindFirstChild("Label")
  set(icon,{Position=UDim2.new(.5,-10/s,0,3/s),Size=UDim2.fromOffset(20/s,20/s)},small)
  set(label,{Position=UDim2.fromOffset(2/s,(short and 20 or 24)/s),Size=UDim2.new(1,-4/s,0,(short and 22 or 26)/s)},small)
  if b.Name=="Dumbbells" then set(label,{Text="Dumbbell"},small) end
  if small then text(label,12/s,16/s) end
 end end
 -- Aura and Speed remain separate purchase flows; only the shared row geometry changes.
 for _,name in ipairs({"Aura","Speed"}) do
  local page=content[name];local list=page:FindFirstChild(name.."List")
  if list then for _,card in ipairs(list:GetChildren()) do if card:IsA("Frame") and card:FindFirstChild("BuyButton") then
   set(card,{Size=UDim2.new(1,0,0,126/s)},small)
   local button=card.BuyButton
   set(button,{Position=UDim2.new(.71,0,.5,-22/s),Size=UDim2.new(.29,-8/s,0,44/s)},small)
   local label=button:FindFirstChild("Label")
   local title=card:FindFirstChild("Title") or card:FindFirstChild("AuraName")
   set(title,{Size=UDim2.new(.40,-8/s,.45,0),Position=UDim2.new(.29,0,.12,0)},small)
   if small then
    if label then text(label,12/s,20/s) end
    text(title,13/s,20/s)
    local effect=card:FindFirstChild("StrengthBonus")
    if effect then text(effect,12/s,18/s) end
   end
  end end end
 end
end
local function rewards(panel,gui)
 local small=false -- Preserve authored geometry at every viewport.
 ;local s=panel.ResponsiveScale.Scale;local holder=panel.Holder
 header(panel,small,s)
 set(holder,{Position=UDim2.fromOffset(12/s,66/s),AnchorPoint=Vector2.zero,Size=UDim2.new(1,-24/s,1,-92/s)},small)
 aspect(holder,HUD.GetLocalSize(panel).X-24/s,HUD.GetLocalSize(panel).Y-92/s,small)
 local vip=panel.Name=="DailyRewardsPanel" and holder:FindFirstChild("VIPBonus")
 holder.ScrollingEnabled=small or vip~=nil;holder.ScrollBarThickness=(small or vip) and 5 or 0
 local cards={} for _,x in ipairs(holder:GetChildren()) do if x:IsA("Frame") then table.insert(cards,x) end end
 table.sort(cards,function(a,b)return a.Name<b.Name end)
 local width=HUD.GetLocalSize(holder).X
 local columns=math.max(1,math.floor((width*s+8)/160))
 local cw=(width-(columns-1)*10/s-8/s)/columns;local short=gui.AbsoluteSize.Y<500;local ch=(short and 180 or 212)/s
 for i,card in ipairs(cards) do
  set(card,{AnchorPoint=Vector2.zero,Position=UDim2.fromOffset(((i-1)%columns)*(cw+10/s),math.floor((i-1)/columns)*(ch+10/s)),Size=UDim2.fromOffset(cw,ch)},small)
  aspect(card,cw,ch,small)
  if small then
   local title=card:FindFirstChild("RewardName") or card:FindFirstChild("RewardText")
   local counter=card:FindFirstChild("Countdown") or card:FindFirstChild("DayText")
   set(counter,{AnchorPoint=Vector2.zero,Position=UDim2.fromOffset(4/s,4/s),Size=UDim2.new(1,-8/s,0,24/s)},true);text(counter,12/s,16/s)
   set(card.Decor,{AnchorPoint=Vector2.zero,Position=UDim2.new(.08,0,0,30/s),Size=UDim2.new(.84,0,0,(short and 50 or 78)/s)},true)
   set(title,{AnchorPoint=Vector2.zero,Position=UDim2.fromOffset(4/s,(short and 84 or 110)/s),Size=UDim2.new(1,-8/s,0,(short and 36 or 44)/s)},true);text(title,13/s,16/s)
  else
   for _,n in ipairs({"RewardName","RewardText","Countdown","DayText","Decor"}) do local x=card:FindFirstChild(n);local saved=x and originals[x] if saved then for k,v in pairs(saved) do x[k]=v[1] end end end
  end
  for _,n in ipairs({"Redeem","Locked"}) do local b=card:FindFirstChild(n) if b then
   set(b,{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-8/s),Size=UDim2.new(1,-16/s,0,44/s)},small)
   aspect(b,cw-16/s,44/s,small)
   if small then text(b:FindFirstChild("TextLabel"),14/s,18/s) end
  end end
 end
 holder.CanvasSize=small and UDim2.fromOffset(0,math.ceil(#cards/columns)*(ch+10/s)) or (vip and UDim2.fromScale(0,1.55) or UDim2.new())
end
local itemModes={}
local itemBusy={}
function M.LayoutItems(gui,page,list,grid)
 if not grid or itemBusy[page] then return end
 itemBusy[page]=true
 -- Three original columns; divide out the ancestor scale exactly once.
 local width=math.max(48,math.floor((HUD.GetLocalSize(list).X-32)/3))
 grid.FillDirectionMaxCells=3
 grid.CellSize=UDim2.fromOffset(width,math.floor(width*1.12))
 itemBusy[page]=nil
end

local function merge(panel,gui)
 local small=false -- Preserve authored geometry at every viewport.
 ;local scale=panel.ResponsiveScale.Scale
 local root=panel.Content.Merge.MergePanel
 local short=gui.AbsoluteSize.Y<500
 local recipe,owned,footer=root.MergeRecipe,root.OwnedItemsArea,root.Footer
 set(recipe,{Position=UDim2.new(),Size=short and UDim2.new(.46,-8/scale,1,-52/scale) or UDim2.new(1,0,0,112/scale)},small)
 set(recipe.SectionTitle,{Position=UDim2.fromOffset(4/scale,0),Size=UDim2.new(1,-8/scale,0,20/scale)},small)
 set(recipe.Slots,{Position=UDim2.fromOffset(4/scale,24/scale),Size=UDim2.new(1,-8/scale,0,84/scale)},small)
 local slots=recipe.Slots;local width=HUD.GetLocalSize(recipe).X-8/scale
 local gap=2/scale;local group=(width-42/scale-6*gap)/4
 set(slots.RecipeLayout,{Padding=UDim.new(0,gap)},small)
 for _,x in ipairs(slots:GetChildren()) do
  if x:IsA("Frame") and x:FindFirstChild("Slot") then
   set(x,{Size=UDim2.fromOffset(group,84/scale)},small)
   local side=math.max(44/scale,math.min(54/scale,group))
   set(x.Slot,{Size=UDim2.fromOffset(side,side),Position=UDim2.new(.5,0,0,0)},small)
   set(x.SlotName,{Position=UDim2.fromOffset(0,56/scale),Size=UDim2.new(1,0,0,32/scale)},small)
   if small then text(x.SlotName,11/scale,13/scale) end
  elseif x:IsA("TextLabel") then
   set(x,{Size=UDim2.fromOffset((x.Name=="Arrow" and 18 or 12)/scale,44/scale)},small)
  end
 end
 set(owned,{Position=short and UDim2.new(.46,0,0,0) or UDim2.fromOffset(0,120/scale),Size=short and UDim2.new(.54,0,1,-52/scale) or UDim2.new(1,0,1,-172/scale)},small)
 set(owned.SortButton,{Position=UDim2.new(1,-4/scale,0,0),Size=UDim2.fromOffset(92/scale,44/scale)},small)
 set(owned.SectionTitle,{Size=UDim2.new(.55,0,0,22/scale)},small)
 set(owned.ItemCount,{Position=UDim2.fromOffset(0,22/scale),Size=UDim2.new(.55,0,0,20/scale)},small)
 local list=owned.OwnedItemsScroll
 set(list,{Position=UDim2.fromOffset(0,48/scale),Size=UDim2.new(1,0,1,-48/scale)},small)
 local grid=list:FindFirstChildOfClass("UIGridLayout")
 if grid then
  local width=HUD.GetLocalSize(owned).X-10/scale
  local cols=math.max(1,math.floor((width*scale+6)/104))
  set(grid,{CellSize=UDim2.fromOffset((width-(cols-1)*6/scale)/cols,(short and 62 or 132)/scale),CellPadding=UDim2.fromOffset(6/scale,6/scale)},small)
 end
 for _,card in ipairs(list:GetChildren()) do if card:IsA("Frame") and card:GetAttribute("ProductionItemCard") then
  set(card.ItemImage,{Position=UDim2.fromOffset(4/scale,2/scale),Size=UDim2.new(1,-8/scale,1,-34/scale)},small)
  set(card.ItemName,{Position=UDim2.new(0,2/scale,1,-30/scale),Size=UDim2.new(1,-4/scale,0,18/scale)},small)
  set(card.RarityStars,{Position=UDim2.new(.5,0,1,-2/scale),Size=UDim2.fromOffset(70/scale,10/scale)},small)
  if small then text(card.ItemName,11/scale,13/scale) end
 end end
 set(footer,{Position=UDim2.new(0,0,1,-48/scale),Size=UDim2.new(1,0,0,44/scale)},small)
 set(footer.MergeButton,{Position=UDim2.new(1,0,.5,0),Size=UDim2.new(.48,0,0,44/scale)},small)
 set(footer.Hint,{Size=UDim2.new(.5,-6/scale,1,0)},small)
 if small then text(footer.Hint,11/scale,14/scale) end
end
local function shop(panel,gui)
 local small=false -- Preserve authored geometry at every viewport.
 ;local s=panel.ResponsiveScale.Scale
 header(panel,small,s)
 local scroll=panel.MainScrollingFrame;local holder=scroll.Holder
 set(scroll,{AnchorPoint=Vector2.zero,Position=UDim2.fromOffset(12/s,66/s),Size=UDim2.new(1,-24/s,1,-78/s)},small)
 local w=HUD.GetLocalSize(scroll).X
 for _,card in ipairs(holder:GetChildren()) do
  if card:IsA("Frame") and card:GetAttribute("PurchaseKind") then
   local wide=card.Name:find("Pack")~=nil
   local featured=card:GetAttribute("ShopFeatured")==true
   local cw=wide and (w-8/s) or featured and (w-38/s)/3 or (w-23/s)/2
   local ch=(wide and card:GetAttribute("PurchaseKind")=="ShopProduct" and 240 or featured and 200 or 200)/s
   set(card,{Size=UDim2.fromOffset(cw,ch)},small);aspect(card,cw,ch,small)
   local area=card:FindFirstChild("PurchaseArea")
   set(area,{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-6/s),Size=UDim2.new(.9,0,0,44/s)},small)
   local b=area and area:FindFirstChild("Purchase")
   set(b,{AnchorPoint=Vector2.zero,Position=UDim2.new(),Size=UDim2.fromScale(1,1)},small)
  elseif card:IsA("TextLabel") then set(card,{Size=UDim2.new(1,-12/s,0,30/s)},small) end
 end
end
-- Transparent touch assistance leaves the authored button and all artwork unchanged.
local hitboxes=setmetatable({}, {__mode="k"})
function M.ConnectActivation(button,callback)
 local hit=button:FindFirstChild("ResponsiveHitbox")
 if not hit then
  hit=Instance.new("TextButton");hit.Name="ResponsiveHitbox";hit.Text=""
  hit.BackgroundTransparency=1;hit.BorderSizePixel=0;hit.AutoButtonColor=false
  hit.AnchorPoint=Vector2.zero;hit.Visible=false;hit.Parent=button
 end
 hitboxes[button]=hit
 local last=-math.huge
 local function activate(...)
  if not button.Active or not button.Interactable then return end
  local now=os.clock();if now-last<.1 then return end;last=now
  callback(...)
 end
 local one=button.Activated:Connect(activate);local two=hit.Activated:Connect(activate)
 button.Destroying:Once(function()hitboxes[button]=nil;one:Disconnect();two:Disconnect()end)
 return one
end
local function updateHitboxes(gui)
 local touch=#HUD.GetControls(gui.Parent)>0
 for button,hit in pairs(hitboxes) do if button:IsDescendantOf(gui) then
  hit.Visible=touch and button.Active and button.Interactable
  hit.Active=hit.Visible
  if hit.Visible then
   local scale=HUD.GetScale(button)
   local p,size=button.AbsolutePosition,button.AbsoluteSize
   local bounds=button.Parent
   if bounds.Name=="PurchaseArea" or bounds.Name=="Tabs" then bounds=bounds.Parent end
   local bp,bs=bounds.AbsolutePosition,bounds.AbsoluteSize
   local width=math.min(bs.X,math.max(size.X,40))
   local height=math.min(bs.Y,math.max(size.Y,40))
   local x=math.clamp(p.X+(size.X-width)/2,bp.X,math.max(bp.X,bp.X+bs.X-width))
   local y=math.clamp(p.Y+(size.Y-height)/2,bp.Y,math.max(bp.Y,bp.Y+bs.Y-height))
   hit.Position=UDim2.fromOffset((x-p.X)/scale,(y-p.Y)/scale)
   hit.Size=UDim2.fromOffset(width/scale,height/scale)
   hit.ZIndex=button.ZIndex+1
  end
 end end
end

function M.Bind(gui)
 if bound[gui] then return bound[gui] end
 local busy=false
 local function refresh()
  if busy then return end busy=true
  for _,ref in ipairs(gui.MainPanels:GetChildren()) do local p=ref.Value if p then
   M.Fit(p,gui)
   local layers={p} for _,x in ipairs(p:GetDescendants()) do if x:IsA("GuiObject") then table.insert(layers,x) end end
   for _,x in ipairs(layers) do
    local z=x:GetAttribute("ResponsiveOriginalZ")
    if z==nil then z=x.ZIndex;x:SetAttribute("ResponsiveOriginalZ",z) end
    x.ZIndex=200+z
   end
   if p.Name=="InventoryPanel" then
    inventory(p,gui)
    merge(p,gui)
    local page=p.Content.Items
    if page:FindFirstChild("RarityTabs") then M.LayoutItems(gui,page,page.OwnedItems,page.OwnedItems:FindFirstChildOfClass("UIGridLayout")) end
   elseif p.Name=="TimeRewardsPanel" or p.Name=="DailyRewardsPanel" then rewards(p,gui)
   elseif p.Name=="ShopPanel" then shop(p,gui)
   else
    local small=false;local scale=p.ResponsiveScale.Scale
    header(p,small,scale)
    if p.Name=="CommunityRewardsPanel" then
     local b=p:FindFirstChild("Refresh")
     set(b,{Size=UDim2.new(.22,0,0,44/scale),Position=UDim2.new(.25,0,1,-30/scale)},small)
    elseif p.Name=="RebirthPanel" then
     local b=p:FindFirstChild("RebirthConfirmButton")
     local height=math.max(44,p.AbsoluteSize.Y*.125)
     set(b,{Size=UDim2.new(.48,0,0,height/scale),Position=UDim2.new(.5,0,1,-(height/2+8)/scale)},small)
    end
   end
   if false then for _,x in ipairs(p:GetDescendants()) do
    if x:IsA("TextLabel") and x.Text=="!" then text(x,12/p.ResponsiveScale.Scale,18/p.ResponsiveScale.Scale) end
   end end
  end end
  updateHitboxes(gui)
  local opened=false for _,ref in ipairs(gui.MainPanels:GetChildren()) do if ref.Value and ref.Value.Visible then opened=true end end
  gui.DisplayOrder=opened and 35 or 10
  if not M.Small(gui) then for x,props in pairs(originals) do if x.Parent then for _,k in ipairs({"TextScaled","TextWrapped","MinTextSize","MaxTextSize"}) do if props[k] then x[k]=props[k][1] end end end end end
  busy=false
 end
 local elapsed=0
 local conn=RunService.Heartbeat:Connect(function(dt) elapsed+=dt if elapsed>.15 then elapsed=0;refresh() end end)
 bound[gui]={Refresh=refresh}
 gui.Destroying:Connect(function()conn:Disconnect();bound[gui]=nil end)
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
 task.defer(refresh)
 return bound[gui]
end
return M
