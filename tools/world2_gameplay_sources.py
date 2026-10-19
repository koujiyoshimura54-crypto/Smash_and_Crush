"""Scoped World2 connections based on the actual CurrentCloud Sources, not old src."""
from pathlib import Path
from rbxl_rows import Editor, string

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')


class Changes:
    def __init__(self, raw):
        self.editor = Editor(raw)
        self.paths = {self.editor.path(r): r for r in self.editor.parents}
        self.before, self.sources = {}, {}

    def get(self, path):
        if path not in self.sources:
            self.before[path] = string(self.editor.get(self.paths[path], 'Source'), 0)[0].decode('utf-8')
            self.sources[path] = self.before[path].replace('\r\n','\n').replace('\r','\n').rstrip()+'\n'
        return self.sources[path]

    def replace(self, path, old, new, count=1):
        source = self.get(path)
        assert source.count(old) == count, (path, old[:100], source.count(old), count)
        self.sources[path] = source.replace(old, new)

    def append(self, path, code, returned):
        source=self.get(path)
        assert source.rstrip().endswith(returned), (path, returned)
        index=source.rindex(returned)
        self.sources[path]=source[:index]+code+'\n'+source[index:]

    def write_mirrors(self):
        for path, source in self.sources.items():
            if source == self.before[path]:
                continue
            cls = self.editor.doc.classes[self.editor.class_of[self.paths[path]]][0]
            suffix = {'Script': '.server.luau', 'LocalScript': '.client.luau', 'ModuleScript': '.luau'}[cls]
            target = ROOT / 'src' / (path.replace('.', '/') + suffix)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.encode('utf-8'))
        return {path: source for path, source in self.sources.items() if source != self.before[path]}


