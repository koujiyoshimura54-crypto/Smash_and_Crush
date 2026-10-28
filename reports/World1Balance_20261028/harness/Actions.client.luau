-- QA bridge to the same regular Item/Pet client request paths used by UI.
local p=game.Players.LocalPlayer;local RS=game.ReplicatedStorage
local b=Instance.new('BindableFunction');b.Name='__BalanceActions';b.Parent=p.PlayerScripts
b.OnInvoke=function(op,a)
 if op=='ItemMerge'then
  local state=RS.Remotes.ItemMergeState:InvokeServer()
  local preview,reason=require(RS.Config.ItemMergeConfig).Evaluate(a,state.OwnedItems,state.World2Unlocked)
  if not preview then return {Sent=false,Reason=reason}end
  local req={RequestId=game.HttpService:GenerateGUID(false),SessionToken=state.SessionToken,Sequence=state.NextSequence,Materials=a}
  RS.Remotes.ItemMergeRequest:FireServer(req)
  RS.__NightMeasure:FireServer('Phase','operations','Normal Item Merge request')
  return {Sent=true,Request=req,Preview=preview}
 end
 if op=='ItemState'then return RS.Remotes.ItemMergeState:InvokeServer()end
 if op=='PetState'then local c=require(p.PlayerScripts.Services.PetClient);c.refresh();return c.state()end
 if op=='PetRequest'then
  local c=require(p.PlayerScripts.Services.PetClient);c.refresh()
  task.spawn(c.request,a.Action,a.A,a.B)
  return {Started=true}
 end
end
