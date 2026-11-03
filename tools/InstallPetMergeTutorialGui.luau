-- Edit-only installer: existing authored Pet merge templates are never overwritten.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local sg=game:GetService("StarterGui")
if sg:FindFirstChild("PetMergeTutorialGui") then return sg.PetMergeTutorialGui end
local gui=sg:WaitForChild("OreMergeTutorialGui"):Clone()
gui.Name="PetMergeTutorialGui";gui:SetAttribute("TutorialPhase",2);gui:SetAttribute("CompletionSeconds",2.5)
gui:SetAttribute("Step",nil);gui:SetAttribute("Target",nil)
for _,x in gui.Messages:GetChildren() do x:Destroy() end
for name,value in {GoToMerge="Go to Merge!",ChoosePet="Select Pets.",AddPets="Add 2 unequipped Pets.",AddAnother="Add one more Pet.",ScrollPets="Scroll to an available Pet.",Merge="Merge your Pets.",Complete="Pet merge complete!"} do
 local v=Instance.new("StringValue");v.Name=name;v.Value=value;v.Parent=gui.Messages
end
gui.Parent=sg
return gui