def configure(c):
    path = 'ReplicatedStorage.Config.World2Config'
    c.replace(path, '-- Data only: does not activate travel, combat, progression, rewards or inventory.',
              '-- World2 workbook authority; existing battle rules and placements are retained.')
    c.replace(path, 'local C={', 'local Workbook=require(script.Parent.World2GameplayConfig)\nlocal C={')
    c.replace(path, 'BalanceVersion="20260915"', 'BalanceVersion=Workbook.Version')
    import re
    old = c.get(path)
    c.sources[path] = re.sub(r',RequiredStrength=\d+', '', old)
    c.replace(path, 'for _,entry in ipairs(stages) do\n local walls={}\n for index,multiplier in ipairs(C.WallHitMultipliers) do\n  walls[index]=entry.RequiredStrength*multiplier\n end\n entry.Walls=table.freeze(walls)\n entry.BossMaxHP=entry.RequiredStrength*C.BossHitMultiplier',
              'for stage,entry in ipairs(stages) do\n local approved=Workbook.Stages[stage]\n entry.RequiredStrength=approved.BossMaxHP/C.BossHitMultiplier -- Existing combat benchmark, never an entry gate.\n entry.Walls=approved.Walls\n entry.BossMaxHP=approved.BossMaxHP\n entry.WinReward=approved.WinReward')
    path = 'ReplicatedStorage.Config.TrophyRewardConfig'
    c.replace(path, 'function Config.GetBaseReward(stage) return Config.Rewards[stage] end',
              'local World2=require(script.Parent.World2GameplayConfig)\nfunction Config.GetBaseReward(stage,worldId)\n if worldId==2 then local row=World2.Stages[stage];return row and row.WinReward end\n return Config.Rewards[stage]\nend')
    path = 'ReplicatedStorage.Config.RebirthConfig'
    c.replace(path, 'return (tonumber(rebirthCount) or 0)>=Config.World1MaxRebirth',
              'return Config.GetRequiredLevel(rebirthCount)==nil -- Rebirth is shared; retain legacy R11+ definitions.')
    c.replace(path, 'function Config.GetRequiredLevel(rebirthCount)',
              'local World2=require(script.Parent.World2GameplayConfig)\nfor count,row in pairs(World2.Rebirth) do Config.RebirthRequiredLevels[count]=row.Level end\nfunction Config.GetRequiredLevel(rebirthCount)')
    path = 'ReplicatedStorage.Config.RebirthMultiplierConfig'
    c.replace(path, ' local exact=Config.Multipliers[count]', ' return 1+count*.5 -- Shared owner rule, including existing counts above ten.\nend\nlocal function legacyFallback(count)\n local exact=Config.Multipliers[count]')
    c.replace(path, 'local function validMultiplier(value)', 'for count in pairs(Config.Multipliers) do Config.Multipliers[count]=1+count*.5 end\n\nlocal function validMultiplier(value)')
    # Keep the public getter small; the obsolete fallback is not an alternate balance table.
    source = c.get(path)
    a = source.index('local function validMultiplier(')
    c.sources[path] = source[:a] + '''function Config.GetMultiplier(rebirthCount)
 local count=tonumber(rebirthCount)
 if not count or count~=count or count==math.huge or count==-math.huge then return 1 end
 return 1+math.max(0,math.floor(count))*.5
end
return Config
'''
    path = 'ServerScriptService.Systems.Controllers.RebirthService'
    c.replace(path, 'if not PlayerData.IsLoaded(player) or PlayerData.IsSaving(player) then',
              'local session=PlayerData.Get(player)\n if not PlayerData.IsLoaded(player) or PlayerData.IsSaving(player) or (session and (session.PendingItemMutation or session.OwnershipLost)) then')
    path = 'StarterGui.StrengthGui.RebirthMenuClient'
    c.replace(path, '"WORLD 1 MAX"', '"MAX"')
    path = 'ReplicatedStorage.Config.DumbbellItemMaster'
    c.replace(path, 'for _, item in ipairs(definitions) do', '''local World2=require(script.Parent.World2GameplayConfig)
for index,row in ipairs(World2.Dumbbells) do
 table.insert(definitions,{ItemId=string.format("W2_NORMAL_%02d",index),Name="World 2 Dumbbell "..index,
  WorldId=2,Grade=index,PriceWin=row.PriceWin,StrengthBonus=row.StrengthBonus,ImageAssetId=World2.DumbbellImages[index]})
end
for _, item in ipairs(definitions) do''')
    c.replace(path, 'item.SeriesId = "NORMAL"', 'item.SeriesId = item.WorldId==2 and "WORLD2" or "NORMAL"')
    c.replace(path, ' if a.Grade~=b.Grade then', ' if (a.WorldId or 1)~=(b.WorldId or 1) then return (a.WorldId or 1)<(b.WorldId or 1) end\n if a.Grade~=b.Grade then')
    c.replace(path, 'function M.GetSorted() return sorted end', '''function M.GetSorted(worldId)
 if worldId==nil then return sorted end
 local result={}
 for _,item in ipairs(sorted) do if (item.WorldId or 1)==worldId then table.insert(result,item) end end
 return result
end''')
    path = 'ReplicatedStorage.Config.ItemMaster'
    c.replace(path, 'table.freeze(items)', '''local World2=require(script.Parent.World2GameplayConfig)
local originals=table.clone(items)
for id,item in pairs(originals) do
 local row=assert(World2.Items[item.Rarity])
 local worldItem=table.clone(item)
 worldItem.ItemId="W2_"..id;worldItem.WorldId=2
 worldItem.WinPrice=row.PriceWin;worldItem.ShopPurchasable=row.PriceWin~=nil
 worldItem.RobuxPurchasable=false;worldItem.RobuxPrice=nil
 items[worldItem.ItemId]=table.freeze(worldItem)
end
table.freeze(items)''')
    c.append(path, '''function ItemMaster.Id(kind,rarity,element,worldId)
 local prefix=worldId==2 and "W2_" or ""
 return prefix..ItemMaster.TypePrefixes[kind].."_"..rarity:upper().."_"..element:upper()
end
function ItemMaster.DisplayName(item)
 return "World "..tostring(item.WorldId or 1).." "..item.Rarity.." "..item.Element.." "..item.ItemType
end''', 'return table.freeze(ItemMaster)')
    path = 'ReplicatedStorage.Config.ItemMultiplierConfig'
    c.replace(path, 'local Config = {}', 'local Config = {}\nlocal World2=require(script.Parent.World2GameplayConfig)')
    for function, field in [('GetProteinBonus','ProteinBonus'),('GetGloveBossDamageBonus','GloveBossDamageBonus'),('GetBeltTreadmillBonus','BeltTreadmillBonus')]:
        c.replace(path, f'function Config.{function}(rarity)\n', f'function Config.{function}(rarity,worldId)\n if worldId==2 then local row=World2.Items[rarity];return row and row.{field} or 0 end\n')
    c.replace(path, 'function Config.GetEffectText(itemType, rarity)', 'function Config.GetEffectText(itemType, rarity, worldId)')
    for function in ['GetProteinBonus','GetGloveBossDamageBonus','GetBeltTreadmillBonus']:
        c.replace(path, f'Config.{function}(rarity))', f'Config.{function}(rarity,worldId))') if function != 'GetGloveBossDamageBonus' else c.replace(path, f'Config.{function}(rarity) *',f'Config.{function}(rarity,worldId) *')
    path = 'ReplicatedStorage.Config.AuraConfig'
    c.replace(path, 'local Shop=require(script.Parent.ShopProductConfig)', '''local World2=require(script.Parent.World2GameplayConfig)
local visualOrder={"Pink","Purple","Yellow","Green","Blue","Red"}
for index,row in ipairs(World2.Auras) do
 local aura=table.clone(Config.Auras[visualOrder[index]])
 local id=string.format("W2_AURA_%02d",index)
 aura.Id=id;aura.Key=id;aura.WorldId=2;aura.Name="World 2 "..aura.Name;aura.DisplayName=aura.Name
 aura.StrengthBonus=row.StrengthBonus;aura.Order=#Config.Order+1
 aura.PurchaseType=index==6 and "Unavailable" or "Win"
 aura.PurchaseEnabled=row.PurchaseEnabled;aura.Price=row.PriceWin
 aura.GamePassId=nil;aura.ProductId=nil;aura.DisplayPriceFallback=nil
 Config.Auras[id]=aura;table.insert(Config.Order,id)
end
local Shop=require(script.Parent.ShopProductConfig)''')


