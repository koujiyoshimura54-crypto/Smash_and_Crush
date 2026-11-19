-- Edit-only property reapplication for the existing purchased-map event board.
-- Run this file once in the copy Studio; no timer, event logic or save operation.
local Style={
 BoardColor=Color3.fromRGB(24,24,24),
 BoardTransparency=0.5,
 EventName="Free Premium Treadmill",
 Title='<font color="#FFE066">FREE</font> PREMIUM TREADMILL',
 Description="3 MINUTES EVERY 30 MINUTES",
 TextColor=Color3.fromRGB(255,255,255),
 Font=Enum.Font.FredokaOne,
 TitleTextSize=48,
 DescriptionTextSize=40,
 TitleSize=UDim2.fromScale(.90,.30),
 DescriptionSize=UDim2.fromScale(.90,.20),
 RowGap=UDim.new(.04,0),
}
assert(game.PlaceId==126576845524886 and game.GameId==10765181857,"Wrong target Studio")
assert(not game:GetService("RunService"):IsRunning(),"Edit only")
local root=assert(workspace:FindFirstChild("EventBoard"),"Existing EventBoard required")
local board=assert(root:FindFirstChild("Board"))
local frame=assert(root:FindFirstChild("Part"))
local gui=assert(board:FindFirstChild("SurfaceGui"))
assert(board:IsA("BasePart") and frame:IsA("BasePart") and gui:IsA("SurfaceGui"))
-- Its old weather renderer writes these labels only through disabled Main.
-- Do not enable that loader or modify weather/treadmill effects here.
assert(game.StarterPlayer.StarterPlayerScripts.Main.Disabled and game.ServerScriptService.Main.Disabled,
 "Review active weather renderer before applying static board text")
for _,part in {board,frame} do
 part.Color=Style.BoardColor
 part.Transparency=Style.BoardTransparency
end
-- Hide only the existing face's stud texture; retain its asset/tiling for editing.
local texture=board:FindFirstChild("Texture")
if texture and texture:IsA("Texture") then texture.Transparency=1 end
root:SetAttribute("DisplayEventName",Style.EventName)
for index,name in {"Event1","Event2"}do
 local label=assert(gui:FindFirstChild(name))
 assert(label:IsA("TextLabel"))
 label.Visible=true
 label.Text=index==1 and Style.Title or Style.Description
 label.RichText=index==1
 label.AutoLocalize=false
 label.TextTransparency=0
 label.BackgroundTransparency=1
 label.TextColor3=Style.TextColor
 label.Font=Style.Font
 label.TextScaled=false
 label.TextWrapped=false
 label.TextSize=index==1 and Style.TitleTextSize or Style.DescriptionTextSize
 label.TextTruncate=Enum.TextTruncate.None
 label.Size=index==1 and Style.TitleSize or Style.DescriptionSize
 label.TextXAlignment=Enum.TextXAlignment.Center
 label.TextYAlignment=Enum.TextYAlignment.Center
end
local unused=assert(gui:FindFirstChild("Event3"))
unused.Text="";unused.Visible=false
local layout=assert(gui:FindFirstChildOfClass("UIListLayout"))
layout.Padding=Style.RowGap
layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
layout.VerticalAlignment=Enum.VerticalAlignment.Center
return {Target=root:GetFullName(),Title=gui.Event1.Text,Description=gui.Event2.Text}
