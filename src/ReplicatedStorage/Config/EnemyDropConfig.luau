-- Conditional Ore weights (sum 100), independently editable per World / Stage.
-- ItemChance is applied once; Ores are rolled only after the Ore category wins.
local M={Worlds={
 [1]={
  {ItemChance=0.20,Ores={{Id="ORE_001",Weight=45},{Id="ORE_002",Weight=30},{Id="ORE_003",Weight=17},{Id="ORE_004",Weight=8}}},
  {ItemChance=0.20,Ores={{Id="ORE_001",Weight=40},{Id="ORE_002",Weight=28},{Id="ORE_003",Weight=17},{Id="ORE_004",Weight=10},{Id="ORE_005",Weight=5}}},
  {ItemChance=0.20,Ores={{Id="ORE_001",Weight=35},{Id="ORE_003",Weight=25},{Id="ORE_004",Weight=18},{Id="ORE_005",Weight=12},{Id="ORE_006",Weight=7},{Id="ORE_007",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_003",Weight=35},{Id="ORE_005",Weight=25},{Id="ORE_006",Weight=18},{Id="ORE_007",Weight=12},{Id="ORE_008",Weight=7},{Id="ORE_009",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_005",Weight=35},{Id="ORE_006",Weight=25},{Id="ORE_008",Weight=18},{Id="ORE_009",Weight=12},{Id="ORE_010",Weight=7},{Id="ORE_011",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_006",Weight=35},{Id="ORE_008",Weight=25},{Id="ORE_009",Weight=18},{Id="ORE_010",Weight=12},{Id="ORE_011",Weight=7},{Id="ORE_012",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_008",Weight=35},{Id="ORE_010",Weight=25},{Id="ORE_011",Weight=18},{Id="ORE_012",Weight=12},{Id="ORE_013",Weight=7},{Id="ORE_014",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_010",Weight=35},{Id="ORE_011",Weight=25},{Id="ORE_012",Weight=18},{Id="ORE_013",Weight=12},{Id="ORE_014",Weight=7},{Id="ORE_015",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_011",Weight=35},{Id="ORE_012",Weight=25},{Id="ORE_013",Weight=18},{Id="ORE_014",Weight=12},{Id="ORE_015",Weight=7},{Id="ORE_016",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_011",Weight=10},{Id="ORE_012",Weight=12},{Id="ORE_013",Weight=13},{Id="ORE_014",Weight=15},{Id="ORE_015",Weight=35},{Id="ORE_016",Weight=15}}},
 },
 [2]={
  {ItemChance=0.20,Ores={{Id="ORE_017",Weight=45},{Id="ORE_018",Weight=30},{Id="ORE_019",Weight=17},{Id="ORE_020",Weight=8}}},
  {ItemChance=0.20,Ores={{Id="ORE_017",Weight=40},{Id="ORE_018",Weight=28},{Id="ORE_019",Weight=17},{Id="ORE_020",Weight=10},{Id="ORE_021",Weight=5}}},
  {ItemChance=0.20,Ores={{Id="ORE_017",Weight=35},{Id="ORE_019",Weight=25},{Id="ORE_020",Weight=18},{Id="ORE_021",Weight=12},{Id="ORE_022",Weight=7},{Id="ORE_023",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_019",Weight=35},{Id="ORE_021",Weight=25},{Id="ORE_022",Weight=18},{Id="ORE_023",Weight=12},{Id="ORE_024",Weight=7},{Id="ORE_025",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_021",Weight=35},{Id="ORE_022",Weight=25},{Id="ORE_024",Weight=18},{Id="ORE_025",Weight=12},{Id="ORE_026",Weight=7},{Id="ORE_027",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_022",Weight=35},{Id="ORE_024",Weight=25},{Id="ORE_025",Weight=18},{Id="ORE_026",Weight=12},{Id="ORE_027",Weight=7},{Id="ORE_028",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_024",Weight=35},{Id="ORE_026",Weight=25},{Id="ORE_027",Weight=18},{Id="ORE_028",Weight=12},{Id="ORE_029",Weight=7},{Id="ORE_030",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_026",Weight=35},{Id="ORE_027",Weight=25},{Id="ORE_028",Weight=18},{Id="ORE_029",Weight=12},{Id="ORE_030",Weight=7},{Id="ORE_031",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_027",Weight=35},{Id="ORE_028",Weight=25},{Id="ORE_029",Weight=18},{Id="ORE_030",Weight=12},{Id="ORE_031",Weight=7},{Id="ORE_032",Weight=3}}},
  {ItemChance=0.20,Ores={{Id="ORE_027",Weight=10},{Id="ORE_028",Weight=12},{Id="ORE_029",Weight=13},{Id="ORE_030",Weight=15},{Id="ORE_031",Weight=35},{Id="ORE_032",Weight=15}}},
 },
}}
for _,stages in pairs(M.Worlds) do
 assert(#stages==10)
 for _,row in ipairs(stages) do
  assert(row.ItemChance>=0 and row.ItemChance<=1)
  local sum=0
  for _,entry in ipairs(row.Ores) do assert(entry.Weight>0);sum+=entry.Weight;table.freeze(entry) end
  assert(sum==100);table.freeze(row.Ores);table.freeze(row)
 end
 table.freeze(stages)
end
table.freeze(M.Worlds)
function M.Get(worldId,stage) local rows=M.Worlds[worldId];return rows and rows[stage] end
return table.freeze(M)