def items(c):
    path='ServerScriptService.Services.ItemService'
    c.replace(path, '  return item.Rarity\n', '  return item.Rarity,item.WorldId or 1\n')
    # Best Equip compares actual effects so a W2 Common can beat a W1 Legendary.
    c.replace(path, ' local selected,ranks={},{}', ''' local selected,ranks={},{}
 local function score(item)
  local getter=({Protein=ItemMultiplierConfig.GetProteinBonus,Glove=ItemMultiplierConfig.GetGloveBossDamageBonus,TrainingBelt=ItemMultiplierConfig.GetBeltTreadmillBonus})[item.ItemType]
  return getter and getter(item.Rarity,item.WorldId) or 0
 end''')
    c.replace(path, '  local rank=item and rarityRank[item.Rarity]', '  local rank=item and score(item)')
    c.replace(path, 'rarityRank[item.Rarity]==ranks[kind]', 'score(item)==ranks[kind]')
    path='ReplicatedStorage.Config.ItemMergeConfig'
    c.replace(path, ' local total,count,types,elements,ids=0,0,{},{},{}', ' local total,count,types,elements,ids=0,0,{},{},{}\n local worldId')
    c.replace(path, '  if not integer(n) then', '  local world=item.WorldId or 1\n  if worldId and worldId~=world then return nil,"MixedWorldMaterials" end\n  worldId=world\n  if not integer(n) then')
    c.replace(path, 'local id=Master.TypePrefixes[kind].."_"..rarity.Rarity:upper().."_"..element:upper()', 'local id=Master.Id(kind,rarity.Rarity,element,worldId)')
    c.replace(path, 'return {Count=count,Points=total,', 'return {WorldId=worldId,Count=count,Points=total,')
    c.replace(path, 'return Master.TypePrefixes[kind].."_"..rarity:upper().."_"..element:upper()', 'return Master.Id(kind,rarity,element,preview.WorldId)')
    path='ServerScriptService.Services.EnemyDropRoller'
    c.replace(path, 'lookup[item.ItemType.."/"..item.Element.."/"..item.Rarity]=id', 'lookup[tostring(item.WorldId or 1).."/"..item.ItemType.."/"..item.Element.."/"..item.Rarity]=id')
    c.replace(path, 'assert(lookup[kind.."/"..element.."/"..rarity],', 'assert(lookup["1/"..kind.."/"..element.."/"..rarity],')
    c.replace(path, 'function M.RollItem(rng,stage,rarityWeights)', 'function M.RollItem(rng,stage,rarityWeights,worldId)')
    c.replace(path, 'return assert(lookup[kind.."/"..element.."/"..rarity])', 'return assert(lookup[tostring(worldId or 1).."/"..kind.."/"..element.."/"..rarity])')
    c.replace(path, 'function M.Roll(rng,stage)', 'function M.Roll(rng,stage,worldId)')
    c.replace(path, 'M.RollItem(rng,stage)', 'M.RollItem(rng,stage,nil,worldId)')
    c.replace('ServerScriptService.Services.EnemyDropGachaService', 'Roller.Roll(rng,stage)', 'Roller.Roll(rng,stage,worldId)')
    path='ServerScriptService.Services.PetServer'
    c.replace(path, 'if player.Parent~=Players or (player:GetAttribute("CurrentWorld") or 1)~=1 then return 1 end', 'if player.Parent~=Players then return 1 end')
    path='ServerScriptService.Services.TrophyRewardService'
    for text in ['r.Stage','record.Stage','major']:
        count=c.get(path).count('RewardConfig.GetBaseReward('+text+')')
        c.replace(path,'RewardConfig.GetBaseReward('+text+')','RewardConfig.GetBaseReward('+text+',worldId)',count)
    c.replace(path, ' -- World2 rewards are explicitly unconfigured; never issue a World1 reward.\n if worldId==2 then return false,"World2RewardUnconfigured" end\n', '')
    c.replace(path, 'player:SetAttribute("Win", updatedWin)', 'if not PlayerData.SetWin(player,updatedWin) then record.Claiming=false;return end')
    c.replace(path, 'if record.Stage == WorldGateConfig.CompletionStage then', 'if worldId==1 and record.Stage == WorldGateConfig.CompletionStage then')
    c.replace(path, 'if record.Stage == 1 then', 'if worldId==1 and record.Stage == 1 then', 2)
    c.replace(path, '\tif not records[player]\n', '\tif (player:GetAttribute("CurrentWorld") or 1)~=worldId or not records[player]\n')
    c.replace(path, 'function M.Spawn(player, major)\n', 'function M.Spawn(player, major)\n if (player:GetAttribute("CurrentWorld") or 1)~=worldId then return false,"WrongWorld" end\n')


