local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.RewardedStrengthBoostConfig)
local S=require(RS.Config.RewardedStrengthBoostStyle)
local Visual=require(script.Parent.RewardedStrengthBoostPresentation)
local M={}
local mounted=setmetatable({}, {__mode="k"})
function M.Mount(strengthGui,d)
	if mounted[strengthGui] then return mounted[strengthGui] end
	if not d then
		assert(game:GetService("RunService"):IsClient(),"Client only")
		local player=game:GetService("Players").LocalPlayer
		local ads=game:GetService("AdService")
		local remote=RS.Remotes:WaitForChild("RewardedStrengthBoost",20)
		if not remote then return {Destroy=function()end} end
		d={Player=player,Menu=game:GetService("GuiService"),Now=function() return workspace:GetServerTimeNow() end,
			Monotonic=os.clock,Reply=remote.OnClientEvent,Send=function(action,id) remote:FireServer(action,id) end,
			Available=function()
				if game:GetService("RunService"):IsStudio() then return false end
				local info=ads:GetAdAvailabilityNowAsync(Enum.AdFormat.RewardedVideo)
				return info.AdAvailabilityResult==Enum.AdAvailabilityResult.IsAvailable
			end,
			Price=function() return require(script.Parent.MarketplacePrice).Get(C.ProductId,Enum.InfoType.Product,nil) end,
			BindPurchase=function(button,label) require(script.Parent.HUDLayout).BindPurchaseButton(button,"Robux",label) end}
	end
	local g=Visual.Build(strengthGui.Parent,true)
	local panel=g.Overlay.Panel
	local alive,available,checking,adBusy=true,false,false,false
	local serial,requestId,nextClick,checkStarted=0,0,0,0
	local checkedAt,nextCheck=-math.huge,0
	local watchIntent,availabilityTask,retryReason,flight
	local diagnostics={}
	local send
	local pending={};local connections={};local api={Gui=g}
	mounted[strengthGui]=api
	local function connect(signal,fn)
		-- Destroyed/recreated panels disconnect their signals; do not retain those handles.
		for i=#connections,1,-1 do if not connections[i].Connected then table.remove(connections,i) end end
		table.insert(connections,signal:Connect(fn))
	end
	local function expiry() return tonumber(d.Player:GetAttribute("StrengthBoostExpiresAt")) or 0 end
	local function active() return expiry()>d.Now() end
	local function usable() return available and d.Monotonic()-checkedAt<(C.AvailabilityCacheSeconds or 60) end
	local function diagnose(token,reason,started,result)
		if not (C.AvailabilityDiagnostics or strengthGui:GetAttribute("StrengthBoostDiagnostics")) then return end
		table.insert(diagnostics,{Request=token,Reason=reason,Started=started,Finished=d.Monotonic(),Seconds=math.max(0,d.Monotonic()-started),Result=result})
		if #diagnostics>8 then table.remove(diagnostics,1) end
	end
	function api.GetAvailabilityDiagnostics()
		local copy={};for _,row in diagnostics do table.insert(copy,table.clone(row)) end;return copy
	end
	local function cancelAvailability()
		local thread=availabilityTask;availabilityTask=nil
		if thread and coroutine.status(thread)~="dead" then pcall(d.Cancel or task.cancel,thread) end
	end
	local function blocked()
		if d.Menu.MenuIsOpen or not strengthGui.Enabled then return true end
		for _,name in {"OfflineRewards","ShopPanel","InventoryPanel","MergePanel","RebirthPanel","DailyRewardsPanel","TimeRewardsPanel","CommunityRewardsPanel"} do
			local p=strengthGui:FindFirstChild(name);if p and p.Visible then return true end
		end
		for _,path in {{"DeathGui","Overlay"},{"WorldTravelGui","Modal"},{"StageSkipGui","Panel"},{"MergeShopGui","MergeShopPanel"}} do
			local root=strengthGui.Parent:FindFirstChild(path[1]);local p=root and root:FindFirstChild(path[2])
			if root and root.Enabled and p and p.Visible then return true end
		end
		return false
	end
	local function text(label,value)
		if label.Text~=value then label.Text=value end
		if label==panel.Watch.Title then label.TextSize=value=="WATCH AD" and S.Modal.ButtonTextSize or S.Modal.StatusTextSize end
	end
	local function paint()
		if not alive then return end
		local running=active()
		g.Entry.Visible=not blocked() and (running or C.Enabled and usable())
		text(g.Entry.Footer,running and Visual.Time(expiry(),d.Now()) or "FREE")
		g.Entry.Footer.TextColor3=running and S.Yellow or S.Green
		panel.Watch.Active=C.Enabled and usable() and not checking and not adBusy and not running
		panel.Watch.AutoButtonColor=panel.Watch.Active
	end
	function api.Close()
		-- Closing cancels the user's start intent, not the background eligibility query.
		watchIntent=nil;g.Overlay.Visible=false;paint()
	end
	local function layout()
		local left=strengthGui:FindFirstChild("HUD") and strengthGui.HUD:FindFirstChild("LeftHUD")
		local bounds=left and {Right=left.AbsolutePosition.X+left.AbsoluteSize.X,Blocks={}} or nil
		if bounds then for _,name in {"RunInventoryLabel","RunInventoryIcon","RunReturnButton"} do
			local o=strengthGui.HUD:FindFirstChild(name)
			if o and o.Visible then table.insert(bounds.Blocks,{X=o.AbsolutePosition.X,Y=o.AbsolutePosition.Y,W=o.AbsoluteSize.X,H=o.AbsoluteSize.Y}) end
		end end
		Visual.Layout(g,bounds)
	end
	function api.RefreshAvailability(reason,force,intent)
		if not alive or not C.Enabled or active() or adBusy or checking then return false end
		reason=reason or "Explicit"
		if not force and usable() then paint();return false end
		if not force and d.Monotonic()<nextCheck then retryReason=reason;return false end
		retryReason=nil
		serial+=1;local token=serial;checking=true;checkStarted=d.Monotonic()
		local started=checkStarted;flight={Token=token,Reason=reason,Started=started}
		if g.Overlay.Visible then text(panel.Watch.Title,"Checking...") end;paint()
		availabilityTask=task.spawn(function()
			local ok,value=pcall(d.Available)
			if not alive or token~=serial then return end
			availabilityTask=nil;flight=nil;checking=false;available=ok and value==true
			checkedAt=d.Monotonic();nextCheck=checkedAt+(C.AvailabilityRetrySeconds or 5)
			diagnose(token,reason,started,not ok and "Error" or available and "Available" or "Unavailable")
			if g.Overlay.Visible then text(panel.Watch.Title,available and "WATCH AD" or "Ad unavailable") end
			if intent and watchIntent==intent then
				watchIntent=nil
				if available and g.Overlay.Visible and not blocked() and not active() then
					adBusy=true;text(panel.Watch.Title,"Please wait...")
					if not send("Ad") then adBusy=false;text(panel.Watch.Title,"Ad unavailable") end
				end
			end
			paint()
		end)
		return true
	end
	function api.Open()
		if not alive or blocked() or not C.Enabled or active() or adBusy or not usable() then return false end
		g.Overlay.Visible=true;text(panel.Watch.Title,checking and "Checking..." or "WATCH AD")
		api.RefreshAvailability("Open");return true
	end
	send=function(action)
		requestId=(requestId+1)%2147483647
		local id=requestId;pending[id]={Action=action,Started=d.Monotonic()}
		local ok=pcall(d.Send,action,id)
		if not ok then pending[id]=nil;return nil end
		return id
	end
	function api.Watch()
		if not alive or not g.Overlay.Visible or blocked() or not panel.Watch.Active or d.Monotonic()<nextClick then return false end
		nextClick=d.Monotonic()+C.RequestCooldownSeconds
		watchIntent={}
		return api.RefreshAvailability("Watch",true,watchIntent)
	end
	local function opportunity(reason)
		if not alive then return end
		if blocked() then api.Close() else api.RefreshAvailability(reason) end
		paint()
	end
	local messages={ReturnToLobby="Return to Lobby",StudioPreviewOnly="Studio preview only",DataNotLoaded="Please try again",
		AwaitingReceipt="Confirming reward...",BoostActive="Boost active",Busy="Please wait..."}
	connect(d.Reply,function(id,code)
		local request=pending[id];if not request or not alive then return end
		pending[id]=nil
		if request.Action=="Ad" then
			adBusy=false
			if code=="AwaitingReceipt" or code=="AdUnavailable" or code=="Unavailable" then available=false end
			if active() then api.Close()
			elseif g.Overlay.Visible then
				text(panel.Watch.Title,messages[code] or "Ad unavailable")
				-- An unconfirmed receipt may still arrive. Don't invite another ad immediately.
			end
		end
		paint()
	end)
	connect(g.Entry.Activated,api.Open);connect(panel.Close.Activated,api.Close);connect(panel.Watch.Activated,api.Watch)
	connect(d.Menu.MenuOpened,api.Close);connect(d.Menu.MenuClosed,function()opportunity("MenuClosed")end)
	connect(d.Player:GetAttributeChangedSignal("StrengthBoostExpiresAt"),function()
		if active() then api.Close() end;paint()
	end)
	-- New natural opportunities can recover a previous no-fill/API failure; no polling loop.
	connect(d.Player:GetAttributeChangedSignal("CurrentWorld"),function()opportunity("WorldChanged")end)
	if d.Player:IsA("Player") then connect(d.Player.CharacterAdded,function()api.Close();opportunity("CharacterAdded")end) end
	connect(strengthGui:GetPropertyChangedSignal("Enabled"),function()opportunity("GuiEnabled")end)
	connect(g:GetPropertyChangedSignal("AbsoluteSize"),layout)
	local left=strengthGui:FindFirstChild("HUD") and strengthGui.HUD:FindFirstChild("LeftHUD")
	if left then
		connect(left:GetPropertyChangedSignal("AbsolutePosition"),layout)
		connect(left:GetPropertyChangedSignal("AbsoluteSize"),layout)
		for _,name in {"RunInventoryLabel","RunInventoryIcon","RunReturnButton"} do
			local o=strengthGui.HUD:FindFirstChild(name)
			if o then for _,property in {"AbsolutePosition","AbsoluteSize","Visible"} do connect(o:GetPropertyChangedSignal(property),layout) end end
		end
	end
	local watched=setmetatable({}, {__mode="k"})
	local watchedRoots=setmetatable({}, {__mode="k"})
	local function watchPanels()
		local list={}
		for _,name in {"OfflineRewards","ShopPanel","InventoryPanel","MergePanel","RebirthPanel","DailyRewardsPanel","TimeRewardsPanel","CommunityRewardsPanel"} do table.insert(list,strengthGui:FindFirstChild(name)) end
		for _,path in {{"DeathGui","Overlay"},{"WorldTravelGui","Modal"},{"StageSkipGui","Panel"},{"MergeShopGui","MergeShopPanel"}} do
			local root=strengthGui.Parent:FindFirstChild(path[1]);if root then
				table.insert(list,root:FindFirstChild(path[2]))
				if not watchedRoots[root] then
					watchedRoots[root]=true
					connect(root:GetPropertyChangedSignal("Enabled"),function()opportunity("OtherGuiEnabled")end)
				end
			end
		end
		for _,p in ipairs(list) do if p and not watched[p] then
			watched[p]=true;connect(p:GetPropertyChangedSignal("Visible"),function()opportunity(p.Name.."Visible")end)
		end end
	end
	connect(strengthGui.Parent.DescendantAdded,function(o)
		if o:IsA("ScreenGui") or o:IsA("GuiObject") and (o.Parent==strengthGui or o.Parent and o.Parent:IsA("ScreenGui")) then
			watchPanels();opportunity("PanelAdded")
		end
	end);watchPanels()
	local holder=strengthGui:FindFirstChild("ShopPanel") and strengthGui.ShopPanel.MainScrollingFrame.Holder
	local card=holder and Visual.BuildShop(holder,true)
	if card then
		local button=card.PurchaseArea.Purchase
		-- CardWin may already carry the shared purchased-button skin at runtime.
		-- Rebind its visible amount to OUR price label instead of retaining BUY WIN.
		if d.BindPurchase then d.BindPurchase(button,button.PriceTag) end
		local priceReady=false
		function api.Buy()
			if not alive or not C.Enabled or not priceReady or d.Monotonic()<nextClick then return end
			nextClick=d.Monotonic()+C.RequestCooldownSeconds;return send("Buy")~=nil
		end
		connect(button.Activated,api.Buy)
		task.spawn(function()
			local ok,price,source=pcall(d.Price)
			if not alive or not card.Parent then return end
			priceReady=ok and type(price)=="number" and price>=0
			button.Active=C.Enabled and priceReady
			button.PriceTag.Text=priceReady and require(script.Parent.NumberFormat).Price(price).." Robux" or "Unavailable"
			button.PriceTag:SetAttribute("PriceSource",source or "Unavailable")
		end)
	end
	local wasActive=active()
	function api.Tick()
		if not alive then return end
		if g.Overlay.Visible and blocked() then api.Close() end
		if checking and d.Monotonic()-checkStarted>=(C.AvailabilityTimeoutSeconds or 15) then
			if flight then diagnose(flight.Token,flight.Reason,flight.Started,"Timeout") end
			serial+=1;checking=false;available=false;watchIntent=nil;flight=nil;cancelAvailability()
			nextCheck=d.Monotonic()+(C.AvailabilityRetrySeconds or 5);text(panel.Watch.Title,"Ad unavailable")
		end
		for id,r in pairs(pending) do if d.Monotonic()-r.Started>C.ClientResponseTimeoutSeconds then
			pending[id]=nil
			if r.Action=="Ad" then adBusy=false;available=false;text(panel.Watch.Title,"Please try again") end
		end end
		local running=active()
		if wasActive and not running then available=false;api.RefreshAvailability("Expired") end
		-- At most one deferred recovery requested by a real UI/world event. Failure
		-- does not schedule another check; the existing timer is not an ad poller.
		if retryReason and d.Monotonic()>=nextCheck and not blocked() then
			local reason=retryReason;retryReason=nil;api.RefreshAvailability(reason)
		end
		wasActive=running;paint()
	end
	function api.Destroy()
		if not alive then return end
		alive=false;serial+=1;watchIntent=nil;retryReason=nil;flight=nil;cancelAvailability()
		for _,c in ipairs(connections) do c:Disconnect() end
		table.clear(connections);table.clear(pending);table.clear(diagnostics);mounted[strengthGui]=nil
		g:Destroy();if card then card:Destroy() end
	end
	connect(strengthGui.Destroying,api.Destroy)
	connect(g.Destroying,api.Destroy)
	layout();paint();api.RefreshAvailability("Mount")
	if not d.ManualTick then task.spawn(function()while alive do task.wait(.25);api.Tick()end end) end
	return api
end
return M
