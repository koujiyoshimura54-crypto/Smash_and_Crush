local handle=require(game.ReplicatedStorage.Modules.RewardedStrengthBoostClient).Mount(script.Parent)
script.Destroying:Once(handle.Destroy)