def pets(c):
    path='ReplicatedStorage.Modules.Config'
    c.append(path, '''-- Distinct World2 identities reuse visuals only. No initial ownership or paid grant.
local World2=require(game:GetService("ReplicatedStorage").Config.World2GameplayConfig)
for name,pet in pairs(World2.Pets) do
 local visual=Config.Pets[pet.SourcePet] or {rarity="Legendary"}
 local entry=table.clone(visual)
 entry.WorldId=2;entry.multiplier=pet.Multiplier;entry.percent=nil
 Config.Pets[name]=entry
end
for index,id in ipairs(World2.EggIds) do
 local row=World2.Eggs[index]
 Config.Eggs.Eggs[id]={WorldId=2,Name=World2.EggNames[index],wins=row and row.PriceWin,
  PurchaseEnabled=row~=nil and row.PurchaseEnabled==true}
end''', 'return Config')
    path='ReplicatedStorage.Modules.Egg'
    c.replace(path, 'local Egg = {}', 'local Egg = {}\nlocal World2=require(ReplicatedStorage.Config.World2GameplayConfig)')
    c.replace(path, 'Egg.MergeThresholds = {', '''-- World2 pools are not Pet Merge targets; the existing four World1 preview pools stay intact.
for index,sources in ipairs(World2.PetSources) do
 local species,percents={},{}
 for slot,source in ipairs(sources) do
  species[slot]="W2 "..source;percents[slot]=(World2.PetMultipliers[index][slot]-1)*100
 end
 Egg.NormalPools[World2.EggIds[index]]={Approved=true,Species=species,StrengthPercents=percents}
end
Egg.MergeThresholds = {''')
    c.append(path, '''function Egg.world(name)
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
end''', 'return Egg')
    path='ReplicatedStorage.Modules.Pet'
    c.replace(path, 'local Pet = {}', '''local Pet = {}
local World2=require(ReplicatedStorage.Config.World2GameplayConfig)
function Pet.VisualName(name)
 local entry=World2.Pets[name]
 return entry and entry.SourcePet or name
end''')
    c.replace(path, 'function Pet.StrengthPercent(name: string): number?\n', 'function Pet.StrengthPercent(name: string): number?\n local entry=World2.Pets[name]\n if entry then return (entry.Multiplier-1)*100 end\n')
    c.replace(path, 'function Pet.model(name: string): Model?\n', 'function Pet.model(name: string): Model?\n name=Pet.VisualName(name)\n')
    c.replace(path, 'return Limited.ByName[name]~=nil', 'return Limited.ByName[Pet.VisualName(name)]~=nil')
    c.replace(path, ' local entry=Limited.ByName[name]\n', ' name=Pet.VisualName(name)\n local entry=Limited.ByName[name]\n')
    path='ReplicatedStorage.Modules.LimitedPetViewport'
    c.replace(path, 'local M={}', 'local M={}\nlocal Pet=require(RS.Modules.Pet)')
    c.replace(path, 'function M.supports(name) return Config.ByName[name]~=nil end', 'function M.supports(name) return Pet.isLimited(name) end')
    c.replace(path, 'function M.mount(host,name)\n', 'function M.mount(host,name)\n name=Pet.VisualName(name)\n')
    c.replace(path, 'local eggs=workspace:FindFirstChild("Eggs")\n local template=eggs and eggs:FindFirstChild(name)', 'local template=require(RS.Modules.Egg).part(name)')
    path='StarterPlayer.StarterPlayerScripts.Services.PetClient'
    c.replace(path, 'sourceIcons:FindFirstChild(name)', 'sourceIcons:FindFirstChild(Pet.VisualName(name))')
    path='ServerScriptService.Services.EggServer'
    c.replace(path, ' if not Egg.isEgg(name) then return false,"EggUnavailable" end', ' if not Egg.isEgg(name) or not Egg.purchasable(name) then return false,"EggUnavailable" end\n if Egg.world(name)~=(player:GetAttribute("CurrentWorld") or 1) then return false,"WrongWorld" end')
    c.replace(path, ' local folder=workspace:FindFirstChild(Egg.FolderName)\n local part=folder and folder:FindFirstChild(name)', ' local part=Egg.part(name)')
    c.replace(path, ' local folder=workspace:FindFirstChild(Egg.FolderName)\n if not folder then return end\n for _,part in ipairs(folder:GetChildren()) do\n  if not part:IsA("BasePart") or not Egg.isEgg(part.Name) then continue end', ' for _,part in ipairs(Egg.parts()) do\n  local name=Egg.identity(part)\n  if not Egg.isEgg(name) then continue end')
    c.replace(path, 'label.Text=require(RS.Modules.NumberFormat).Price(Egg.price(part.Name))', 'label.Text=Egg.purchasable(name) and require(RS.Modules.NumberFormat).Price(Egg.price(name)) or "Unavailable"')
    path='ServerScriptService.Services.PlayerDataService'
    c.replace(path, 'or type(payload.EggName)~="string" or not egg.isEgg(payload.EggName)', 'or type(payload.EggName)~="string" or not egg.isEgg(payload.EggName) or not egg.purchasable(payload.EggName)\n    or egg.world(payload.EggName)~=(player:GetAttribute("CurrentWorld") or 1)')
    path='StarterPlayer.StarterPlayerScripts.Services.EggClient'
    c.replace(path, 'local Egg = require(ReplicatedStorage.Modules.Egg)', 'local Egg = require(ReplicatedStorage.Modules.Egg)\nlocal Pet = require(ReplicatedStorage.Modules.Pet)')
    c.replace(path, 'icons:FindFirstChild(petName)', 'icons:FindFirstChild(Pet.VisualName(petName))')
    c.replace(path, 'local price=require(ReplicatedStorage.Modules.NumberFormat).Price(Egg.price(name)*count)\n\t\t\t\tsetPair(frame,"Title",string.format("Open %d\\n%s Win",count,price))', '''local price=require(ReplicatedStorage.Modules.NumberFormat).Price(Egg.price(name)*count)
                setPair(frame,"Title",Egg.purchasable(name) and string.format("Open %d\\n%s Win",count,price) or "Unavailable")
                local button=frame:FindFirstChild("Button")
                if button and button:IsA("GuiButton") then button.Active=Egg.purchasable(name);button.Interactable=button.Active end''')
    c.replace(path, 'string.format(Config.Eggs.titleFormat, name)', 'string.format(Config.Eggs.titleFormat, Egg.displayName(name))')
    c.replace(path, 'local function press(name: string, button: string, count: number)\n', 'local function press(name: string, button: string, count: number)\n if not Egg.purchasable(name) or Egg.world(name)~=(Player:GetAttribute("CurrentWorld") or 1) then return end\n')
    c.replace(path, 'local name = egg.part.Name', 'local name = Egg.identity(egg.part)')
    for text in ['egg.part.Name','part.Name']:
        # Every remaining use denotes the Egg identity, not its physical Instance name.
        count=c.get(path).count(text)
        c.replace(path,text,('Egg.identity(egg.part)' if text=='egg.part.Name' else 'Egg.identity(part)'),count)
    c.replace(path, 'amount.Text=require(ReplicatedStorage.Modules.NumberFormat).Price(Egg.price(Egg.identity(part)))', 'amount.Text=Egg.purchasable(Egg.identity(part)) and require(ReplicatedStorage.Modules.NumberFormat).Price(Egg.price(Egg.identity(part))) or "Unavailable"')
    c.replace(path, '\t\tif not egg.open then continue end', '\t\tif not egg.open or Egg.world(Egg.identity(egg.part))~=(Player:GetAttribute("CurrentWorld") or 1) then continue end')
    old='''\tlocal folder = workspace:WaitForChild(Egg.FolderName, WAIT_TIMEOUT)
\tif not folder then
\t\twarn(`[EggClient] could not find {workspace:GetFullName()}.{Egg.FolderName}`)
\t\treturn
\tend

\tfor _, child in ipairs(folder:GetChildren()) do
\t\tif not child:IsA("BasePart") or not Egg.isEgg(child.Name) then continue end

\t\tregister(child)
\tend

\tfolder.ChildAdded:Connect(function(child)
\t\tif not child:IsA("BasePart") or not Egg.isEgg(child.Name) then return end

\t\tregister(child)
\tend)'''
    c.replace(path, old, ''' for _,part in ipairs(Egg.parts()) do register(part) end
 workspace.DescendantAdded:Connect(function(part)
  if part:IsA("BasePart") and Egg.part(Egg.identity(part))==part then register(part) end
 end)''')
    path='StarterPlayer.StarterPlayerScripts.Services.HatchClient'
    c.replace(path, 'local folder = Workspace:FindFirstChild(Egg.FolderName)\n\tlocal model = folder and folder:FindFirstChild(name)', 'local model = Egg.part(name)')


