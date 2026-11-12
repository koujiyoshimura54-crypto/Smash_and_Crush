local source=game.ReplicatedStorage.Modules.BadgeRenderer.Source
local heartbeatConnections=0
local signal={Connect=function(_,fn)heartbeatConnections+=1;return {Disconnect=function()heartbeatConnections-=1 end}end}
local fn=assert(loadstring(source:gsub("return table.freeze%(M%)%s*$","return {API=M,Records=records,Mounts=mounts,Animate=animate}")))
local env=setmetatable({game={GetService=function(_,name)assert(name=="RunService");return {Heartbeat=signal}end}},{__index=getfenv()});setfenv(fn,env)
local t=fn();local M=t.API
local parent=Instance.new("Folder");local gui=Instance.new("ScreenGui");gui.Parent=parent;local button=Instance.new("TextButton");button.Parent=gui
local badge=game.StarterGui.StrengthGui.LeftMenu.InventoryButton.NotificationBadge:Clone();badge.Parent=button;badge.Visible=true
local count=0;local rows={}
local function check(name,value)assert(value,name);count+=1;table.insert(rows,name)end
local cleanup
local ok,err=xpcall(function()
 cleanup=M.Mount(gui);M.Mount(gui);M.Attach(badge);M.Attach(badge)
 local image=badge.NotificationImage
 check("specified image ID",image.Image=="rbxassetid://126155807251943")
 check("1.5 size factor",image.Size==UDim2.fromScale(1.5,1.5))
 check("image never intercepts input",not image.Active and not image.Interactable and not image.Selectable)
 check("old background and text muted",badge.BackgroundTransparency==1 and badge.TextLabel.TextTransparency==1 and badge.UIStroke.Transparency==1)
 check("one animation connection after repeated mount",heartbeatConnections==1)
 local childCount=0;for _,x in badge:GetChildren()do if x.Name=="NotificationImage"then childCount+=1 end end
 check("one image",childCount==1)
 button.ZIndex=239;badge.ZIndex=230;task.wait();task.wait();check("responsive layer change stays above parent",badge.ZIndex>button.ZIndex and image.ZIndex>badge.ZIndex)
 t.Animate(2.9);check("no early shake",image.Rotation==0)
 t.Animate(.2);check("positive rotation",image.Rotation>9.9)
 t.Animate(.2);check("negative rotation",image.Rotation< -9.9)
 t.Animate(.2);check("rotation returns to zero",image.Rotation==0)
 badge.Visible=false;task.wait();t.Animate(3.1)
 check("hidden badge reset",image.Rotation==0 and t.Records[badge].Elapsed==0)
 badge.Visible=true;button.Visible=false;t.Animate(3.1)
 check("hidden ancestor reset",image.Rotation==0 and t.Records[badge].Elapsed==0)
 button.Visible=true;gui.Enabled=false;t.Animate(3.1)
 check("disabled screen reset",image.Rotation==0 and t.Records[badge].Elapsed==0)
 gui.Enabled=true;t.Animate(3.1);check("resume one shake",image.Rotation>9.9)
 gui.Parent=nil;t.Animate(3.1);check("detached screen reset",image.Rotation==0 and t.Records[badge].Elapsed==0);gui.Parent=parent
 badge.BackgroundTransparency=0;badge.TextLabel.TextTransparency=0;badge.UIStroke.Transparency=0;task.wait();task.wait()
 check("late legacy paint writers remain suppressed",badge.BackgroundTransparency==1 and badge.TextLabel.TextTransparency==1 and badge.UIStroke.Transparency==1)
 local clone=M.GetOrClone(badge,button,"ItemGuideBadge");M.GetOrClone(badge,button,"ItemGuideBadge")
 check("clone is deduplicated",clone==button.ItemGuideBadge)
 check("cloning keeps one shared scheduler",heartbeatConnections==1)
 badge:Destroy();task.wait();task.wait();check("destroy drops badge record",t.Records[badge]==nil)
 cleanup();check("cleanup stops scheduler",heartbeatConnections==0)
 check("cleanup clears mount",t.Mounts[gui]==nil)
end,debug.traceback)
if cleanup then cleanup()end;gui:Destroy();parent:Destroy()
assert(ok,err)
return game:GetService("HttpService"):JSONEncode({Checks=count,Passed=rows,Mode="Current renderer with deterministic heartbeat and native GUI signals",Cleanup=true})
