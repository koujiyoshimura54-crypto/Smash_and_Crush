assert(game:GetService("RunService"):IsStudio()and game.ReplicatedStorage:FindFirstChild("__ThreeFixMemory"))
local p=assert(game.Players:GetPlayers()[1]);local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService);local I=require(S.ItemService);local R=require(S.RunInventoryService)
local q=game.ReplicatedStorage.__ThreeFixQA
local call=Instance.new("BindableFunction");call.Name="Extra";call.Parent=q
call.OnInvoke=function(action)
 if action=="Purchase"then
  D.SetWin(p,1000)
  local before=I.GetItemCount(p,"PROTEIN_COMMON_FIRE")
  local ok,why=I.PurchaseItemWithWin(p,"PROTEIN_COMMON_FIRE")
  return {OK=ok,Code=why,Before=before,After=I.GetItemCount(p,"PROTEIN_COMMON_FIRE"),Win=p:GetAttribute("Win")}
 elseif action=="Drop"then
  local run=R.Reset(p,true);local id=game.HttpService:GenerateGUID(false)
  local ok,why=R.TryAddDrop(p,run,id,"GLOVE_LEGENDARY_ELECTRIC")
  assert(ok,why)
  game.ReplicatedStorage.Remotes.EnemyDropGachaResult:FireClient(p,{OwnerUserId=p.UserId,Id=id,RunId=run,WorldId=1,Outcome="ITEM",ItemId="GLOVE_LEGENDARY_ELECTRIC"})
  return {Added=ok,Code=why}
 end
end