def facilities(c):
    path='ReplicatedStorage.Config.DumbbellStandConfig'
    c.replace(path, 'function M.GetItemId(index)', 'function M.GetItemId(index,worldId)')
    c.replace(path, 'index > #Master.GetSorted()', 'index > #Master.GetSorted(worldId or 1)')
    c.replace(path, 'string.format("NORMAL_%02d", index)', 'string.format(worldId==2 and "W2_NORMAL_%02d" or "NORMAL_%02d", index)')
    c.replace(path, 'function M.GetPress(folder, index)', 'function M.GetPress(folder, index,worldId)')
    c.replace(path, 'if not M.GetItemId(index) or not folder', 'if not M.GetItemId(index,worldId) or not folder')
    c.replace(path, 'function M.GetStandingIndex(folder, position)', 'function M.GetStandingIndex(folder, position,worldId)')
    c.replace(path, 'ipairs(Master.GetSorted())', 'ipairs(Master.GetSorted(worldId or 1))')
    c.replace(path, 'M.GetPress(folder, index), position', 'M.GetPress(folder, index,worldId), position')
    c.append(path, '''function M.GetFolder(worldId)
 if worldId~=2 then return workspace:FindFirstChild(M.FolderName) end
 local map=workspace:FindFirstChild("World2Map")
 local area=map and map:FindFirstChild("TrainingArea")
 local displays=area and area:FindFirstChild("DumbbellDisplays")
 return displays and displays:FindFirstChild(M.FolderName)
end''', 'return table.freeze(M)')
    path='ServerScriptService.Services.DumbbellStandService'
    c.replace(path, 'if player.Parent ~= Players or (player:GetAttribute("CurrentWorld") or 1) ~= 1 then return nil end', 'if player.Parent ~= Players then return nil end\n local worldId=player:GetAttribute("CurrentWorld")==2 and 2 or 1')
    c.replace(path, 'Config.GetStandingIndex(workspace:FindFirstChild(Config.FolderName), root.Position)', 'Config.GetStandingIndex(Config.GetFolder(worldId), root.Position,worldId)')
    c.replace(path, '   Config.AdvanceEntry(state, player.Character, standing(player))', '   local worldId=player:GetAttribute("CurrentWorld")==2 and 2 or 1\n   if state.WorldId~=worldId then state.Index=nil;state.WorldId=worldId end\n   Config.AdvanceEntry(state, player.Character, standing(player))')
    c.replace(path, 'Config.GetItemId(state.Index)', 'Config.GetItemId(state.Index,state.WorldId)')
    path='StarterPlayer.StarterPlayerScripts.Services.DumbbellStandClient'
    c.replace(path, ' local function render()\n  local folder = workspace:FindFirstChild(Config.FolderName)', ' local function renderWorld(worldId)\n  local folder = Config.GetFolder(worldId)')
    c.replace(path, 'ipairs(Master.GetSorted())', 'ipairs(Master.GetSorted(worldId))')
    c.replace(path, 'Config.GetPress(folder, index)', 'Config.GetPress(folder, index,worldId)')
    c.replace(path, ' -- Read-only state presentation;', ' local function render() renderWorld(1);renderWorld(2) end\n -- Read-only state presentation;')
    c.replace(path, ' local folder = workspace:FindFirstChild(Config.FolderName)\n if folder then bind(folder) else render() end', ' for worldId=1,2 do local folder=Config.GetFolder(worldId);if folder then bind(folder) end end\n workspace.DescendantAdded:Connect(function(child) if child==Config.GetFolder(2) then bind(child) end end)\n render()')
    path='ReplicatedStorage.Config.TreadmillConfig'
    c.append(path, '''-- Only the seven existing, exact World2 roots authorize World2 training.
local World2=require(script.Parent.World2GameplayConfig)
local stationTypes={1,1,2,2,3,3,4}
function Config.WorldForModel(model)
 if not model then return nil end
 if model.Parent==workspace:FindFirstChild("Treadmills") and Config.Get(model.Name) then return 1 end
 local map=workspace:FindFirstChild("World2Map")
 local area=map and map:FindFirstChild("TrainingArea")
 local folder=area and area:FindFirstChild("TreadmillDisplays")
 local index=tonumber(model.Name)
 if folder and model.Parent==folder and index and model.Name==string.format("%02d",index) and stationTypes[index] then return 2 end
end
function Config.GetForModel(model)
 local world=Config.WorldForModel(model)
 if world==1 then return Config.Get(model.Name) end
 if world==2 then
  local index=stationTypes[tonumber(model.Name)]
  return World2.Treadmills[index],"World2_"..index
 end
end''', 'return Config')
    path='ServerScriptService.Services.TrainingManager'
    c.replace(path, 'local TrainingManager={}', 'local TrainingManager={}\nlocal Data=require(game.ServerScriptService.Services.PlayerDataService)')
    c.replace(path, ' local config=TreadmillConfig.Get(treadmill.Name)', ' local config=TreadmillConfig.GetForModel(treadmill)')
    c.replace(path, ' if not config or not finitePositive(config.Multiplier) then return false end', ''' if not config or not finitePositive(config.Multiplier) then return false end
 if TreadmillConfig.WorldForModel(treadmill)~=(player:GetAttribute("CurrentWorld") or 1) or not Data.IsLoaded(player) then return false,config end
 if config.PurchaseEnabled==false then return false,config end''')
    c.replace(path, 'local config=occupiedTreadmill and TreadmillConfig.Get(occupiedTreadmill.Name)', 'local config=occupiedTreadmill and TreadmillConfig.GetForModel(occupiedTreadmill)')
    c.replace(path, '  if treadmill.Parent==treadmillFolder then', '  if TreadmillConfig.WorldForModel(treadmill) then')
    c.replace(path, 'assert(TreadmillConfig.Get(name),', 'assert(TreadmillConfig.GetForModel(treadmill),')
    path='ServerScriptService.Systems.Controllers.TrainingController'
    c.replace(path, ' p:SetAttribute("IsTraining",false)', ' p:SetAttribute("IsTraining",false)\n p:GetAttributeChangedSignal("CurrentWorld"):Connect(function() TrainingManager.StopTraining(p);walkState[p]=nil end)')
    path='StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient'
    c.replace(path, 'local entry = Config.Get(modelName)', 'local entry = Config.GetForModel(model)\n  if not entry then continue end\n  if Config.WorldForModel(model)==2 then\n   local label=model:FindFirstChild("StationBillboard") and model.StationBillboard:FindFirstChild("Multiplier")\n   if label then label.Text=tostring(entry.Multiplier).."x Strength\\n"..(entry.PurchaseEnabled==false and "Robux - Unavailable" or (entry.RequiredRebirth>0 and "Rebirth "..entry.RequiredRebirth.." Required" or "Available")) end\n  end')
    path='StarterPlayer.StarterPlayerScripts.UI.TreadmillGuideClient'
    c.replace(path, 'Config.Get(model.Name)', 'Config.GetForModel(model)')
    path='ServerScriptService.Services.GamePassService'
    c.replace(path, 'function M.GetWinReward(player,baseReward)\n', 'function M.GetWinReward(player,baseReward,worldId)\n if worldId==2 then return math.floor(tonumber(baseReward) or 0) end -- No configured World2 Win pass; never borrow World1 IDs.\n')
    path='ServerScriptService.Services.TrophyRewardService'
    for text in ['RewardConfig.GetBaseReward(r.Stage,worldId)','baseReward']:
        old='GamePass.GetWinReward(player, '+text+')'
        count=c.get(path).count(old)
        c.replace(path,old,'GamePass.GetWinReward(player, '+text+',worldId)',count)


