local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local pg=p:WaitForChild("PlayerGui")
local services=script.Parent.Services
local PC=require(services.PetClient)
local MC=require(services.MenuClient)
local HC=require(services.HatchClient)
local Connections=require(RS.__EggQAConnections)
local function waitFor(fn)
 for i=1,200 do local v=fn();if v then return v end;task.wait(.1)end error("Client fixture timeout")
end
waitFor(function()return PC.state() and pg:FindFirstChild("EggPetTutorialGui")end)
local overlay=pg.EggPetTutorialGui
local originalCanvas={Position=overlay.Canvas.Position,Size=overlay.Canvas.Size}
local history={};local last
local rendered=0
game.RunService.RenderStepped:Connect(function()rendered+=1 end)
game.RunService.Heartbeat:Connect(function()
 local s=overlay:GetAttribute("Step")
 if s~=last then last=s;table.insert(history,{Step=s,At=os.clock(),Arrow=typeof(p:GetAttribute("EggTutorialTarget"))=="Vector3"})end
end)
local function rect(x)return x and {X=x.AbsolutePosition.X,Y=x.AbsolutePosition.Y,W=x.AbsoluteSize.X,H=x.AbsoluteSize.Y}end
local function status()
 local line=overlay.Canvas.Notification.Stack:FindFirstChild("PinnedLine")
 local sheet=pg.ScreenGui:FindFirstChild("Basic");local target=sheet and sheet.Opens.Open1
 local route=workspace:FindFirstChild("TutorialGuide")
 local lines=0;for _,x in overlay.Canvas.Notification.Stack:GetChildren()do if x.Name=="PinnedLine"then lines+=1 end end
 return {Step=overlay:GetAttribute("Step"),Target=overlay:GetAttribute("Target"),Arrow=tostring(p:GetAttribute("EggTutorialTarget")),
  OreStep=pg.OreMergeTutorialGui:GetAttribute("Step"),Owner=tostring(require(RS.Modules.TutorialPresentationCoordinator).Owner()),
  Focus=rect(overlay.Canvas.Highlight),FocusVisible=overlay.Canvas.Highlight.Visible,Message=line and line.Message.Text,MessageRect=line and rect(line.Message),
  Proxy=rect(overlay.Canvas.TargetProxy),Canvas=rect(overlay.Canvas),Lines=lines,Rendered=rendered,
  Sheet=sheet and {Enabled=sheet.Enabled,Size=tostring(sheet.AbsoluteSize),Target=rect(target),Offset=tostring(sheet.StudsOffsetWorldSpace)},
  Tutorial=PC.tutorialState(),Pets=PC.state(),Busy=PC.busy(),Hatch=HC.playing(),Menu=MC.shown()}
end
local probe=Instance.new("BindableFunction");probe.Name="__EggQAProbe"
probe.OnInvoke=function(action,v)
 if action=="Status"then return status()
 elseif action=="History"then return history
 elseif action=="Refresh"then PC.refresh()
 elseif action=="ClickOpen"then return Connections.Fire(pg.ScreenGui.Basic.Opens.Open1.Button,"Activated")
 elseif action=="OpenRequest"then task.spawn(PC.request,"OpenEgg","Basic","Open1")
 elseif action=="AdvanceHatch"then HC.__QAAdvance()
 elseif action=="OpenPets"then return Connections.Fire(pg.StrengthGui.LeftMenu.PetsButton.Button,"Activated")
 elseif action=="BestEquip"then return Connections.Fire(pg.ScreenGui.Menus.Inventory.Main.PetBestEquip.Button,"Activated")
 elseif action=="ClosePets"then return Connections.Fire(pg.ScreenGui.Menus.Inventory.Exit.Button,"Activated")
 elseif action=="Equip"then task.spawn(PC.request,"Equip",v)
 elseif action=="Notification"then require(services.NotifyClient).push({{text="QA reward notification"}})
 elseif action=="Offline"then pg.StrengthGui.OfflineRewards.Visible=v
 elseif action=="Narrow"then
  local width=v or 460
  overlay.Canvas.Size=UDim2.fromOffset(width,540);overlay.Canvas.Position=UDim2.fromOffset(10,0)
  pg.ScreenGui.Menus.Inventory.Size=UDim2.fromOffset(width-80,430)
  pg.ScreenGui.Menus.Inventory.Position=UDim2.fromOffset(width/2,290)
 elseif action=="ReplayResponse"then PC.__QAAccept(v)
 else error(action)end
 return status()
end
probe.Parent=p.PlayerScripts
print("[Egg QA] native client ready")
