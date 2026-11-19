-- Edit-only presentation restore. Reads current Source without caching a live ModuleScript.
-- Does not set an event date, start Play, save or publish. Source synchronization is separate.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857,"Wrong place")
assert(not game:GetService("RunService"):IsRunning(),"Edit only")
assert(game.ServerScriptService.Main.Disabled and game.StarterPlayer.StarterPlayerScripts.Main.Disabled,"Legacy Weather Main must remain disabled")
local RS=game:GetService("ReplicatedStorage")
local Style=assert(loadstring(RS.Config.World1PremiumTreadmillEventStyle.Source))()
local Schedule=assert(loadstring(RS.Modules.World1PremiumTreadmillEventSchedule.Source))()
local chunk=assert(loadstring(RS.Modules.World1PremiumTreadmillEventPresentation.Source))
setfenv(chunk,setmetatable({require=function(ref)
 assert(ref==RS.Config.World1PremiumTreadmillEventStyle,"Unexpected dependency")
 return Style
end},{__index=getfenv()}))
local View=chunk()
local Config=assert(loadstring(game.ServerScriptService.Config.World1PremiumTreadmillEventConfig.Source))()
local plan=Schedule.Compile(Config)
local p=Schedule.Presentation(Schedule.At(plan,workspace:GetServerTimeNow()))
local board=assert(View.BindBoard(workspace.EventBoard),"Existing board incomplete")
local overhead=assert(View.BindOverhead(workspace.Treadmills.Diamond01),"Actual equipment missing")
View.DrawBoard(board,p);View.DrawOverhead(overhead,p)
local state=RS:FindFirstChild("World1PremiumTreadmillEventState")
if not state then state=Instance.new("StringValue");state.Name="World1PremiumTreadmillEventState";state.Parent=RS end
state.Value=game:GetService("HttpService"):JSONEncode(plan)
return {BoardVisible=p.BoardVisible,Open=p.Open,Plan=plan}
