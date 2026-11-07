-- Definition-based owned-Item sale. Battle Bag quantities never enter this API.
local Master=require(script.Parent.Parent.Config.ItemMaster)
local WinAmount=require(script.Parent.WinAmount)
local M={}
function M.UnitPrice(id)
 local item=Master.Get(id)
 if not item then return nil,"InvalidItemId" end
 if item.RobuxPurchasable and not item.ShopPurchasable then return nil,"RobuxOnlyItem" end
 local price=item.WinPrice
 if not item.ShopPurchasable or typeof(price)~="number" or price~=price or price<=0 or price==math.huge then return nil,"NoWinPurchasePrice" end
 local unit=WinAmount.Normalize(price/2)
 if unit<=0 then return nil,"NoSaleValue" end
 return unit
end
function M.Available(id,owned,equipped)
 local item=Master.Get(id)
 local count=owned and owned[id] or 0
 return math.max(0,count-(item and equipped and equipped[item.ItemType]==id and 1 or 0))
end
return table.freeze(M)
