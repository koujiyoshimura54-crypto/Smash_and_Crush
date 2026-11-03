local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer
local PC=require(script.Parent.Services.PetClient);local remote=RS:WaitForChild("__EggFinalQA")
local function waitFor(fn)
 for i=1,200 do local r=fn();if r then return r end;task.wait(.1)end error("Final QA timeout")
end
local report={};local result=Instance.new("StringValue");result.Name="__EggFinalResult";result.Parent=p.PlayerScripts
local ok,err=xpcall(function()
 local early=remote:InvokeServer("Early");assert(early.Before==false and early.Purchase.ok and early.Equip.tutorial.Completed)
 report.EarlyServerConfirmed=true
 PC.refresh();waitFor(function()return PC.tutorialState() and PC.tutorialState().Completed end)
 remote:InvokeServer("CompleteFloor");task.wait(.5)
 local gui=p.PlayerGui.EggPetTutorialGui;assert(not gui.Canvas.Highlight.Visible and p:GetAttribute("EggTutorialTarget")==nil)
 report.EarlySkippedAllInstructions=true
 remote:InvokeServer("ResetEligible");waitFor(function()return gui:GetAttribute("Step")=="GoToEgg"end)
 local screen=p.PlayerGui.ScreenGui;local original=screen:FindFirstChild("Rare");if original then original.Name="__EggQARareOriginal"end
 local other=Instance.new("BillboardGui");other.Name="Rare";other.Enabled=true;other.Parent=screen
 waitFor(function()return gui:GetAttribute("Step")=="WaitingForDisplay"end);report.OtherEggPause=true
 other:Destroy();if original then original.Name="Rare"end
 waitFor(function()return gui:GetAttribute("Step")=="GoToEgg"end);report.OtherEggResume=true
 local limited=Instance.new("ScreenGui");limited.Name="LimitedEgg01Gui";limited.Parent=p.PlayerGui
 waitFor(function()return gui:GetAttribute("Step")=="WaitingForDisplay"end);limited:Destroy()
 waitFor(function()return gui:GetAttribute("Step")=="GoToEgg"end);report.LimitedPauseResume=true
 report.State=remote:InvokeServer("Done")
end,debug.traceback)
report.Passed=ok;report.Error=not ok and err or nil;result.Value=game.HttpService:JSONEncode(report)
