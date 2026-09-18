-- Phase 7.4.2: three identical regular items become one next-rarity item.
local Players=game:GetService("Players")
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local Items=require(game.ServerScriptService.Services.ItemService)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local M={}
local MergeConfig=require(game.ReplicatedStorage.Config:WaitForChild("ItemMergeConfig"))
local nextRarity=Master.NextRarity
local prefixes=Master.TypePrefixes
local elements=Master.ElementSet
function M.GetMergeResult(itemId)
 local item=Master.Get(itemId)
 if not item then return nil,"InvalidItemId" end
 local nextName=nextRarity[item.Rarity]
 if not nextName or item.Mergeable~=true then return nil,"NotMergeable" end
 local prefix=prefixes[item.ItemType]
 if not prefix or not elements[item.Element] then return nil,"InvalidItemDefinition" end
 if item.ItemId~=itemId or itemId~=prefix.."_"..item.Rarity:upper().."_"..item.Element:upper() then return nil,"InvalidItemDefinition" end
 local resultId=prefix.."_"..nextName:upper().."_"..item.Element:upper()
 local result=Master.Get(resultId)
 if not result or result.ItemId~=resultId or result.ItemType~=item.ItemType
  or result.Element~=item.Element or result.Rarity~=nextName then return nil,"InvalidMergeResult" end
 return resultId
end
function M.CanMerge(player,itemId)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 local result,reason=M.GetMergeResult(itemId)
 if not result then return false,reason end
 if not Data.IsLoaded(player) then return false,"DataNotLoaded" end
 if Data.IsSaving(player) then return false,"DataSaving" end
 if Items.GetItemCount(player,itemId)<MergeConfig.RequiredCount then return false,"NotEnoughItems" end
 if Items.GetItemCount(player,result)>=9007199254740991 then return false,"CountOverflow" end
 return true,result
end
function M.MergeItem(player,itemId)
 local allowed,result=M.CanMerge(player,itemId)
 if not allowed then return false,result end
 local changed,reason=Items.RunItemTransaction(player,function(transaction)
  local removed,removeError=Items.RemoveItem(player,itemId,MergeConfig.RequiredCount,transaction)
  if not removed then return false,removeError end
  return Items.AddItem(player,result,1,transaction)
 end)
 if not changed then return false,reason end
 Items.NotifyRegularItemGranted(player,result)
 return true,"Merged",result
end
return M
