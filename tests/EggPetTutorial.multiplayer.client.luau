local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local services=script.Parent.Services
local PC=require(services.PetClient)
local HC=require(services.HatchClient)
local MC=require(services.MenuClient)
local function waitFor(fn,seconds)
 local t=os.clock()+(seconds or 20)
 repeat local x=fn();if x then return x end;task.wait(.1)until os.clock()>t
 error("Client timeout")
end
local remote=RS:WaitForChild("__EggQAMulti")
local index=remote:InvokeServer("Ready")
local checks={}
local ok,err=xpcall(function()
 local overlay=p.PlayerGui:WaitForChild("EggPetTutorialGui")
 local function step()return overlay:GetAttribute("Step")end
 local function check(name,value)assert(value,name);table.insert(checks,name)end
 waitFor(function()return step()==(index==1 and "GoToEgg" or "WaitingForWin")end)
 check("author Outline survives Play",overlay.Canvas.Highlight.Outline.Thickness==1.125)
 check("author Shadow survives Play",math.abs(overlay.Canvas.Highlight.Shadow.Transparency-.35)<.0001)
 check("author growth survives Play",overlay.Canvas.Highlight:GetAttribute("GuiGrow")==1.22)
 check("author message survives Play",overlay.Messages.GoToEgg.Value=="QA edited Egg instruction")
 remote:InvokeServer("Started")
 if index==1 then
  remote:InvokeServer("Basic");task.wait(.5)
  check("ordinary Basic purchase",PC.request("OpenEgg","Basic","Open1"))
  check("hatch playing",HC.playing())
  for i=1,require(RS.Modules.Config).Hatch.clicks do HC.__QAAdvance();task.wait(.1)end
  task.wait(2);HC.__QAAdvance()
  waitFor(function()return step()=="OpenPets"end)
  MC.open("Inventory");waitFor(function()return step()=="Equip"end)
  check("ordinary Best Equip",PC.request("BestEquip"))
  waitFor(function()return PC.tutorialState().Completed end)
  check("one equipped",#require(RS.Modules.Pet).EquippedEntries(PC.state())==1)
  local other=remote:InvokeServer("CompletedA")
  check("other server not granted/completed",not other.Tutorial.Completed and not next(other.Pets.Owned) and other.Win==2)
  remote:InvokeServer("ResetA");waitFor(function()return PC.tutorialState() and not PC.tutorialState().Completed and not next(PC.state().Owned)end)
  MC.close();waitFor(function()return step()=="WaitingForWin"end)
  check("own reset clears progress/display",true)
 else
  local own=remote:InvokeServer("WaitA")
  check("own server unchanged by peer",not own.Tutorial.Completed and not next(own.Pets.Owned) and own.Win==2)
  check("own client unchanged by peer",not PC.tutorialState().Completed and not next(PC.state().Owned) and step()=="WaitingForWin")
  local other=remote:InvokeServer("StartB")
  waitFor(function()return step()=="GoToEgg"end)
  check("own guide starts independently",not other.Tutorial.Completed and other.Win==2)
 end
 check("template retained across steps",overlay.Canvas.Highlight.Outline.Thickness==1.125 and overlay.Canvas.Highlight:GetAttribute("GuiGrow")==1.22)
end,debug.traceback)
remote:InvokeServer("Report",{Passed=ok,Error=not ok and err or nil,Checks=checks})
