return function(sources)
	local n=0
	local function eq(a,b,why)n+=1;assert(a==b,(why or "check")..": "..tostring(a).." ~= "..tostring(b))end
	local values={}
	local fakeRS={Config={RewardedStrengthBoostConfig="Config",RewardedStrengthBoostStyle="Style"}}
	local parent={StrengthHUDStyle="HUDStyle",RewardedStrengthBoostPresentation="Visual",NumberFormat="NumberFormat"}
	local function load(key)
		local f=assert(loadstring(sources[key]));setfenv(f,setmetatable({
			game={GetService=function(_,name)assert(name=="ReplicatedStorage");return fakeRS end},
			script={Parent=parent},require=function(id)return assert(values[id],id)end,
		},{__index=getfenv()}));values[key]=f();return values[key]
	end
	load("Config");load("HUDStyle");load("Style");load("Visual")
	for _,size in {Vector2.new(1365,768),Vector2.new(749,381),Vector2.new(1375,1031)}do
		local mock={AbsoluteSize=size,Entry={Fit={}},Overlay={Panel={Fit={},Close={}}}}
		values.Visual.Layout(mock,{Right=150,Blocks={{X=164,Y=20,W=120,H=44}}})
		eq(mock.Entry.Position.Y.Offset>=72,true,"entry avoids current bag/return HUD")
		eq(mock.Overlay.Panel.Close.Size.X.Offset*mock.Overlay.Panel.Fit.Scale>=44,true,"close touch target")
	end
	values.NumberFormat={Price=tostring}
	local Client=load("Client")
	local folder=Instance.new("Folder");folder.Name="UnparentedBoostUITest"
	local main=Instance.new("ScreenGui");main.Name="StrengthGui";main.Parent=folder
	for _,name in {"OfflineRewards","ShopPanel","InventoryPanel","MergePanel","RebirthPanel","DailyRewardsPanel","TimeRewardsPanel","CommunityRewardsPanel"} do
		local p=Instance.new("Frame");p.Name=name;p.Visible=false;p.Parent=main
	end
	local scroll=Instance.new("ScrollingFrame");scroll.Name="MainScrollingFrame";scroll.Parent=main.ShopPanel
	local holder=Instance.new("Frame");holder.Name="Holder";holder.Parent=scroll
	local template=Instance.new("Frame");template.Name="CardWin";template.Parent=holder
	for _,name in {"Title","Benefits","Benefits"}do local o=Instance.new("TextLabel");o.Name=name;o.Parent=template end
	local icon=Instance.new("ImageLabel");icon.Name="Icon";icon.Parent=template
	for _,name in {"Gift","Owned"}do local b=Instance.new("TextButton");b.Name=name;b.Parent=template end
	local area=Instance.new("Frame");area.Name="PurchaseArea";area.Parent=template
	local buy=Instance.new("TextButton");buy.Name="Purchase";buy.Parent=area
	local price=Instance.new("TextLabel");price.Name="PriceTag";price.Parent=buy
	local hit=Instance.new("TextButton");hit.Name="ResponsiveHitbox";hit.Parent=buy
	local player=Instance.new("Folder");player.Parent=folder
	local events={}
	local function event()local e=Instance.new("BindableEvent");events[#events+1]=e;return e end
	local opened,closed,reply=event(),event(),event()
	local menu={MenuIsOpen=false,MenuOpened=opened.Event,MenuClosed=closed.Event}
	local now,mono,allowed,fail=1000,0,true,false
	local sent,checks,priceBindings={},0,0;local gate
	local d={Player=player,Menu=menu,Now=function()return now end,Monotonic=function()return mono end,
		Reply=reply.Event,Send=function(action,id)sent[#sent+1]={action,id}end,ManualTick=true,
		Price=function()return 1,"Marketplace"end,
		BindPurchase=function(button,label)eq(label,button.PriceTag);priceBindings+=1 end,
		Available=function()checks+=1;if gate then gate.Event:Wait()end;if fail then error("API fail")end;return allowed end}
	local api
	local function wait()task.wait(.03)end
	local ok,result=pcall(function()
		api=Client.Mount(main,d);wait();local g=api.Gui;local p=g.Overlay.Panel
		eq(g.Entry.Visible,true);eq(g.Entry.Footer.Text,"FREE");eq(p.Title.Text,"FREE BOOST")
		eq(p.Subtitle.Text,"×2 Strength · 5 MIN");eq(g.Entry.Arm.Image,values.HUDStyle.Assets.Strength)
		eq(Client.Mount(main,d),api,"single mount");eq(#folder:GetChildren(),3,"no repeated GUI")
		eq(api.Open(),true);wait();eq(g.Overlay.Visible,true);eq(p.Watch.Active,true)
		eq(api.Watch(),true);eq(api.Watch(),false);wait();eq(#sent,1);eq(sent[1][1],"Ad")
		eq(p.Watch.Active,false);api.Close();eq(g.Overlay.Visible,false)
		reply:Fire(sent[1][2],"AwaitingReceipt");wait();eq(g.Overlay.Visible,false,"late result cannot reopen")
		eq(player:GetAttribute("StrengthBoostExpiresAt"),nil,"ad result never sets reward")
		player:SetAttribute("StrengthBoostExpiresAt",1300);wait();api.Tick()
		eq(g.Entry.Visible,true);eq(g.Entry.Footer.Text,"05:00");eq(api.Open(),false)
		now=1299;api.Tick();eq(g.Entry.Footer.Text,"00:01")
		allowed=false;now=1300;api.Tick();wait();eq(g.Entry.Visible,false)
		local count=checks;for _=1,20 do api.Tick()end;eq(checks,count,"no availability polling")
		allowed=true;api.RefreshAvailability();wait();eq(g.Entry.Visible,true)
		main.OfflineRewards.Visible=true;wait();eq(g.Entry.Visible,false);eq(api.Open(),false)
		main.OfflineRewards.Visible=false;wait();eq(g.Entry.Visible,true)
		api.Open();wait();menu.MenuIsOpen=true;opened:Fire();wait();eq(g.Overlay.Visible,false)
		eq(main.OfflineRewards.Visible,false,"no reward UI mutation")
		menu.MenuIsOpen=false;closed:Fire();wait();eq(g.Overlay.Visible,false)
		api.Open();wait();mono+=4;allowed=false;api.Watch();wait();eq(#sent,1,"no-fill does not start or buy")
		eq(p.Watch.Title.Text,"Ad unavailable");eq(p.Close.Active,true)
		api.Close();allowed=true;api.RefreshAvailability();wait();api.Open();wait()
		mono+=4;fail=true;api.Watch();wait();eq(#sent,1);eq(p.Watch.Active,false);fail=false
		api.Close();allowed=true;api.RefreshAvailability();wait()
		gate=event();api.Open();wait();api.Close();gate:Fire();gate=nil;wait();eq(g.Overlay.Visible,false)
		api.Open();wait();mono+=4;api.Watch();wait();eq(#sent,2)
		mono+=121;api.Tick();eq(p.Watch.Title.Text,"Please try again");eq(p.Close.Active,true)
		reply:Fire(sent[2][2],"AwaitingReceipt");wait();eq(g.Overlay.Visible,true,"ignored expired reply does not control modal")
		player:SetAttribute("StrengthBoostExpiresAt",1600);wait();eq(g.Overlay.Visible,false,"late durable receipt closes modal")
		eq(g.Entry.Visible,true,"active timer independent of ad eligibility")
		local card=holder.StrengthBoostProduct
		eq(card:GetAttribute("PurchaseKind"),"ShopProduct","legacy purchase handler excluded")
		eq(card.PurchaseArea.Purchase:FindFirstChild("ResponsiveHitbox"),nil,"no inherited click interception")
		eq(card.PurchaseArea.Purchase.PriceTag.Text,"1 Robux")
		eq(priceBindings,1,"visible shop price rebound once")
		local oldSent=#sent;mono+=4;eq(api.Buy(),true);eq(#sent,oldSent+1);eq(sent[#sent][1],"Buy")
		api.Buy();eq(#sent,oldSent+1,"shop debounce")
		api.Destroy();eq(folder:FindFirstChild("RewardedStrengthBoostGui"),nil)
		local second=Client.Mount(main,d);wait();eq(second==api,false)
		second.Destroy();eq(folder:FindFirstChild("RewardedStrengthBoostGui"),nil)
		return {Assertions=n,Mode="Edit / native unparented GUI + mocked availability/events; no real prompts or ads"}
	end)
	if api then api.Destroy()end
	folder:Destroy();for _,e in ipairs(events)do e:Destroy()end
	assert(ok,result);return result
end
