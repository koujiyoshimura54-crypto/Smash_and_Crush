assert(game.PlaceId==126576845524886)
assert(not _G.MobileHUDReview)
local SG=game:GetService("StarterGui")
assert(not SG:FindFirstChild("TouchGui"),"Existing TouchGui must be preserved")
local state={OriginalShow=SG.ShowDevelopmentGui,Fixtures={},Snapshots={}}
local gui=SG.StrengthGui:Clone();gui.Name="CodexOrientationReview";gui.Enabled=true;gui.DisplayOrder=10001
for _,x in gui:GetDescendants() do if x:IsA("LuaSourceContainer") then x:Destroy() end end
local backdrop=Instance.new("ScreenGui");backdrop.Name="CodexOrientationBackdrop";backdrop.DisplayOrder=10000;backdrop.IgnoreGuiInset=true
local bg=Instance.new("Frame");bg.BackgroundColor3=Color3.fromRGB(36,49,61);bg.Size=UDim2.fromScale(1,1);bg.Parent=backdrop
backdrop.Parent=SG;gui.Parent=SG;SG.ShowDevelopmentGui=true
local touch=Instance.new("ScreenGui");touch.Name="TouchGui";touch.DisplayOrder=10002;touch.IgnoreGuiInset=gui.IgnoreGuiInset;touch.Parent=SG
local function control(name,size,pos)
 local b=Instance.new("ImageLabel");b.Name=name;b.Size=size;b.Position=pos;b.BackgroundTransparency=.55;b.BackgroundColor3=Color3.fromRGB(80,180,230);b.Image="";b.BorderSizePixel=0;b.Active=false;b.Parent=touch
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=b
 return b
end
local start=control("ThumbstickStart",UDim2.fromOffset(70,70),UDim2.new(.08,0,.73,0))
local finish=control("ThumbstickEnd",UDim2.fromOffset(44,44),UDim2.new(.08,13,.73,13))
local jump=control("JumpButton",UDim2.fromOffset(70,70),UDim2.new(1,-100,1,-100))
local title=Instance.new("TextLabel");title.BackgroundTransparency=1;title.Text="Edit preview / simulated control bounds";title.TextColor3=Color3.new(1,1,1);title.TextSize=14;title.Position=UDim2.new(.3,0,0,0);title.Size=UDim2.new(.5,0,0,20);title.Parent=touch
local layoutSource=game.ReplicatedStorage.Modules.HUDLayout
local layout=assert(loadstring("return function(script)\n"..layoutSource.Source.."\nend"))()(layoutSource)
layout.Mount(gui)
function state.SetControls(mode)
 touch.Enabled=mode~="PC";start.Visible=mode=="Pressed";finish.Visible=mode=="Pressed";jump.Visible=true
end
function state.Snapshot(label)
 local left=gui.HUD.LeftHUD;local out={Label=label,Viewport=tostring(workspace.CurrentCamera.ViewportSize),GuiSize={gui.AbsoluteSize.X,gui.AbsoluteSize.Y},Base=gui:GetAttribute("LeftMenuBaseScale"),Final=gui:GetAttribute("LeftMenuFinalScale"),Ratio=gui:GetAttribute("LeftMenuAvoidanceRatio"),Buttons={},Overlaps={}}
 for _,slot in left:GetChildren() do if slot:IsA("Frame") then local b=gui.LeftMenu:FindFirstChild(slot.Name);if b then
 local input=b:IsA("GuiButton") and b or b:FindFirstChild("Button")
 local p,s=b.AbsolutePosition,b.AbsoluteSize
 table.insert(out.Buttons,{Name=b.Name,Position={p.X,p.Y},Size={s.X,s.Y},HitPosition=input and {input.AbsolutePosition.X,input.AbsolutePosition.Y},HitSize=input and {input.AbsoluteSize.X,input.AbsoluteSize.Y}})
 for _,r in layout.GetControls(SG) do if p.X<r.P.X+r.S.X and p.X+s.X>r.P.X and p.Y<r.P.Y+r.S.Y and p.Y+s.Y>r.P.Y then table.insert(out.Overlaps,b.Name.."/"..r.Name) end end
 end end end
 table.insert(state.Snapshots,out);return out
end
function state.Stop()
 gui:Destroy();touch:Destroy();backdrop:Destroy();SG.ShowDevelopmentGui=state.OriginalShow;_G.MobileHUDReview=nil
end
state.Gui=gui;state.Touch=touch;state.Start=start;state.Finish=finish;state.Layout=layout
state.SetControls("Released")
_G.MobileHUDReview=state
return "Temporary Edit preview created; no Play or input started."