def presentation(c):
    path='ServerScriptService.Services.TrainingLobbyAreaService'
    c.replace(path, 'local function getTrainingFloor()', 'local function getTrainingFloor(player)')
    c.replace(path, 'Workspace:FindFirstChild("GeneratedMap")', 'Workspace:FindFirstChild(player:GetAttribute("CurrentWorld")==2 and "World2Map" or "GeneratedMap")')
    c.replace(path, 'local floor = getTrainingFloor()', 'local floor = getTrainingFloor(player)')
    path='ReplicatedStorage.Modules.Pet'
    c.append(path, '''function Pet.StrengthText(name)
 local entry=World2.Pets[name]
 if entry then return string.format("Strength x%g",entry.Multiplier) end
 local percent=Pet.StrengthPercent(name)
 return percent and string.format("Strength +%g%%",percent) or "Cosmetic pet"
end''','return Pet')
    path='StarterPlayer.StarterPlayerScripts.Services.PetClient'
    c.replace(path, 'percent and string.format("Strength +%g%%",percent) or "Cosmetic pet"', 'Pet.StrengthText(name)')
    path='StarterGui.StrengthGui.InventoryPanelClient'
    c.replace(path, 'label(card,"Multiplier","+"..tostring(item.StrengthBonus).." Strength"', 'label(card,"Multiplier",(item.WorldId==2 and "World 2 " or "").."+"..tostring(item.StrengthBonus).." Strength"')
    path='StarterGui.StrengthGui.ItemInventoryTabClient'
    for name in ['GetProteinBonus','GetGloveBossDamageBonus','GetBeltTreadmillBonus']:
        c.replace(path,'ItemMultiplierConfig.'+name+'(item.Rarity)','ItemMultiplierConfig.'+name+'(item.Rarity,item.WorldId)')
    c.replace(path, 'return x.Element<y.Element', 'if (x.WorldId or 1)~=(y.WorldId or 1) then return (x.WorldId or 1)<(y.WorldId or 1) end\n   return x.Element<y.Element')
    c.replace(path, 'label(c,"Effect",effect(item)', 'label(c,"Effect","W"..tostring(item.WorldId or 1).." "..effect(item)')
    path='StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient'
    c.replace(path, 'definition.Get(item.Rarity)', 'definition.Get(item.Rarity,item.WorldId)')
    c.replace(path, 'gameRemotes:WaitForChild("CombatState").OnClientEvent:Connect(function(event)', 'local function combatEvent(event)')
    c.replace(path, 'end)\nplayer:GetAttributeChangedSignal("IsTraining")', '''end
gameRemotes:WaitForChild("CombatState").OnClientEvent:Connect(function(event)if player:GetAttribute("CurrentWorld")~=2 then combatEvent(event) end end)
gameRemotes:WaitForChild("World2CombatState").OnClientEvent:Connect(function(event)if player:GetAttribute("CurrentWorld")==2 then combatEvent(event) end end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()lastAttackId=0;stopGlove()end)
player:GetAttributeChangedSignal("IsTraining")''')
    path='StarterPlayer.StarterPlayerScripts.UI.TrophyRewardFeedbackClient'
    c.replace(path, 'remote.OnClientEvent:Connect(function(data)', 'local function rewardEvent(data)')
    c.replace(path, 'end)\n\nscript.Destroying', '''end
remote.OnClientEvent:Connect(rewardEvent)
ReplicatedStorage.Remotes.GameRemotes:WaitForChild("World2CombatState").OnClientEvent:Connect(rewardEvent)

script.Destroying''')
    path='StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New'
    c.replace(path, 'Name=info.Rarity.." "..info.Element.." "..info.ItemType', 'Name=Master.DisplayName(info)')
    c.replace(path, 'Name=completed.Rarity.." "..completed.Element.." "..completed.ItemType', 'Name=Master.DisplayName(completed)',2)
    c.replace(path, 'local model=workspace:FindFirstChild("RestockShop")', '''local model=workspace:FindFirstChild("RestockShop")
  if player:GetAttribute("CurrentWorld")==2 then
   local map=workspace:FindFirstChild("World2Map");local lobby=map and map:FindFirstChild("TrainingArea")
   local facilities=lobby and lobby:FindFirstChild("FacilityDisplays")
   model=facilities and facilities:FindFirstChild("MergeDisplay")
  end''')
    c.replace(path, 'and (player:GetAttribute("CurrentWorld") or 1)==1 then', 'then')
    path='StarterGui.StrengthGui.InventoryCapacityUpgradeClient'
    c.replace(path, '\tlocal found = workspace:FindFirstChild("ShopStallTemplate")', ''' local found=workspace:FindFirstChild("ShopStallTemplate")
 if player:GetAttribute("CurrentWorld")==2 then
  local map=workspace:FindFirstChild("World2Map");local lobby=map and map:FindFirstChild("TrainingArea")
  local facilities=lobby and lobby:FindFirstChild("FacilityDisplays")
  found=facilities and facilities:FindFirstChild("UpgradesDisplay")
 end''')
    c.replace(path, ' and (player:GetAttribute("CurrentWorld") or 1) == 1 then', ' then')
    path='ServerScriptService.Services.AuraService'
    c.replace(path, '  if id=="Red" then out[id]=', '  if Config.Get(id).PurchaseEnabled==false then out[id]=false\n  elseif id=="Red" then out[id]=')
    path='StarterGui.StrengthGui.AuraInventoryClient'
    c.replace(path, 'b.Label.Text=notice[id] or (isEquipped', 'b.Label.Text=notice[id] or (aura.PurchaseEnabled==false and "UNAVAILABLE" or isEquipped')
    c.replace(path, 'Presentation.SetButtonEnabled(b,loaded and not pending)', 'Presentation.SetButtonEnabled(b,loaded and not pending and aura.PurchaseEnabled~=false)')
    c.replace(path, 'card.Price.Amount.Text=aura.PurchaseType==', 'card.Price.Amount.Text=aura.PurchaseEnabled==false and "" or aura.PurchaseType==')
    c.replace(path, 'if aura.PurchaseType~="Entitlement" then', 'if aura.PurchaseType~="Entitlement" and aura.PurchaseEnabled~=false then')
    c.replace(path, 'if not loaded or pending then return end', 'if not loaded or pending or Config.Get(id).PurchaseEnabled==false then return end')
    path='StarterPlayer.StarterPlayerScripts.Services.EggClient'
    c.replace(path, 'local function setIcon(frame: ImageLabel, petName: string)\n', 'local function setIcon(frame: ImageLabel, petName: string)\n if Pet.isLimited(petName) then require(ReplicatedStorage.Modules.LimitedPetViewport).bind(frame,petName);return end\n')
    path='StarterGui.StrengthGui.EssentialStudShopClient'
    c.replace(path, 'local itemOrder=20', '''local itemOrder=20
for _,card in ipairs(holder:GetChildren()) do if card:GetAttribute("PurchaseKind")=="Dumbbell" then itemOrder=math.max(itemOrder,card.LayoutOrder+1) end end
local template
for _,card in ipairs(holder:GetChildren()) do if card:GetAttribute("PurchaseKind")=="Item" then template=card;break end end
if template then
 local ids={};for id,item in pairs(ItemMaster.GetAll()) do if item.WorldId==2 and item.ShopPurchasable then table.insert(ids,id) end end
 table.sort(ids)
 for _,id in ipairs(ids) do
  local card=template:Clone();card.Name="Item_"..id;card:SetAttribute("PurchaseKey",id);card.Parent=holder
  local title=card:FindFirstChild("Title");if title then title.Text=ItemMaster.DisplayName(ItemMaster.Get(id)) end
 end
end''')
    c.replace(path, 'if title then title.Text="+"..tostring(item.StrengthBonus).." Strength" end', 'if title then title.Text=(item.WorldId==2 and "World 2 " or "").."+"..tostring(item.StrengthBonus).." Strength" end')


