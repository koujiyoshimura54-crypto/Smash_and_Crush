type Slot = {
	pet: string,
	percent: number,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local Limited = require(ReplicatedStorage.Config.LimitedEggConfig)

local Egg = {}
local World2=require(ReplicatedStorage.Config.World2GameplayConfig)

Egg.FolderName = "Eggs"

-- Owner-approved normal pools: one definition for server rolls, UI and merge metadata.
Egg.NormalSlots = {
	{Percent=25, Rank="E"}, {Percent=25, Rank="E"}, {Percent=25, Rank="E"},
	{Percent=15, Rank="D"}, {Percent=6.5, Rank="C"}, {Percent=3, Rank="B"}, {Percent=.5, Rank="A"},
}
Egg.RankPoints = {E=10, D=20, C=30, B=40, A=50}
Egg.NormalOrder = {"Basic", "Rare", "Legendary", "Mythic"}
Egg.NormalPools = {
	Basic={Coefficient=1, Approved=true, Icon="", ModelPath="Workspace.Eggs.Basic",
		StrengthPercents={2,2,2,4,6,8,12}, -- Same species slots; independent of merge points.
		Species={"Dog", "Grey Cat", "Pink Bunny", "Sheep", "Bear", "Camel", "Slime"}},
	Rare={Coefficient=5, Approved=true, Icon="", ModelPath="Workspace.Eggs.Rare",
		StrengthPercents={8,8,8,12,18,25,35},
		Species={"Cow", "Giraffe", "Lion", "Lizard", "Spider", "Bat", "Shroom"}},
	Legendary={Coefficient=25, Approved=true, Icon="", ModelPath="Workspace.Eggs.Legendary",
		StrengthPercents={20,20,20,30,45,60,80},
		Species={"Elephant", "Mammoth", "Penguin", "Crocodile", "Octopus", "Shark", "Ninja"}},
	Mythic={Coefficient=125, Approved=true, Icon="", ModelPath="Workspace.Eggs.Mythic",
		StrengthPercents={45,45,45,60,80,100,130},
		Species={"Turtle", "Alien", "Anglerfish", "Dino", "Scorpion", "Evil Dragon", "Chimpanzini Bananini"}},
}
-- World2 pools are not Pet Merge targets; the existing four World1 preview pools stay intact.
for index,sources in ipairs(World2.PetSources) do
 local species,percents={},{}
 for slot,source in ipairs(sources) do
  species[slot]="W2 "..source;percents[slot]=(World2.PetMultipliers[index][slot]-1)*100
 end
 Egg.NormalPools[World2.EggIds[index]]={Approved=true,Species=species,StrengthPercents=percents}
end
Egg.MergeThresholds = {
	{Points=20, Odds={60,40,0,0}}, {Points=30, Odds={40,60,0,0}},
	{Points=40, Odds={20,80,0,0}}, {Points=50, Odds={0,100,0,0}},
	{Points=100, Odds={0,60,40,0}}, {Points=150, Odds={0,40,60,0}},
	{Points=200, Odds={0,20,80,0}}, {Points=250, Odds={0,0,100,0}},
	{Points=500, Odds={0,0,60,40}}, {Points=750, Odds={0,0,40,60}},
	{Points=1000, Odds={0,0,20,80}}, {Points=1250, Odds={0,0,0,100}},
}

function Egg.validateNormalPool(name: string): (boolean, string?)
	local pool=Egg.NormalPools[name]
	if not pool or not pool.Approved then return false,"SeventhPetUnapproved" end
	if #pool.Species~=7 then return false,"SevenDistinctPetsRequired" end
	local seen,total={},0
	for index,pet in ipairs(pool.Species) do
		if type(pet)~="string" or pet=="" or seen[pet] or Limited.ByName[pet] then return false,"InvalidNormalPet" end
		seen[pet]=true;total+=Egg.NormalSlots[index].Percent
	end
	return math.abs(total-100)<1e-9, if math.abs(total-100)<1e-9 then nil else "InvalidProbabilityTotal"
end

function Egg.mergePet(name: string): any?
	if Limited.ByName[name] then return nil end
	for _,eggName in ipairs(Egg.NormalOrder) do
		local pool=Egg.NormalPools[eggName]
		for index,pet in ipairs(pool.Species) do
			if pet==name then
				local slot=Egg.NormalSlots[index]
				local live=Egg.pets(eggName)
				return {Name=name, Egg=eggName, Slot=index, Rank=slot.Rank,
					Points=Egg.RankPoints[slot.Rank]*pool.Coefficient,
					Percent=live and live[name], TargetPercent=slot.Percent,
					PoolApproved=Egg.validateNormalPool(eggName)}
			end
		end
	end
	return nil
end

-- Pure display projection only; never rolls, consumes, grants or saves.
function Egg.mergePreview(points: number, count: number): any
	local result={Eligible=false, Reason="MinimumTwoPets", Points=points, EffectivePoints=0, Surplus=0, Outcomes={}}
	if type(count)~="number" or count<2 then return result end
	if type(points)~="number" or points~=points or points==math.huge or points<20 then
		result.Reason="InvalidPoints";return result
	end
	local p=math.min(points,1250);local odds
	result.EffectivePoints=p;result.Surplus=math.max(points-1250,0)
	for index=2,#Egg.MergeThresholds do
		local a,b=Egg.MergeThresholds[index-1],Egg.MergeThresholds[index]
		if p<=b.Points then
			local t=(p-a.Points)/(b.Points-a.Points);odds={}
			for i=1,4 do odds[i]=a.Odds[i]+(b.Odds[i]-a.Odds[i])*t end
			break
		end
	end
	-- Hundredths, using largest remainders so displayed probabilities sum to exactly 100%.
	local units,remainders,sum={},{},0
	for i=1,4 do
		local exact=math.max(odds[i],0)*100
		units[i]=math.floor(exact+1e-9);sum+=units[i]
		table.insert(remainders,{Index=i,Value=exact-units[i]})
	end
	table.sort(remainders,function(a,b) return a.Value==b.Value and a.Index<b.Index or a.Value>b.Value end)
	for i=1,10000-sum do units[remainders[i].Index]+=1 end
	for i,name in ipairs(Egg.NormalOrder) do
		if units[i]>0 then table.insert(result.Outcomes,{Egg=name, Percent=units[i]/100, RawPercent=odds[i]}) end
	end
	result.Eligible=true;result.Reason=nil;return result
end

function Egg.ordered(slots: {[string]: Slot}): {Slot}
	if type(slots) ~= "table" then return {} end

	local Names: {string} = {}

	for name in pairs(slots) do
		table.insert(Names, name)
	end

	table.sort(Names)

	local List: {Slot} = {}

	for _, name in ipairs(Names) do
		local slot = slots[name]
		if type(slot) ~= "table" then continue end
		if type(slot.pet) ~= "string" then continue end
		if type(slot.percent) ~= "number" then continue end
		if slot.percent <= 0 then continue end

		table.insert(List, slot)
	end

	return List
end

function Egg.ranked(Pets: {[string]: number}): {Slot}
	if type(Pets) ~= "table" then return {} end

	local List: {Slot} = {}

	for pet, percent in pairs(Pets) do
		if type(pet) ~= "string" then continue end
		if type(percent) ~= "number" then continue end
		if percent <= 0 then continue end

		table.insert(List, { pet = pet, percent = percent })
	end

	table.sort(List, function(a: Slot, b: Slot): boolean
		if a.percent ~= b.percent then return a.percent > b.percent end
		local wa,wb=World2.Pets[a.pet],World2.Pets[b.pet]
		if wa and wb and wa.Egg==wb.Egg then return wa.Slot<wb.Slot end
		local x,y=Egg.mergePet(a.pet),Egg.mergePet(b.pet)
		if x and y and x.Egg==y.Egg then return x.Slot<y.Slot end

		return a.pet < b.pet
	end)

	return List
end

function Egg.pick(List: {Slot}): (string?, number)
	local total = 0
	for _, slot in ipairs(List) do
		total += slot.percent
	end

	if total <= 0 then return nil, 0 end

	local point = math.random() * total

	for _, slot in ipairs(List) do
		point -= slot.percent
		if point > 0 then continue end

		return slot.pet, slot.percent
	end

	local last = List[#List]
	if not last then return nil, 0 end

	return last.pet, last.percent
end

function Egg.roll(slots: {[string]: Slot}): (string?, number)
	return Egg.pick(Egg.ordered(slots))
end

function Egg.isEgg(name: string): boolean
	return Config.Eggs.Eggs[name] ~= nil
end

function Egg.pets(name: string): {[string]: number}?
	local entry = Config.Eggs.Eggs[name]
	if not entry then return nil end
	local normal=Egg.NormalPools[name]
	if normal and normal.Approved then
		-- An approved but broken pool must never quietly revert to the old six-species odds.
		if not Egg.validateNormalPool(name) then return nil end
		local pool={}
		for index,pet in ipairs(Egg.NormalPools[name].Species) do pool[pet]=Egg.NormalSlots[index].Percent end
		return pool
	end

	return if type(entry.Pets) == "table" then entry.Pets else nil
end

function Egg.price(name: string): number
	local entry = Config.Eggs.Eggs[name]
	if not entry then return 0 end

	return if type(entry.wins) == "number" then entry.wins else 0
end

function Egg.count(button: string): number?
	local rolls = Config.Eggs.Buttons[button]

	return if type(rolls) == "number" then rolls else nil
end

function Egg.world(name)
 local row=Config.Eggs.Eggs[name]
 return row and (row.WorldId or 1)
end
function Egg.purchasable(name)
 local row=Config.Eggs.Eggs[name]
 return row~=nil and row.PurchaseEnabled~=false and type(row.wins)=="number" and row.wins>0
end
function Egg.displayName(name)
 local row=Config.Eggs.Eggs[name]
 return row and row.Name or name
end
local function facilities()
 local map=workspace:FindFirstChild("World2Map")
 local area=map and map:FindFirstChild("TrainingArea")
 return area and area:FindFirstChild("FacilityDisplays")
end
function Egg.part(name)
 if Egg.world(name)~=2 then local folder=workspace:FindFirstChild(Egg.FolderName);return folder and folder:FindFirstChild(name) end
 local root=facilities()
 if not root then return nil end
 if name=="W2_Limited" then local limited=root:FindFirstChild("LimitedEggDisplay");return limited and limited:FindFirstChild("PetMesh") end
 local displays=root:FindFirstChild("EggDisplays")
 local visuals=displays and displays:FindFirstChild("Visuals")
 return visuals and visuals:FindFirstChild(name:sub(4))
end
function Egg.identity(part)
 for _,id in ipairs(World2.EggIds) do if Egg.part(id)==part then return id end end
 return part.Name
end
function Egg.parts()
 local parts={}
 for name in pairs(Config.Eggs.Eggs) do
  local part=Egg.part(name)
  if part and part:IsA("BasePart") then table.insert(parts,part) end
 end
 return parts
end
return Egg
