-- UI lifecycle only. Injected native services below allow Edit-only, send-free tests.
-- No View/Claim/purchase/save/HTTP/notification reservation calls belong here.
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.OfflineRewardUIConfig)
local Visual=require(script.Parent.OfflineRewardPresentation)
local M={}
local mounted=setmetatable({}, {__mode="k"})
local refreshMounted=setmetatable({}, {__mode="k"})
-- Survives GUI recreation while a native opt-in prompt is still open.
local nativeBusy=false
local nextClick=0
function M.Mount(gui,panel,dependencies)
	if mounted[gui] then return mounted[gui] end
	local d=dependencies
	if not d then
		assert(game:GetService("RunService"):IsClient(),"ClientOnly")
		local notifications=game:GetService("ExperienceNotificationService")
		d={Menu=game:GetService("GuiService"),
			CanPrompt=function() return notifications:CanPromptOptInAsync() end,
			Prompt=function() notifications:PromptOptIn() end, Closed=notifications.OptInPromptClosed}
	end
	local now=d.Now or os.clock
	local button=Visual.EnsureNotify(panel)
	local row=button.Parent
	local exit=Visual.EnsureExit(gui.Parent,panel)
	local alive,serial,checking=true,0,false
	local connections={}
	local api={}
	local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
	local function visible() return alive and gui.Enabled and panel.Visible and panel.Parent~=nil end
	local function layout()
		if not alive then return end
		Visual.LayoutReward(panel,gui.AbsoluteSize.X,gui.AbsoluteSize.Y)
		local size=exit.AbsoluteSize
		local safe=Rect.new(0,0,size.X,size.Y)
		local ok,none,device=pcall(function()
			return d.Menu:GetInsetArea(Enum.ScreenInsets.None),d.Menu:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
		end)
		if ok then safe=Rect.new(device.Min-none.Min,device.Max-none.Min) end
		Visual.LayoutExit(exit,size,safe)
	end
	local function setRow(show)
		if not alive then return end
		row.Visible=show;button.Active=show and not checking and not nativeBusy
		layout()
	end
	local function current(token) return visible() and serial==token end
	local function refresh()
		serial+=1;checking=false;setRow(false)
		if not visible() or not C.Notify.Enabled or nativeBusy then return end
		local token=serial;checking=true
		task.spawn(function()
			local ok,allowed=pcall(d.CanPrompt)
			if not current(token) then return end
			checking=false;setRow(ok and allowed==true)
		end)
	end
	function api.Click()
		if not visible() or not row.Visible or checking or nativeBusy or now()<nextClick or not C.Notify.Enabled then return "DisabledOrBusy" end
		nativeBusy=true;checking=true;nextClick=now()+C.Notify.CooldownSeconds
		serial+=1;local token=serial;button.Active=false
		local ok,allowed=pcall(d.CanPrompt)
		if not current(token) then nativeBusy=false;return "Stale" end
		checking=false
		if not ok or allowed~=true then nativeBusy=false;setRow(false);return ok and "Unavailable" or "CheckFailed" end
		-- Install before Prompt: even an immediate native close cannot be missed.
		local closing
		closing=d.Closed:Connect(function()
			closing:Disconnect();nativeBusy=false
			-- Closing is NOT opt-in success. Recheck capability only while still visible.
			for _,recheck in pairs(refreshMounted) do recheck() end
		end)
		local prompted=pcall(d.Prompt)
		if not prompted then closing:Disconnect();nativeBusy=false;setRow(false);return "PromptFailed" end
		setRow(false)
		return "Opened"
	end
	local function menu(open)
		exit.Enabled=C.Exit.Enabled and gui.Enabled and open
		layout()
	end
	function api.Destroy()
		if not alive then return end
		alive=false;serial+=1;checking=false
		for _,c in ipairs(connections) do c:Disconnect() end
		table.clear(connections);mounted[gui]=nil;refreshMounted[gui]=nil
		if row.Parent then row.Visible=false end
		exit:Destroy()
		-- A native prompt's one-shot Closed listener lasts until that prompt closes.
	end
	connect(button.Activated,api.Click)
	connect(panel:GetPropertyChangedSignal("Visible"),refresh)
	connect(gui:GetPropertyChangedSignal("Enabled"),function() refresh();menu(d.Menu.MenuIsOpen) end)
	connect(gui:GetPropertyChangedSignal("AbsoluteSize"),layout)
	connect(exit:GetPropertyChangedSignal("AbsoluteSize"),layout)
	connect(d.Menu.MenuOpened,function() menu(true) end)
	connect(d.Menu.MenuClosed,function() menu(false) end)
	connect(gui.Destroying,api.Destroy)
	connect(panel.Destroying,api.Destroy)
	mounted[gui]=api
	refreshMounted[gui]=refresh
	menu(d.Menu.MenuIsOpen);refresh()
	return api
end
return M