def combat_return(c):
    # Apply the approved Glove damage in the old lottery branch as well, without
    # changing its outcome policy, attack cap, timing or wall damage calculation.
    c.replace('ServerScriptService.World.BossCombatService', 'math.max(1,s.HP-s.Strength)', 'math.max(1,s.HP-s.BattleDamage)')
    c.replace('StarterPlayer.StarterPlayerScripts.Combat.CombatClient', 'TrophyConfig.GetBaseReward(d.Stage)', 'TrophyConfig.GetBaseReward(d.Stage,worldId)')
    path='ServerScriptService.World.EnemyManager'
    c.replace(path, ' local ps=state(p)\n if RunInventory then ps.RunInventoryId=RunInventory.Reset(p,true) end', ''' local ps=state(p)
 if worldId==2 then
  ps.RunReturnId=game:GetService("HttpService"):GenerateGUID(false)
  p:SetAttribute("World2RunId",ps.RunReturnId)
 end
 if RunInventory then ps.RunInventoryId=RunInventory.Reset(p,true) end''')
    path='ServerScriptService.Services.RunReturnService'
    c.replace(path, 'local function returnToLobby(player, character, spawn, speed)', 'local function returnToLobby(player, character, spawn, speed, worldEnemy)')
    c.replace(path, '\tEnemy.InitializePlayer(player)', '\t(worldEnemy or Enemy).InitializePlayer(player)')
    c.replace(path, '\tRun.Invalidate(player)', '\tif not worldEnemy then Run.Invalidate(player) end')
    c.replace(path, '\t\tlocal spawn = Trophy.GetLobbySpawn()', '''  if player:GetAttribute("CurrentWorld")==2 then
   local Data=require(Services.PlayerDataService)
   local session=Data.Get(player)
   if not session or not session.Loaded or session.Saving or session.PendingItemMutation or session.OwnershipLost then return false,"DataSaving" end
   local worldEnemy=require(game.ServerScriptService.World.EnemyManager).ForWorld(2)
   local worldTrophy=require(Services.TrophyRewardService).ForWorld(2)
   local wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(2)
   local currentStage=player:GetAttribute("World2CurrentStage") or 1
   local ps=worldEnemy.GetPlayerState(player)
   if not worldEnemy.IsReady() or not ps or ps.RunReturnId~=runId then return false,"StaleRun" end
   if ps.Defeated[currentStage] or not wall.IsBossUnlockedForStage(player,currentStage) then return false,"NotReturnable" end
   local character=player.Character;local hum=character and character:FindFirstChildOfClass("Humanoid")
   local root=character and character:FindFirstChild("HumanoidRootPart")
   local spawn=worldTrophy.GetLobbySpawn()
   if not root or not hum or hum.Health<=0 or not spawn then return false,"CharacterNotReady" end
   returnToLobby(player,character,spawn,Speed.GetState(player).WalkSpeed,worldEnemy)
   return true,"Returned"
  end
  local spawn = Trophy.GetLobbySpawn()''')
    path='StarterGui.StrengthGui.RunReturnClient'
    c.replace(path, 'local style = gui.StrengthLevelHUD.LevelPanel.Level', '''local combat2=RS.Remotes.GameRemotes:WaitForChild("World2CombatState")
local function activeCombat()return player:GetAttribute("CurrentWorld")==2 and combat2 or combat end
local function currentStage()return player:GetAttribute(player:GetAttribute("CurrentWorld")==2 and "World2CurrentStage" or "CurrentStage") or 1 end
local function runId()return player:GetAttribute(player:GetAttribute("CurrentWorld")==2 and "World2RunId" or "RunInventoryId") end
local style = gui.StrengthLevelHUD.LevelPanel.Level''')
    c.replace(path, '(player:GetAttribute("CurrentWorld") or 1) == 1\n\t\tand player:GetAttribute("RunInventoryActive") == true', '(player:GetAttribute("CurrentWorld")==2 or player:GetAttribute("RunInventoryActive")==true)')
    # Only the two presentation indices use the helper; its own implementation stays intact.
    c.replace(path, 'unlocked[player:GetAttribute("CurrentStage") or 1]', 'unlocked[currentStage()]')
    c.replace(path, 'defeated[player:GetAttribute("CurrentStage") or 1]', 'defeated[currentStage()]')
    c.replace(path, 'local id = player:GetAttribute("RunInventoryId")', 'local id = runId()')
    c.replace(path, '"保存中…"', '"Saving..."')
    c.replace(path, '"失敗\\n再試行"', '"Retry"')
    c.replace(path, '{"CurrentWorld", "CurrentStage", "RunInventoryActive", "RunReturnBusy"}', '{"CurrentWorld", "CurrentStage", "World2CurrentStage", "RunInventoryActive", "RunReturnBusy"}')
    c.replace(path, 'combat:FireServer({Type = "RequestState"})', 'activeCombat():FireServer({Type = "RequestState"})',2)
    c.replace(path, 'combat.OnClientEvent:Connect(function(data)', 'local function onCombat(data)')
    c.replace(path, 'end)\n-- Character health gates', '''end
combat.OnClientEvent:Connect(function(data)if player:GetAttribute("CurrentWorld")~=2 then onCombat(data) end end)
combat2.OnClientEvent:Connect(function(data)if player:GetAttribute("CurrentWorld")==2 then onCombat(data) end end)
local function reconcileWorld()
 initialized=false;waitingForProgress=false;pending=nil;failed=false
 table.clear(unlocked);table.clear(defeated);render()
 activeCombat():FireServer({Type="RequestState"})
end
player:GetAttributeChangedSignal("CurrentWorld"):Connect(reconcileWorld)
player:GetAttributeChangedSignal("World2RunId"):Connect(function()if player:GetAttribute("CurrentWorld")==2 then reconcileWorld() end end)
-- Character health gates''')
    c.replace(path, 'workspace:FindFirstChild("GeneratedMap")', 'workspace:FindFirstChild(player:GetAttribute("CurrentWorld")==2 and "World2Map" or "GeneratedMap")')


def build(raw):
    c=Changes(raw)
    configure(c)
    items(c)
    pets(c)
    facilities(c)
    presentation(c)
    combat_return(c)
    return c


if __name__=='__main__':
    c=build(PLACE.read_bytes())
    changed=c.write_mirrors()
    print('Prepared actual-Source changes:',len(changed))
