local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local player=game:GetService("Players").LocalPlayer
local chat=game:GetService("TextChatService")
player:GetAttributeChangedSignal("StudioDebugMessageSequence"):Connect(function()
 local channels=chat:FindFirstChild("TextChannels")
 local channel=channels and (channels:FindFirstChild("RBXSystem") or channels:FindFirstChild("RBXGeneral"))
 if channel then channel:DisplaySystemMessage(player:GetAttribute("StudioDebugMessage") or "") end
end)

