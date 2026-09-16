local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players=game:GetService("Players")
local Chat=game:GetService("TextChatService")
local Debug=require(game.ServerScriptService.Systems.Debug.StudioDebugService)
local count=0
for _,alias in ipairs({"/resetdata","/setstrength","/setstage","/balance","/addwin","/setwin"}) do
 local command=Instance.new("TextChatCommand")
 command.Name="StudioDebug_"..alias:sub(2)
 command.PrimaryAlias=alias
 command.Triggered:Connect(function(source,message)
  if not RunService:IsStudio() or not source then return end
  local player=Players:GetPlayerByUserId(source.UserId)
  if not player then return end
  local ok,result=Debug.Execute(player,message)
  count+=1
  local text="[StudioDebug] "..(ok and "OK: " or "ERROR: ")..tostring(result)
  player:SetAttribute("StudioDebugMessage",text)
  player:SetAttribute("StudioDebugMessageSequence",count)
  print(player.Name.." "..text)
 end)
 command.Parent=Chat
end
