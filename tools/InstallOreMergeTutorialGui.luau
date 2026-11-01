-- Run once in Studio Edit. Existing owner-edited templates are never overwritten.
assert(not game:GetService("RunService"):IsRunning())
if game.StarterGui:FindFirstChild("OreMergeTutorialGui") then return "Template already exists; preserved" end
local RS=game.ReplicatedStorage
local gui=Instance.new("ScreenGui");gui.Name="OreMergeTutorialGui";gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false;gui.DisplayOrder=45;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local canvas=Instance.new("Frame");canvas.Name="Canvas";canvas.BackgroundTransparency=1
canvas.Size=UDim2.fromScale(1,1);canvas.Active=false;canvas.Parent=gui
local focus=RS.Assets.Tutorial.TutorialHighlight:Clone();focus.Name="Highlight"
focus.AnchorPoint=Vector2.zero;focus.Visible=false;focus.Active=false;focus.ZIndex=2
focus:SetAttribute("PaddingX",6);focus:SetAttribute("PaddingY",6)
for _,x in focus:GetChildren() do
 if x:IsA("UIStroke") then
  local outline=x.Color.R+x.Color.G+x.Color.B>1
  x.Name=outline and "Outline" or "Shadow";x.Thickness=outline and 3 or 6
  x.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
 elseif x:IsA("UICorner") then x.Name="Corner";x.CornerRadius=UDim.new(0,8) end
end
focus.Parent=canvas
-- Purchased notification typography/gradient, retained as an editable authored label.
local note=game.StarterGui.ScreenGui.Menus.RestockShop.Main.Common.Buy.Main.Amount:Clone()
note.Name="Message";note.AnchorPoint=Vector2.new(.5,0);note.Position=UDim2.fromScale(.5,.02)
note.Size=UDim2.new(.85,0,0,56);note.BackgroundTransparency=0;note.BackgroundColor3=Color3.fromRGB(25,25,30);note.Visible=false;note.Active=false
note.Text="";note.AutoLocalize=false;note.TextWrapped=true;note.TextScaled=true;note.ZIndex=3
for _,x in note:GetChildren() do if not x:IsA("UIStroke") then x:Destroy() end end
note:SetAttribute("MaxWidth",500);note:SetAttribute("Gap",10)
note:SetAttribute("HeaderWidthScale",.70);note:SetAttribute("HeaderCenterX",.50);note:SetAttribute("HeaderInset",4)
local noteCorner=Instance.new("UICorner");noteCorner.CornerRadius=UDim.new(0,8);noteCorner.Parent=note
local limit=Instance.new("UITextSizeConstraint");limit.MinTextSize=12;limit.MaxTextSize=26;limit.Parent=note
local colors=require(RS.Modules.Config).Tutorial
local gradient=Instance.new("UIGradient");gradient.Rotation=90;gradient.Color=ColorSequence.new(colors.from,colors.to);gradient.Parent=note
note.Parent=canvas
local text=Instance.new("Folder");text.Name="Messages";text.Parent=gui
for name,value in {GoToMerge="Go to Merge to create a dumbbell!",ChooseOre="Select Ore.",
 AddOres="Tap ore cards to add 2–5. Tap again for another.",Merge="Press Merge to create a dumbbell!",Saving="Creating your dumbbell…"} do
 local x=Instance.new("StringValue");x.Name=name;x.Value=value;x.Parent=text
end
gui.Parent=game.StarterGui
return gui:GetFullName()
