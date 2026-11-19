-- Actual UI modules + native Instances, fake menu/permission APIs. No Play/network/store.
return function(s)
	local checks=0
	local function check(ok,message) checks+=1;assert(ok,message) end
	local config=assert(loadstring(s.Config))()
	local style=assert(loadstring(s.Style))()
	local rs={Config={OfflineRewardUIConfig="Config",StrengthHUDStyle="Style"}}
	local values={Config=config,Style=style}
	local function load(source)
		local fn=assert(loadstring(source))
		setfenv(fn,setmetatable({game={GetService=function(_,name) assert(name=="ReplicatedStorage");return rs end},
			script={Parent={OfflineRewardPresentation="Visual"}},require=function(key) return assert(values[key],key) end},{__index=getfenv()}))
		return fn()
	end
	local V=load(s.Visual);values.Visual=V
	local M=load(s.Client)
	local events={}
	local function event()
		local e={listeners={}};table.insert(events,e)
		function e:Connect(fn)
			local c={Connected=true};self.listeners[c]=fn
			function c:Disconnect() self.Connected=false;e.listeners[self]=nil end
			return c
		end
		function e:Fire() local copy=table.clone(self.listeners);for c,fn in pairs(copy) do if c.Connected then fn() end end end
		return e
	end
	local root=Instance.new("Folder")
	local gui=Instance.new("ScreenGui");gui.Parent=root;gui.Enabled=true
	local panel=game.StarterGui.StrengthGui.OfflineRewards:Clone();panel.Parent=gui;panel.Visible=false
	local opened,closed,promptClosed=event(),event(),event()
	local menu={MenuOpened=opened,MenuClosed=closed,MenuIsOpen=false}
	local allowed,failed,block,release,promptFailure=true,false,false,false,false
	local queries,prompts,clock=0,0,10
	local d={Menu=menu,Closed=promptClosed,Now=function() return clock end,
		CanPrompt=function()
			queries+=1
			if block then repeat task.wait() until release end
			if failed then error("Mock unavailable") end
			return allowed
		end,
		Prompt=function() prompts+=1;if promptFailure then error("Mock prompt error") end end}
	local api
	local ok,err=pcall(function()
		api=M.Mount(gui,panel,d)
		local exit=root.OfflineExitNotice
		check(M.Mount(gui,panel,d)==api,"mount must be singleton")
		check(#root:GetChildren()==2,"one exit GUI")
		check(not exit.Enabled and not panel.NotifyRow.Visible,"initial hidden")
		check(exit.Center.Title.Text=="DON’T GO YET!" and exit.TopBand.Text.Text=="DON’T GO YET!","exact title UTF-8")
		check(exit.Center.Subtitle.Text=="Earn Strength while you’re away!" and exit.BottomBand.Text.Text=="EARN STRENGTH WHILE YOU’RE AWAY!","exact subtitle UTF-8")
		check(queries==0 and prompts==0,"hidden UI must not call capability or prompt")
		local before=panel.Visible
		for _=1,30 do
			menu.MenuIsOpen=true;opened:Fire()
			check(exit.Enabled and exit.Center.Visible and exit.TopBand.Visible and exit.BottomBand.Visible,"simultaneous three visuals")
			menu.MenuIsOpen=false;closed:Fire()
			check(not exit.Enabled and panel.Visible==before,"menu must preserve normal popup")
		end
		check(queries==0 and prompts==0,"menu has no permission/reward side effects")
		for _,x in ipairs(exit:GetDescendants()) do
			check(not x:IsA("GuiButton") and not x:IsA("LuaSourceContainer"),"passive exit only")
			if x:IsA("GuiObject") then check(not x.Active and not x.Interactable,"no exit input interception") end
		end
		panel.Visible=true;task.wait(.04)
		check(panel.NotifyRow.Visible and panel.NotifyRow.Button.Active,"eligible visible")
		check(prompts==0,"open never auto-prompts")
		local originalWidth=config.Exit.Width
		config.Exit.Width=680;V.EnsureExit(root,panel)
		check(exit.Center.Size.X.Offset==680,"existing authored GUI reapplies configured size")
		config.Exit.Width=originalWidth;V.EnsureExit(root,panel)
		local originalColor=config.Notify.Color;config.Notify.Color=Color3.new(.1,.2,.3);V.EnsureNotify(panel)
		check(panel.NotifyRow.Button.BackgroundColor3==config.Notify.Color,"existing button reapplies configured color")
		config.Notify.Color=originalColor;V.EnsureNotify(panel)
		menu.MenuIsOpen=true;opened:Fire();closed:Fire();menu.MenuIsOpen=false
		check(panel.Visible and panel.NotifyRow.Visible,"menu close preserves pending reward")
		for _,size in ipairs({Vector2.new(1920,1080),Vector2.new(1280,720),Vector2.new(852,393),Vector2.new(1024,768)}) do
			V.LayoutReward(panel,size.X,size.Y)
			local scale=panel.RewardScale.Scale
			check(panel.Size.Y.Offset*scale<=size.Y-style.Offline.MarginY+1,"popup fits height (integer pixel rounding)")
			check(panel.NotifyRow.Button.Size.Y.Offset*scale>=43.99,"44px notify hit height")
			check(panel.NotifyRow.Position.Y.Offset>panel.Claim.Position.Y.Offset+panel.Claim.Size.Y.Offset,"separate row")
			V.LayoutExit(exit,size,Rect.new(40,0,size.X-40,size.Y-18))
			check(exit.TopBand.Size.X.Offset==size.X and exit.BottomBand.Size.X.Offset==size.X,"full edge bands")
			check(exit.TopBand.Text.Position.X.Offset>=40,"safe horizontal text")
			check(exit.Center.Fit.Scale>0 and exit.Center.Fit.Scale<=1,"center fit")
		end
		check(api.Click()=="Opened" and prompts==1,"click prompts after eligibility")
		check(api.Click()=="DisabledOrBusy" and prompts==1,"spam blocked")
		allowed=false;promptClosed:Fire();task.wait(.04)
		check(not panel.NotifyRow.Visible,"close isn't assumed consent")
		check(panel.Size.Y.Offset==style.Offline.Height,"hidden row collapses")
		check(panel.Claim.Button.Active,"eligibility does not disable CLAIM")
		panel.Visible=false;allowed=true;panel.Visible=true;task.wait(.04);clock+=3
		failed=true
		check(api.Click()=="CheckFailed" and prompts==1,"click recheck error")
		check(not panel.NotifyRow.Visible,"error hides row")
		panel.Visible=false;failed=false;panel.Visible=true;task.wait(.04);clock+=3
		promptFailure=true
		check(api.Click()=="PromptFailed","native prompt error contained")
		promptFailure=false
		panel.Visible=false;block=true;release=false;panel.Visible=true;task.wait(.03)
		panel.Visible=false;release=true;task.wait(.04)
		check(not panel.NotifyRow.Visible and not panel.Visible,"late availability cannot reopen")
		block=false;panel.Visible=true;task.wait(.04);clock+=3
		block=true;release=false;local answer
		task.spawn(function() answer=api.Click() end);task.wait(.03)
		panel.Visible=false;release=true;task.wait(.04)
		check(answer=="Stale" and prompts==2,"close during recheck prevents prompt")
		block=false;panel.Visible=true;task.wait(.04);clock+=3
		check(api.Click()=="Opened","retry after stale")
		api.Destroy()
		check(not root:FindFirstChild("OfflineExitNotice"),"dispose exit")
		api=M.Mount(gui,panel,d);task.wait(.03)
		check(not panel.NotifyRow.Visible,"recreate doesn't double native prompt")
		promptClosed:Fire();task.wait(.03)
		check(panel.NotifyRow.Visible,"new UI recovers after native close")
		config.Exit.Enabled=false;opened:Fire();check(not root.OfflineExitNotice.Enabled,"exit off")
		config.Notify.Enabled=false;panel.Visible=false;panel.Visible=true;task.wait(.03)
		check(not panel.NotifyRow.Visible,"notify UI off")
		api.Destroy();api.Destroy()
		local listeners=0;for _,e in ipairs(events) do for _ in pairs(e.listeners) do listeners+=1 end end
		check(listeners==0,"no menu/native event residue")
		config.Exit.Enabled=true;menu.MenuIsOpen=true
		api=M.Mount(gui,panel,d)
		check(root.OfflineExitNotice.Enabled,"initial MenuIsOpen")
	end)
	if api then api.Destroy() end
	root:Destroy()
	assert(ok,err)
	return {Assertions=checks,Mode="Edit native Instances + mocked menu/permission; no Play",PromptsMocked=prompts}
end
