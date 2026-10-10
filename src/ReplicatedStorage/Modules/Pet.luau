local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local Limited = require(ReplicatedStorage.Config.LimitedEggConfig)

type Colors = {Color3}

local NONE = ""
local NO_PET = 1

local PERCENT = 100

local MODELS_PATH = { "Assets", "Pets" }

local Pet = {}

Pet.InventoryField = "inventory"
Pet.PetsField = "pets"
Pet.None = NONE

Pet.MaxEquipped = 1
Pet.Slots = { "current" }

Pet.Attributes = { "Pet" }

function Pet.container(playerData: any): any
	if not playerData then return nil end

	local inventory = playerData[Pet.InventoryField]
	if not inventory then return nil end

	return inventory[Pet.PetsField]
end

function Pet.model(name: string): Model?
	if Limited.ByName[name] then
		local assets=ReplicatedStorage:FindFirstChild("Assets")
		local limited=assets and assets:FindFirstChild(Limited.ModelsFolder)
		local model=limited and limited:FindFirstChild(name)
		return if model and model:IsA("Model") then model else nil
	end
	local folder: Instance? = ReplicatedStorage
	for _, step in ipairs(MODELS_PATH) do
		if not folder then return nil end
		folder = (folder :: Instance):FindFirstChild(step)
	end

	if not folder then return nil end

	local direct = folder:FindFirstChild(name)
	if direct and direct:IsA("Model") then return direct end

	for _, egg in ipairs(folder:GetChildren()) do
		local model = egg:FindFirstChild(name)
		if model and model:IsA("Model") then return model end
	end

	return nil
end

-- Prepare display/follower clones only. Never edits the purchased templates.
function Pet.isLimited(name: string): boolean
 return Limited.ByName[name]~=nil
end

local function visibleBounds(model: Model): (Vector3,Vector3)
 local low=Vector3.new(math.huge,math.huge,math.huge)
 local high=-low
 for _,part in model:GetDescendants() do
  if part:IsA("BasePart") and part.Transparency<1 then
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local point=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
    low=low:Min(point);high=high:Max(point)
   end end end
  end
 end
 assert(low.X<math.huge,"Limited Pet has no visible geometry")
 return low,high
end

function Pet.prepareLimited(model: Model,name: string,height: number?,grounded: boolean?): Vector3?
 local entry=Limited.ByName[name]
 if not entry then return nil end
 assert(model.PrimaryPart,"Limited Pet PrimaryPart missing")
 -- Pivot the entire rig; assigning only primary.CFrame breaks multipart layouts.
 model:PivotTo(CFrame.Angles(0,math.rad(entry.Yaw),0))
 local low,high=visibleBounds(model)
 if height then
  assert(height>0 and high.Y>low.Y,"Invalid limited Pet height")
  model:ScaleTo(model:GetScale()*height/(high.Y-low.Y))
  low,high=visibleBounds(model)
 end
 local center=(low+high)/2
 local anchor=if grounded then Vector3.new(center.X,low.Y,center.Z) else center
 local primary=model.PrimaryPart :: BasePart
 primary.PivotOffset=primary.CFrame:ToObjectSpace(CFrame.new(anchor))
 model:PivotTo(CFrame.identity)
 return high-low
end

local function snapshot(playerData: any): {[string]: any}?
	local container = Pet.container(playerData)
	if not container then return nil end

	local raw = container()

	return if type(raw) == "table" then raw else nil
end

local function isOwned(pets: {[string]: any}, name: string): boolean
	if not Config.Pets[name] then return false end

	return pets[name] == true
end

function Pet.owned(playerData: any, name: string): boolean
	local pets = snapshot(playerData)
	if not pets then return false end

	return isOwned(pets, name)
end

local function isEmpty(pets: {[string]: any}, key: string): boolean
	local current = pets[key]
	if type(current) ~= "string" then return true end
	if current == NONE then return true end

	return not isOwned(pets, current)
end

function Pet.isSlot(key: string): boolean
	return table.find(Pet.Slots, key) ~= nil
end

function Pet.equipped(playerData: any): {string}
	local pets = snapshot(playerData)
	if not pets then return {} end

	local Out: {string} = {}

	for _, key in ipairs(Pet.Slots) do
		if isEmpty(pets, key) then continue end

		local current = pets[key]
		if table.find(Out, current) then continue end

		table.insert(Out, current)
	end

	return Out
end

function Pet.freeSlot(playerData: any): string?
	local pets = snapshot(playerData)
	if not pets then return nil end

	for _, key in ipairs(Pet.Slots) do
		if isEmpty(pets, key) then return key end
	end

	return nil
end

function Pet.multiplier(name: string): number
	local entry = Config.Pets[name]
	if not entry then return NO_PET end

	return if type(entry.multiplier) == "number" then entry.multiplier else NO_PET
end

function Pet.percent(name: string): number?
	local entry = Config.Pets[name]
	if not entry then return nil end
	if type(entry.multiplier) == "number" then return nil end

	return if type(entry.percent) == "number" then entry.percent else nil
end

function Pet.best(playerData: any): number
	local pets = snapshot(playerData)
	if not pets then return NO_PET end

	local best = NO_PET

	for name, entry in pairs(Config.Pets) do
		if type(entry.multiplier) ~= "number" then continue end
		if entry.multiplier <= best then continue end
		if not isOwned(pets, name) then continue end

		best = entry.multiplier
	end

	return best
end

function Pet.worth(playerData: any, name: string): number
	local percent = Pet.percent(name)
	if not percent then return Pet.multiplier(name) end

	return Pet.best(playerData) * (1 + percent / PERCENT)
end

function Pet.rarity(name: string): string?
	local entry = Config.Pets[name]

	return if entry then entry.rarity else nil
