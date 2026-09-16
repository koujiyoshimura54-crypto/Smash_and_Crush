-- Temporary Studio-only QA control. Removed after verification.
local Players=game:GetService("Players")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Dumbbells=require(game.ServerScriptService.Services.DumbbellService)
local control=Instance.new("Folder")
control.Name="DumbbellBuySeenQA"
control.Parent=workspace
local p=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
repeat task.wait(.1) until Data.Get(p) and Data.Get(p).Loaded
local function result(action,ok,detail)
 control:SetAttribute("Result",game:GetService("HttpService"):JSONEncode({Action=action,Success=ok,Detail=detail}))
end
control:GetAttributeChangedSignal("Action"):Connect(function()
 local action=control:GetAttribute("Action")
 local ok,detail=pcall(function()
  if action:match("^win:") then
   local amount=tonumber(action:match("^win:(.+)$"))
   assert(Data.SetWin(p,amount))
   return {Win=amount}
  elseif action:match("^purchase:") then
   local id=action:match("^purchase:(.+)$")
   local success,code=Dumbbells.PurchaseDumbbell(p,id)
   return {Success=success,Code=code,Owned=Dumbbells.HasDumbbell(p,id)}
  elseif action=="save" then
   local success,reason=Data.Save(p)
   return {Success=success,Reason=reason}
  elseif action=="snapshot" then
   local s=Data.Get(p)
   return {Win=p:GetAttribute("Win"),Owned=table.clone(s.Data.OwnedDumbbells),Seen=Data.GetInventoryNotificationSeen(p)}
  end
  error("Unknown action")
 end)
 result(action,ok,detail)
end)
control:SetAttribute("Ready",true)
