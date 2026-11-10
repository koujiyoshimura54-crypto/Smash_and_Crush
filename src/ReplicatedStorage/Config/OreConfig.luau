-- Stable Ore IDs shared by both Worlds. Drop weights live in EnemyDropConfig.
local M = {Version = "WorldOre3"}
local rows = {
 {"Stone",5,1,131452437678251}, {"Coal",7,3,83727497047517},
 {"Iron",9,5,111308943708149}, {"Copper",11,7,106917824814020},
 {"Quartz",15,9,98802386870713}, {"Silver Stone",20,10,92842832362846},
 {"Sand Crystal",30,15,100254430391832}, {"Brown Ore",35,20,90313945125672},
 {"Rock Core",45,25,74885090507086}, {"Gray Crystal",50,30,131216796823283},
 {"Amber",60,35,122870709116506}, {"Topaz",75,40,95006906073775},
 {"Jade",90,45,80400820880542}, {"Aqua Crystal",100,50,111060074263221},
 {"Forest Stone",130,55,133113647660531}, {"Spark Ore",145,65,103644070407489},
 {"Sunstone",175,90,136139361458479}, {"Moon Quartz",200,95,136614965232146},
 {"Blue Crystal",230,100,95334159293900}, {"Green Core",260,110,99321545969483},
 {"Fire Crystal",500,125,123040533451102},
 {"Ice Crystal",800,150,131904521722854},
 {"Thunder Crystal",1200,175,91063489732839},
 {"Wind Crystal",1800,200,86680826462250},
 {"Earth Crystal",2700,225,73601508560022},
 {"Ruby Core",4000,250,116198836377017},
 {"Sapphire Core",6000,280,81308625825873},
 {"Emerald Core",9000,315,134950477291874},
 {"Amethyst",12000,345,115312330145120},
 {"Frostbite",16000,375,82851451613885},
 {"Blood Ore",24000,440,127269924651631},
 {"Crimson",30000,500,132695351248923},
}
local names={"Common","Uncommon","Rare","Super Rare"}
local colors={Color3.fromRGB(145,151,160),Color3.fromRGB(72,193,86),Color3.fromRGB(54,144,245),Color3.fromRGB(180,69,247)}
-- Presentation-only tuning; rarity names/colors above are shared by every Ore view.
M.RarityDisplay=table.freeze({
 Card=table.freeze({TextSize=20,Position=UDim2.fromScale(.025,.81),Size=UDim2.fromScale(.47,.16)}),
 Detail=table.freeze({TextSize=22,Top=122,Height=18}),
 Drop=table.freeze({TextSize=14,Position=UDim2.fromOffset(97,76),Size=UDim2.fromOffset(83,24)}),
})
local byId,ordered={},{}
for index,row in ipairs(rows) do
 local rank=index<=10 and 1 or (index<=20 and 2 or (index<=30 and 3 or 4))
 local ore=table.freeze({Id=string.format("ORE_%03d",index),Index=index,Name=row[1],Points=row[2],SellWin=row[3],
  Image="rbxassetid://"..row[4],RarityId=string.format("RARITY_%02d",rank),Rarity=names[rank],Color=colors[rank],Available=true,WorldId=index<=16 and 1 or 2,WorldIndex=(index-1)%16+1})
 byId[ore.Id]=ore
 if ore.Available then table.insert(ordered,ore) end
end
local Drops=require(script.Parent.EnemyDropConfig)
local pools={}
for stage,row in ipairs(Drops.Worlds[1]) do pools[stage]=row.Ores end
M.DropPools=table.freeze(pools) -- Compatibility view; edit EnemyDropConfig instead.
function M.Get(id) return byId[id] end
function M.GetAvailable() return ordered end
function M.Roll(stage,unit,worldId)
 local row=Drops.Get(worldId or 1,stage);if not row then return nil end
 local pool=row.Ores
 local roll=math.clamp(unit or math.random(),0,1)*100
 local sum=0
 for _,entry in ipairs(pool) do sum+=entry.Weight;if roll<sum then return entry.Id end end
 return pool[#pool].Id
end
table.freeze(ordered);table.freeze(byId)
return table.freeze(M)
