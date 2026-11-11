-- Actual client HUD + ordinary Tap input, with explicitly seeded save boundaries.
local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer
local qa=RS:WaitForChild("__EarlyQABoundary");local request=qa.Request
local Format=require(RS.Modules.StrengthHUDPresentation);local Requirements=require(RS.Config.LevelRequirements)
local Progress=require(RS.Modules.LevelProgression)
local hud=p.PlayerGui:WaitForChild("StrengthGui"):WaitForChild("StrengthLevelHUD")
local bar=hud.LevelPanel.StrengthProgressBar
local records={}
local function view(s)
 task.wait(.25)
 local expected=Format.Number(s.Progress).." / "..Format.Number(Requirements.GetRequiredStrength(s.Level))
 assert(bar.Level.Text=="Lv."..s.Level,"HUD Level "..bar.Level.Text)
 assert(bar.Exp.Text==expected,"HUD progress "..bar.Exp.Text.." expected "..expected)
 assert(hud.StrengthValueContainer.Strength.Text==Format.Number(s.Strength),"HUD Strength")
 assert(math.abs(bar.FillClip.Size.X.Scale-s.Progress/Requirements.GetRequiredStrength(s.Level))<1e-6,"HUD fill")
 return {Level=bar.Level.Text,Progress=bar.Exp.Text,Strength=hud.StrengthValueContainer.Strength.Text,Fill=bar.FillClip.Size.X.Scale}
end
local ok,err=xpcall(function()
 request:InvokeServer("Ready")
 local cases={{1,9,9},{2,29,39},{3,49,89},{4,69,159},{5,0,160},{6,124,374},{7,154,529},{8,189,719},{10,15,970},{2,29,39,1}}
 for _,v in cases do
  local row={Case={Level=v[1],Progress=v[2],Strength=v[3],Rebirth=v[4]or 0}}
  local first=request:InvokeServer("Seed",row.Case);row.Normalized=first;row.FirstHUD=view(first)
  task.wait(.6);RS.Remotes.AutoTapRequest:FireServer("Tap")
  task.wait(.4)
  local gained=request:InvokeServer("State");local gain=gained.Strength-first.Strength
  assert(gain>0,"ordinary Tap not accepted")
  local l,pr=Progress.Advance(first.Level,first.Progress,gain)
  assert(gained.Level==l and gained.Progress==pr,"gain carry")
  row.Gain=gain;row.AfterGain=gained;row.GainHUD=view(gained)
  local reload=request:InvokeServer("Roundtrip");row.ReloadHUD=view(reload)
  table.insert(records,row);print("[EARLY_BOUNDARY] "..v[1].."/"..v[2].." passed")
 end
 local s=request:InvokeServer("ZeroGain");table.insert(records,{ZeroGain=s,HUD=view(s)})
end,debug.traceback)
local result=Instance.new("StringValue");result.Name="ClientResult"
result.Value=game.HttpService:JSONEncode({Success=ok,Error=not ok and err or nil,Cases=records});result.Parent=qa
print("[EARLY_BOUNDARY] finished "..tostring(ok))
