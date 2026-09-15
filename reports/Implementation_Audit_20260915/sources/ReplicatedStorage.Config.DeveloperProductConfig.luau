local C={}
C.ItemProducts=table.freeze({
 Epic=table.freeze({ProductId=3711755218,FallbackPrice=25}),
 Legendary=table.freeze({ProductId=3711755280,FallbackPrice=50}),
})
function C.GetItemProduct(rarity) return C.ItemProducts[rarity] end
function C.GetItemProductId(rarity)
 local item=C.GetItemProduct(rarity)
 return item and item.ProductId
end
function C.GetItemRarity(productId)
 for rarity,item in pairs(C.ItemProducts) do if item.ProductId==productId then return rarity end end
 return nil
end
return table.freeze(C)

