-- Isolated native Play probe; install only beside the memory-backed server fixture.
local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local pg=p:WaitForChild("PlayerGui")
local gui=pg:WaitForChild("StrengthGui")
local probe=gui:WaitForChild("__UI2Merge")
local oldView=probe:Invoke("View")
local overlay=pg:WaitForChild("OreMergeTutorialGui")
local qa=Instance.new("BindableFunction");qa.Name="__OreVisualQA"
local frame,view,stop
qa.OnInvoke=function(action)
 if action=="AuthoredStyle" then
  local h=overlay.Canvas.Highlight
  assert(h.Outline.Color==Color3.fromRGB(0,255,130) and h.Outline.Thickness==5)
  assert(h.Corner.CornerRadius.Offset==12 and h:GetAttribute("PaddingX")==10)
  probe:Invoke("Show");task.wait(.2)
  assert(overlay.Canvas.Message.Text=="Select Ore. [QA]")
  probe:Invoke("Tab","Ore");task.wait(.2)
  assert(h.Outline.Color==Color3.fromRGB(0,255,130) and h.Outline.Thickness==5)
  return true
 elseif action=="Narrow" then
  probe:Invoke("GuideStop");oldView:Hide()
  local screen=Instance.new("ScreenGui");screen.Name="__OreNarrowGui";screen.DisplayOrder=40;screen.ResetOnSpawn=false;screen.Parent=pg
  frame=Instance.new("Frame");frame.Name="Bounds";frame.Position=UDim2.fromOffset(20,20);frame.Size=UDim2.fromOffset(460,560)
  frame.BackgroundColor3=Color3.fromRGB(20,25,30);frame.Parent=screen
  local source=gui.ShopPanel:Clone();source.Visible=false;source.Parent=frame
  local pet=require(p.PlayerScripts.Services.PetClient)
  view=require(RS.Modules.MergeShopView)({gui=frame,RS=RS,PetClient=pet,Egg=require(RS.Modules.Egg),
   Master=require(RS.Config.ItemMaster),ItemColors={},PurchasedInventory=game.StarterGui.ScreenGui.Menus.Inventory.Main,
   EggViewport=require(RS.Modules.LimitedPetViewport),Input=game.UserInputService,GuiService=game.GuiService})
  overlay.Canvas.Position=UDim2.fromOffset(20,20);overlay.Canvas.Size=UDim2.fromOffset(460,560)
  stop=require(RS.Modules.OreMergeTutorialGuide).Mount(p,frame,view)
  view:Show();view:SelectTab("Ore");task.wait(.3)
  return view
 elseif action=="View" then return view
 elseif action=="Resize" then
  frame.Size=UDim2.fromOffset(400,520);overlay.Canvas.Size=UDim2.fromOffset(400,520);task.wait(.3);return view
 elseif action=="Stop" then
  if stop then stop();stop=nil end
  if view then view:Destroy();view=nil end
  local screen=pg:FindFirstChild("__OreNarrowGui");if screen then screen:Destroy() end
 end
end
qa.Parent=pg
