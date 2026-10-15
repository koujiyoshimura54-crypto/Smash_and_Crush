-- Only legacy Smash PlayerData; no purchased Data or Marketplace startup.
local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local Pet=require(game.ReplicatedStorage.Modules.Pet)
local M={}
function M.GetStrengthMultiplier(player)
 if player.Parent~=Players or (player:GetAttribute("CurrentWorld") or 1)~=1 then return 1 end
 local session=Data.Get(player)
 if not session or not session.Loaded or not session.Data or session.OwnershipLost then return 1 end
 -- Read the committed server session directly; no client mirror/cache and no
 -- per-tick copy of the entire owned inventory. Only its owned equipped ID counts.
 return Pet.StrengthMultiplier(session.Data.Pets)
end
function M.state(player)
 local state,reason=Data.GetPetState(player)
 return state,reason
end
function M.equip(player,id,requestId,revision)
 if type(id)~="string" or #id>128 then return false,"InvalidPet" end
 local state,reason=M.state(player)
 if not state then return false,reason end
 if not state.Owned[id] then return false,"PetNotOwned" end
 if not Pet.model(state.Owned[id]) then return false,"PetModelUnavailable" end
 return Data.MutatePets(player,requestId,revision,"Equip",id)
end
function M.publish(player)
 local state=M.state(player)
 if state then Pet.Publish(player,state) end
end
function M.start()
 -- Load/reset and confirmed transactions publish Pet/Pet2 in PlayerDataService.
 for _,player in ipairs(Players:GetPlayers()) do M.publish(player) end
end
return M
