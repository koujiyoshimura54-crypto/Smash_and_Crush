local RS=game.ReplicatedStorage
require(RS.Modules.ForgeClient).Completed:Connect(function(op,response)
 RS.__NightMeasure:FireServer('ClientEvent',{Remote='ForgeClient.Completed',Data={Type='Completed',Operation=op,Response=response}})
end)
