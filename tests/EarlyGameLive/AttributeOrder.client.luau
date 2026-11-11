local p=game.Players.LocalPlayer;local q=game.ReplicatedStorage.__EarlyQABoundary
q.Request:InvokeServer("Seed",{Level=2,Progress=0,Strength=7,Rebirth=0});task.wait(.3)
local results={}
for _,order in {{"Level","Strength"},{"Strength","Level"}}do
 p:SetAttribute("Level",nil);p:SetAttribute("Strength",nil);p:SetAttribute("LevelProgress",0);task.wait(.3)
 local trace={}
 for _,name in order do p:SetAttribute(name,name=="Level"and 2 or 7);task.wait(.3);table.insert(trace,workspace.TutorialFloorGuide:GetAttribute("Target"))end
 assert(workspace.TutorialFloorGuide:GetAttribute("Target")=="Treadmill")
 p:SetAttribute("Strength",10);task.wait(.3);assert(workspace.TutorialFloorGuide:GetAttribute("Target")=="Wall1.1")
 local targetChanges=0;local last="Wall1.1";for i=1,60 do task.wait();local t=workspace.TutorialFloorGuide:GetAttribute("Target");if t~=last then targetChanges+=1;last=t end end
 assert(targetChanges==0);table.insert(results,{Order=order,Trace=trace,After10=last,ChangesIn60Frames=targetChanges})
end
p:SetAttribute("Strength",7);p:SetAttribute("Level",2);p:SetAttribute("LevelProgress",0)
return results
