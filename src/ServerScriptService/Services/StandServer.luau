-- Phase 2: remove the retired GamePass-price path. Main remains disabled.
local Config=require(game.ReplicatedStorage.Config.LimitedEggConfig)
local M={}
function M.init()
 local model=workspace:FindFirstChild(Config.Entrance)
 local board=model and model:FindFirstChild("BillboardGui")
 if not board then return end
 board.Adornee=model.PrimaryPart
 board.AlwaysBetter.Text=Config.Name;board.AlwaysBetter.AutoLocalize=false
 board.Price.Text=string.format("%g Robux / 1 Pet",Config.BasePrice);board.Price.AutoLocalize=false
end
function M.start() M.init() end
return M