end

function Pet.rarityEntry(name: string): {[string]: any}?
	local rarity = Pet.rarity(name)
	if not rarity then return nil end

	local entry = Config.Rarities[rarity]

	return if type(entry) == "table" then entry else nil
end

function Pet.rotation(name: string): number
	local entry = Pet.rarityEntry(name)
	local rotation = if entry then entry.rotation else nil

	return if type(rotation) == "number" then rotation else Config.Inventory.gradientRotation
end

function Pet.trail(name: string): string?
	local entry = Pet.rarityEntry(name)
	local trail = if entry then entry.trail else nil

	return if type(trail) == "string" and trail ~= "" then trail else nil
end

function Pet.colors(name: string): Colors?
	local entry = Pet.rarityEntry(name)
	if not entry then return nil end

	local Run = entry.Colors
	if type(Run) ~= "table" then return nil end

	return if #Run > 0 then Run else nil
end

function Pet.sequence(Run: Colors): ColorSequence
	if #Run == 0 then return ColorSequence.new(Color3.new(1, 1, 1)) end
	if #Run == 1 then return ColorSequence.new(Run[1]) end

	local Keypoints: {ColorSequenceKeypoint} = {}
	local last = #Run - 1

	for index, color in ipairs(Run) do
		table.insert(Keypoints, ColorSequenceKeypoint.new((index - 1) / last, color))
	end

	return ColorSequence.new(Keypoints)
end


function Pet.payout(playerData: any): number
	return 1 -- Pet abilities are intentionally not connected.
end

function Pet.ordered(playerData: any): {string}
	local pets = snapshot(playerData)
	if not pets then return {} end

	local Names: {string} = {}

	for name in pairs(Config.Pets) do
		if not isOwned(pets, name) then continue end

		table.insert(Names, name)
	end

	table.sort(Names, function(a: string, b: string): boolean
		local left, right = Pet.worth(playerData, a), Pet.worth(playerData, b)
		if left ~= right then return left > right end

		return a < b
	end)

	return Names
end


-- Legacy Smash persistence. Each copy has an immutable ID; names only select visuals.
function Pet.NormalizeState(raw)
 local out={Version=1,Revision=0,Owned={},Equipped={""},LastRequestId="",LastResults={}}
 if raw==nil then return out end
 if type(raw)~="table" or raw.Version~=1 then return nil,"InvalidPetsVersion" end
 if type(raw.Revision)~="number" or raw.Revision<0 or raw.Revision%1~=0 or raw.Revision>9007199254740991 then return nil,"InvalidPetsRevision" end
 if type(raw.Owned)~="table" or type(raw.Equipped)~="table" then return nil,"InvalidPets" end
 out.Revision=raw.Revision
 for id,name in pairs(raw.Owned) do
  if type(id)~="string" or #id==0 or #id>128 or type(name)~="string" or #name==0 or #name>128 then return nil,"InvalidPetCopy" end
  out.Owned[id]=name
 end
 for slot,id in pairs(raw.Equipped) do
  if (slot~=1 and slot~=2) or type(id)~="string" then return nil,"InvalidPetEquip" end
 end
 -- Read legacy two-slot data in order; only equipment changes, never ownership.
 for slot=1,2 do
  local id=raw.Equipped[slot]
  if id and id~="" and out.Owned[id] then
   out.Equipped[1]=id
   break
  end
 end
 if type(raw.LastRequestId)~="string" or #raw.LastRequestId>128 or type(raw.LastResults)~="table" or #raw.LastResults>8 then return nil,"InvalidPetReceipt" end
 out.LastRequestId=raw.LastRequestId
 for index in pairs(raw.LastResults) do
  if type(index)~="number" or index%1~=0 or index<1 or index>#raw.LastResults then return nil,"InvalidPetReceipt" end
 end
 for _,result in ipairs(raw.LastResults) do
  if type(result)~="table" or type(result.id)~="string" or type(result.pet)~="string" or out.Owned[result.id]~=result.pet
   or type(result.percent)~="number" or result.percent~=result.percent or result.percent<=0 or result.percent>100 then return nil,"InvalidPetResult" end
  table.insert(out.LastResults,{id=result.id,pet=result.pet,percent=result.percent,duplicate=false,bonus=0})
 end
 return out
end

function Pet.ApplyOperation(raw,op)
 local state,reason=Pet.NormalizeState(raw)
 if not state then return nil,reason end
 if state.LastRequestId==op.Id then return state,"AlreadyApplied" end
 if state.Revision~=op.Revision then return nil,"PetStateChanged" end
 if state.Revision>=9007199254740991 then return nil,"PetRevisionLimit" end
 local results={}
 if op.Action=="Hatch" then
  for _,result in ipairs(op.Results) do
   if state.Owned[result.id] then return nil,"PetIdConflict" end
   state.Owned[result.id]=result.pet
   table.insert(results,table.clone(result))
  end
 elseif op.Action=="Equip" then
  if not state.Owned[op.PetId] then return nil,"PetNotOwned" end
  state.Equipped[1]=if state.Equipped[1]==op.PetId then "" else op.PetId
 else return nil,"InvalidPetAction" end
 state.Revision+=1
 state.LastRequestId=op.Id
 state.LastResults=results
 return state
end

function Pet.Publish(player,state)
 for slot,attribute in ipairs(Pet.Attributes) do
  player:SetAttribute(attribute,state.Owned[state.Equipped[slot]] or Pet.None)
 end
 player:SetAttribute("Pet2",Pet.None) -- Clear the retired follower mirror on load/reset/update.
 player:SetAttribute("PetInventoryRevision",state.Revision)
end

return Pet
