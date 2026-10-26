-- World1 ore definitions. Reserved rows 17..20 are not obtainable or spendable.
local M = {Version = "World1Ore1"}
local rows = {
 {"Stone",5,1,131452437678251}, {"Coal",7,3,83727497047517},
 {"Iron",9,5,111308943708149}, {"Copper",11,7,106917824814020},
 {"Quartz",15,9,98802386870713}, {"Silver Stone",20,10,92842832362846},
 {"Sand Crystal",25,15,100254430391832}, {"Brown Ore",30,20,90313945125672},
 {"Rock Core",35,25,74885090507086}, {"Gray Crystal",40,30,131216796823283},
 {"Amber",55,35,122870709116506}, {"Topaz",65,40,95006906073775},
 {"Jade",75,45,80400820880542}, {"Aqua Crystal",85,50,111060074263221},
 {"Forest Stone",100,55,133113647660531}, {"Spark Ore",130,65,103644070407489},
 {"Sunstone",150,nil,136139361458479}, {"Moon Quartz",170,nil,136614965232146},
 {"Blue Crystal",190,nil,95334159293900}, {"Green Core",220,nil,99321545969483},
}
local names={"Common","Uncommon","Rare","Super Rare"}
local colors={Color3.fromRGB(145,151,160),Color3.fromRGB(72,193,86),Color3.fromRGB(54,144,245),Color3.fromRGB(180,69,247)}
local byId,ordered={},{}
for index,row in ipairs(rows) do
 local rank=math.ceil(index/5)
 local ore=table.freeze({Id=string.format("ORE_%03d",index),Index=index,Name=row[1],Points=row[2],SellWin=row[3],
  Image="rbxassetid://"..row[4],RarityId=string.format("RARITY_%02d",rank),Rarity=names[rank],Color=colors[rank],Available=index<=16})
 byId[ore.Id]=ore
 if ore.Available then table.insert(ordered,ore) end
end
local pools={
 {{1,45},{2,30},{3,17},{4,8}},
 {{1,40},{2,28},{3,17},{4,10},{5,5}},
 {{1,35},{3,25},{4,18},{5,12},{6,7},{7,3}},
 {{3,35},{5,25},{6,18},{7,12},{8,7},{9,3}},
 {{5,35},{6,25},{8,18},{9,12},{10,7},{11,3}},
 {{6,35},{8,25},{9,18},{10,12},{11,7},{12,3}},
 {{8,35},{10,25},{11,18},{12,12},{13,7},{14,3}},
 {{10,35},{11,25},{12,18},{13,12},{14,7},{15,3}},
 {{11,35},{12,25},{13,18},{14,12},{15,7},{16,3}},
 {{11,10},{12,12},{13,13},{14,15},{15,35},{16,15}},
}
for _,pool in ipairs(pools) do
 local total=0
 for _,entry in ipairs(pool) do
  entry.Id=string.format("ORE_%03d",entry[1]);entry.Weight=entry[2]
  assert(byId[entry.Id].Available);total+=entry.Weight;table.freeze(entry)
 end
 assert(total==100);table.freeze(pool)
end
M.DropPools=table.freeze(pools)
function M.Get(id) return byId[id] end
function M.GetAvailable() return ordered end
function M.Roll(stage,unit)
 local pool=pools[stage];if not pool then return nil end
 local roll=math.clamp(unit or math.random(),0,1)*100
 local sum=0
 for _,entry in ipairs(pool) do sum+=entry.Weight;if roll<sum then return entry.Id end end
 return pool[#pool].Id
end
table.freeze(ordered);table.freeze(byId)
return table.freeze(M)
