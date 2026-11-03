-- Edit-only clone of the CURRENT approved Ore template. Existing Egg edits are preserved.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning(),"Canonical Edit only")
if game.StarterGui:FindFirstChild("EggPetTutorialGui") then return "Existing Egg template preserved" end
local gui=game.StarterGui:WaitForChild("OreMergeTutorialGui"):Clone()
gui.Name="EggPetTutorialGui";gui:SetAttribute("Step",nil);gui:SetAttribute("Target",nil)
gui:SetAttribute("CompletionSeconds",2.5)
gui:SetAttribute("TutorialPhase",1)
for _,x in gui.Messages:GetChildren() do x:Destroy() end
for name,text in {GoToEgg="Go to the Basic Egg!",OpenOne="Open 1 Egg.",OpenPets="Open your Pets.",Equip="Press Best Equip.",Complete="Pet equipped!"} do
 local x=Instance.new("StringValue");x.Name=name;x.Value=text;x.Parent=gui.Messages
end
local canvas=gui.Canvas
canvas.Highlight.Visible=false;canvas.Notification.Visible=false
local function region(name,position,size)
 local x=Instance.new("Frame");x.Name=name;x.BackgroundTransparency=1;x.BorderSizePixel=0
 x.Active=false;x.Selectable=false;x.Interactable=false;x.Size=size;x.Position=position;x.Parent=canvas;return x
end
local proxy=region("TargetProxy",UDim2.new(),UDim2.new());proxy.Visible=false
local header=region("NotificationRegion",UDim2.fromScale(.5,.045),UDim2.fromScale(.8,.065))
header.AnchorPoint=Vector2.new(.5,0)
gui.Parent=game.StarterGui
return gui:GetFullName()
