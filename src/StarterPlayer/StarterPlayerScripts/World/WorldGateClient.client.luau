local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(RS:WaitForChild("Config"):WaitForChild("WorldGateConfig"))
local remote=RS:WaitForChild("Remotes"):WaitForChild("WorldTravelRequest")
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("WorldTravelGui")
local modal=gui:WaitForChild("Modal")
local card=modal:WaitForChild("Card")
local title=card:WaitForChild("Title")
local prompt=card:WaitForChild("Prompt")
local yes=card:WaitForChild("YesButton")
local no=card:WaitForChild("NoButton")
local activeTarget
local wasInsideTarget
local suppressedUntilExit=false
local requestPending=false
local world2Gate

local function world2Unlocked()
 local value=player:GetAttribute("HighestUnlockedWorld")
 return typeof(value)=="number" and value>=Config.RequiredWorld
end

local function refreshWorld2Gate()
 local gate=world2Gate
 if not gate or not gate.Parent then return end
 local portal=gate:FindFirstChild("PortalSurface")
 local sign=gate:FindFirstChild("Sign")
 local anchor=sign and sign:FindFirstChild("SignAnchor")
 local surface=anchor and anchor:FindFirstChild("WorldLabel")
 local gateTitle=surface and surface:FindFirstChild("Title")
 local subtitle=surface and surface:FindFirstChild("Subtitle")
 local canEnter=world2Unlocked()
 local style=canEnter and Config.Unlocked or Config.Locked
 if portal and portal:IsA("BasePart") then
  portal.Color=style.Color;portal.Material=style.Material;portal.Transparency=style.Transparency
 end
 if gateTitle then gateTitle.Text=Config.Title;gateTitle.TextColor3=style.TextColor;gateTitle.TextStrokeTransparency=canEnter and 1 or .15 end
 if subtitle then subtitle.Text=canEnter and Config.UnlockedText or Config.LockedText;subtitle.TextColor3=style.TextColor;subtitle.TextStrokeTransparency=canEnter and 1 or .15 end
 gate:SetAttribute("LocallyUnlocked",canEnter)
 if not canEnter and activeTarget=="ToWorld2" then modal.Visible=false end
end

local function isInside(trigger,root)
 local p=trigger.CFrame:PointToObjectSpace(root.Position)
 local half=trigger.Size*.5
 return math.abs(p.X)<=half.X and math.abs(p.Y)<=half.Y and math.abs(p.Z)<=half.Z
end

local function gateDefinitions()
 local result={}
 local enter=workspace:FindFirstChild(Config.GateName)
 if enter then
  result[#result+1]={Model=enter,Action="ToWorld2",Title="WORLD 2",Prompt="Travel to World 2?",Allowed=world2Unlocked()}
 end
 local world2=workspace:FindFirstChild("World2Map")
 local training=world2 and world2:FindFirstChild("TrainingArea")
 local returnGate=training and training:FindFirstChild("World1ReturnGate")
 if returnGate then
  result[#result+1]={Model=returnGate,Action="ReturnWorld1",Title="WORLD 1",Prompt="Return to World 1?",Allowed=player:GetAttribute("CurrentWorld")==2}
 end
 return result
end

local function closeAndSuppress()
 modal.Visible=false
 suppressedUntilExit=true
end

yes.Activated:Connect(function()
 if requestPending or not modal.Visible or not activeTarget then return end
 requestPending=true;yes.Active=false;no.Active=false
 local action=activeTarget
 closeAndSuppress()
 remote:FireServer(action)
 task.delay(1,function() requestPending=false;yes.Active=true;no.Active=true end)
end)
no.Activated:Connect(function()
 if modal.Visible then closeAndSuppress() end
end)

player:GetAttributeChangedSignal("HighestUnlockedWorld"):Connect(refreshWorld2Gate)
RunService.Heartbeat:Connect(function()
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local insideDefinition
 if root then
  for _,definition in ipairs(gateDefinitions()) do
   local trigger=definition.Model:FindFirstChild("WorldGateTrigger")
   if trigger and trigger:IsA("BasePart") and isInside(trigger,root) then insideDefinition=definition;break end
  end
 end
 local insideTarget=insideDefinition and insideDefinition.Action or nil
 if not insideTarget then
  if wasInsideTarget then modal.Visible=false end
  wasInsideTarget=nil;activeTarget=nil;suppressedUntilExit=false
  return
 end
 if insideTarget~=wasInsideTarget then
  wasInsideTarget=insideTarget
  activeTarget=insideTarget
  if insideDefinition.Allowed and not suppressedUntilExit and not requestPending then
   title.Text=insideDefinition.Title
   prompt.Text=insideDefinition.Prompt
   modal.Visible=true
  else
   modal.Visible=false
  end
 end
end)

workspace.ChildAdded:Connect(function(child)
 if child.Name==Config.GateName and child:IsA("Model") then world2Gate=child;refreshWorld2Gate() end
end)
workspace.ChildRemoved:Connect(function(child)
 if child==world2Gate then world2Gate=nil;if activeTarget=="ToWorld2" then modal.Visible=false end end
end)
world2Gate=workspace:FindFirstChild(Config.GateName)
refreshWorld2Gate()
