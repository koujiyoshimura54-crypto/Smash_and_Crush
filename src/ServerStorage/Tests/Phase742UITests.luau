-- Phase 7.4.2 compatibility entry point.
-- The current Merge UI contract is exercised by the Phase 7.4.3 suite.
local T={}
function T.Run()
 return require(game.ServerStorage.Tests.Phase743UITests).Run()
end
return T