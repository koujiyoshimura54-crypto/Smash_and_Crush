-- Edit-only native layout test. First run tests/MobileHUDPreviewEdit.luau.
-- Control geometry is simulated; no physical input or gameplay Play occurs.
local s=assert(_G.MobileHUDReview,"Run MobileHUDPreviewEdit first")
local svc=game:GetService("StudioDeviceSimulatorService")
local assertions=0
local function check(ok,label)assert(ok,label);assertions+=1 end
local function settle() task.wait(.2);game:GetService("RunService").RenderStepped:Wait();game:GetService("RunService").RenderStepped:Wait() end -- Harness yields for native deferred layout, not production policy.
local cases={}
for _,id in {"iphone_7","iphone_16_pro_max","ipad_pro_M5_13in"} do
 svc:SetDeviceAsync(id);svc:SetOrientationAsync(Enum.ScreenOrientation.LandscapeLeft)
 s.SetControls("Released");settle()
 local normal=s.Gui:GetAttribute("LeftMenuBaseScale")
 check(math.abs(s.Gui:GetAttribute("LeftMenuFinalScale")-normal)<1e-6,id.." normal size")
 for _,y in {0,.25,.35,.5,.73,.85,1} do
  s.Start.Position=UDim2.new(.08,0,y,0);s.Finish.Position=UDim2.new(.08,13,y,13)
  s.SetControls("Pressed");settle()
  local g=s.Gui
  local base,final=g:GetAttribute("LeftMenuBaseScale"),g:GetAttribute("LeftMenuFinalScale")
  check(math.abs(base-normal)<1e-6,string.format("baseline independent of joystick position %s y %.2f normal %.6f base %.6f",id,y,normal,base))
  check(final>=normal*.70-1e-6,"final floor")
  check(g.HUD.LeftHUD.UIGridLayout.FillDirectionMaxCells==2,"two columns")
  for _,slot in g.HUD.LeftHUD:GetChildren() do if slot:IsA("Frame") then local b=g.LeftMenu:FindFirstChild(slot.Name)
   if b then
    local input=b:IsA("GuiButton") and b or b:FindFirstChild("Button")
    check(b.AbsoluteSize.X>=slot:GetAttribute("DesignSize").X*normal*.70-.02,"paint size floor")
    check(input and (input.AbsoluteSize-b.AbsoluteSize).Magnitude<.02 and (input.AbsolutePosition-b.AbsolutePosition).Magnitude<.02,"paint and hit geometry")
   end
  end end
  table.insert(cases,{Device=id,StickY=y,Base=base,Final=final,Ratio=final/base})
 end
 for i=1,3 do
  s.SetControls("Released");settle()
  check(math.abs(s.Gui:GetAttribute("LeftMenuFinalScale")-normal)<1e-6,"release restores normal")
  check(s.Layout.Mount(s.Gui)==s.Layout.Mount(s.Gui),"mount idempotent")
 end
 svc:SetOrientationAsync(Enum.ScreenOrientation.Portrait);settle()
 check(s.Gui.AbsoluteSize.X<s.Gui.AbsoluteSize.Y,"portrait dimensions observed")
 svc:SetOrientationAsync(Enum.ScreenOrientation.LandscapeRight);settle()
 check(s.Gui.AbsoluteSize.X>s.Gui.AbsoluteSize.Y,"right landscape reflow")
 check(math.abs(s.Gui:GetAttribute("LeftMenuBaseScale")-normal)<1e-6,"landscape baseline restored")
end
s.SetControls("PC");svc:SetDeviceAsync("average_windows");settle()
return game.HttpService:JSONEncode({Assertions=assertions,Cases=cases,Kind="Native Edit layout with synthetic control bounds"})
