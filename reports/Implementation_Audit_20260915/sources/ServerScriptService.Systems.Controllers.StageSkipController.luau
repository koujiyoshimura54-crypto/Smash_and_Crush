local RS=game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local Skip=require(game.ServerScriptService.Services.StageSkipService)
local Receipts=require(game.ServerScriptService.Systems.Purchases.ReceiptService)
local folder=RS.Remotes:FindFirstChild("GameRemotes") or Instance.new("Folder")
folder.Name="GameRemotes"
folder.Parent=RS.Remotes
local event=folder:FindFirstChild("StageSkip") or Instance.new("RemoteEvent")
event.Name="StageSkip"
event.Parent=folder
Skip.Initialize(event)
-- Single global callback. Add future product handlers inside ReceiptService.
MarketplaceService.ProcessReceipt=Receipts.ProcessReceipt

