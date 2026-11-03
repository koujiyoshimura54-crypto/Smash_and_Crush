local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local services=script.Parent.Services
local PC=require(services.PetClient)
local HC=require(services.HatchClient)
local function waitFor(fn,seconds)
 local t=os.clock()+(seconds or 25)
 repeat local x=fn();if x then return x end;task.wait(.1)until os.clock()>t
 error("PM multiplayer client timeout")
end
local remote=RS:WaitForChild("__PMMulti")
local index=remote:InvokeServer("Ready")
local checks={}
local ok,err=xpcall(function()
 local overlay=p.PlayerGui:WaitForChild("PetMergeTutorialGui")
 local function step()return overlay:GetAttribute("Step")end
 local function check(name,value)assert(value,name);table.insert(checks,name)end
 local function hatch()
  waitFor(function()return HC.playing()end)
  for i=1,require(RS.Modules.Config).Hatch.clicks do HC.__QAAdvance();task.wait(.2)end
  task.wait(2);HC.__QAAdvance();waitFor(function()return not HC.playing()end)
 end
 local function merge()
  remote:InvokeServer("MergeArea")
  local view=waitFor(function()return _G.__PMView end)
  waitFor(function()return view.Root.Visible end)
  view:SelectTab("Pet");view:SetPetState(PC.state())
  view:ActivateMaterial("Grey Cat");view:ActivateMaterial("Dog")
  check("ordinary selected two",view:GetPetTutorialState().Valid)
  view:SubmitItem()
  hatch()
  waitFor(function()return PC.mergeTutorialState().Completed end)
  check("two consumed and one granted",not PC.state().Owned["copy-a"]and not PC.state().Owned["copy-b"]and #PC.state().LastResults==1)
 end
 waitFor(function()return step()=="GoToMerge"end)
 check("authored outline survives Play",math.abs(overlay.Canvas.Highlight.Outline.Thickness-.035)<.0001)
 check("authored shadow survives Play",math.abs(overlay.Canvas.Highlight.Shadow.Transparency-.35)<.0001)
 check("authored growth survives Play",overlay.Canvas.Highlight:GetAttribute("GuiGrow")==1.22)
 check("authored message survives Play",overlay.Messages.GoToMerge.Value=="QA edited Pet Merge instruction")
 remote:InvokeServer("Started")
 if index==1 then
  merge()
  local other=remote:InvokeServer("CompletedA")
  check("peer still owns both original copies",other.Pets.Owned["copy-a"]=="Grey Cat"and other.Pets.Owned["copy-b"]=="Dog"and not other.Tutorial.Completed)
  remote:InvokeServer("ResetA")
  waitFor(function()return PC.mergeTutorialState()and not PC.mergeTutorialState().Completed and not next(PC.state().Owned)end)
  waitFor(function()return step()=="WaitingForPets"end)
  check("own reset clears progress and presentation",true)
 else
  local own=remote:InvokeServer("WaitA")
  check("peer merge did not alter own server",not own.Tutorial.Completed and own.Pets.Owned["copy-a"]=="Grey Cat"and own.Pets.Owned["copy-b"]=="Dog")
  check("peer merge did not alter own client",not PC.mergeTutorialState().Completed and step()=="GoToMerge"and PC.state().Owned["copy-a"]=="Grey Cat")
  local other=remote:InvokeServer("StartB")
  check("peer reset did not alter own materials",PC.state().Owned["copy-b"]=="Dog"and not other.Tutorial.Completed and not next(other.Pets.Owned))
  merge()
  other=remote:InvokeServer("CheckA")
  check("own merge did not grant to reset peer",not other.Tutorial.Completed and not next(other.Pets.Owned))
 end
 check("author values survive step changes",overlay.Canvas.Highlight:GetAttribute("GuiGrow")==1.22)
end,debug.traceback)
remote:InvokeServer("Report",{Passed=ok,Error=not ok and err or nil,Checks=checks})
