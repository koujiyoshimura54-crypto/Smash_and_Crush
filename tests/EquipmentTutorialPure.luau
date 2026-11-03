-- Edit-only pure checks; the equal-strength fixture does not mutate the live master.
local RS=game.ReplicatedStorage
local Best=require(RS.Modules.DumbbellEquipment)
local State=require(RS.Modules.EquipmentTutorialState)
local checks={}
local function check(name,ok)assert(ok,name);table.insert(checks,name)end
check("strongest real effect",Best.Best({NORMAL_01=5,NORMAL_06=1},"NORMAL_01")=="NORMAL_06")
check("current strongest retained",Best.Best({NORMAL_01=5,NORMAL_06=1},"NORMAL_06")=="NORMAL_06")
check("no owned item",Best.Best({},"")==nil)
check("zero count excluded",Best.Best({NORMAL_06=0,NORMAL_01=1},"NORMAL_06")=="NORMAL_01")
check("World2 actual master",Best.Best({NORMAL_12=2,W2_NORMAL_01=1},"NORMAL_12")=="W2_NORMAL_01")
local clone=RS.Modules.DumbbellEquipment:Clone();clone.Name="__EquipmentTieFixture"
clone.Source=clone.Source:gsub("local Master=[^\n]+","local Master={Get=function(id)return {Category='Dumbbell',StrengthBonus=20}end}",1)
clone.Parent=RS.Modules
local ok,why=pcall(function()
 local tied=require(clone)
 check("equal distinct types retain current B",tied.Best({A=3,B=1},"B")=="B")
 check("equal distinct types retain current A",tied.Best({A=3,B=1},"A")=="A")
 check("no current stable tie order",tied.Best({B=1,A=1},"")=="A")
end)
clone:Destroy();assert(ok,why)
check("missing legacy does not enroll",State.Normalize(nil,false).Eligible==false)
check("fresh/reset enrolls",State.Normalize(nil,true).Eligible==true)
check("malformed state rejected",State.Normalize({Version=9},true)==nil)
local completed={Version=1,Eligible=true,ItemCompleted=true,DumbbellCompleted=true}
local merged=State.Merge(completed,State.Normalize(nil,true))
check("ordinary save cannot regress completion",merged.ItemCompleted and merged.DumbbellCompleted)
return checks
