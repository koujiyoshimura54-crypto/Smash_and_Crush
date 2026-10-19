"""Read every populated cell of the owner's World2 workbook without changing it."""
import hashlib
import re
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

WORKBOOK = Path('C:/Users/kouji/Downloads/World2_数値一覧.xlsx')
NS = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}


def load():
    raw = WORKBOOK.read_bytes()
    with zipfile.ZipFile(WORKBOOK) as archive:
        workbook = ET.fromstring(archive.read('xl/workbook.xml'))
        sheets = workbook.findall('m:sheets/m:sheet', NS)
        assert len(sheets) == 1
        strings = []
        for entry in ET.fromstring(archive.read('xl/sharedStrings.xml')).findall('m:si', NS):
            texts = entry.findall('m:t', NS) + entry.findall('m:r/m:t', NS)
            strings.append(''.join(node.text or '' for node in texts))
        sheet = ET.fromstring(archive.read('xl/worksheets/sheet1.xml'))
        cells, formulas = {}, {}
        for cell in sheet.findall('m:sheetData/m:row/m:c', NS):
            value = cell.find('m:v', NS)
            text = value.text if value is not None else None
            if text is not None:
                if cell.get('t') == 's':
                    value = strings[int(text)]
                else:
                    number = float(text)
                    value = int(number) if number.is_integer() else float(format(number, '.15g'))
                cells[cell.get('r')] = value
            formula = cell.find('m:f', NS)
            if formula is not None:
                formulas[cell.get('r')] = dict(formula.attrib, text=formula.text)
        assert all(cells[f'{col}{row}'] == cells[f'B{row}'] * factor
                   for row in range(6, 16) for col, factor in [('E', .4), ('F', .5), ('G', .6), ('H', .8)])
    value = lambda column, row: cells[f'{column}{row}']
    stages = [dict(BossMaxHP=value('B', r), Walls=[value(c, r) for c in 'EFGH'], WinReward=value('D', r))
              for r in range(6, 16)]
    rebirth = {value('J', r): dict(Level=value('K', r), ReferenceStrength=value('L', r), Multiplier=value('M', r))
               for r in range(7, 17)}
    dumbbells = [dict(PriceWin=value('P', r), StrengthBonus=value('Q', r)) for r in range(6, 18)]
    items = {value('S', r): dict(ProteinBonus=value('U', r), GloveBossDamageBonus=value('V', r),
                               BeltTreadmillBonus=value('W', r), **({'PriceWin': value('T', r)} if r < 10
                               else {'MergeCostReference': value('T', r)})) for r in range(6, 11)}
    def rebirth_condition(row):
        text=value('AD',row)
        match=re.search(r'再生\s*([0-9０-９]+)',text)
        if match:return int(match.group(1))
        if text=='初期値':return 0
        assert value('AC',row)=='Robux' and text=='未定',text
        return None
    treadmills = [dict(Count=value('AA', r), Multiplier=value('AB', r), RequiredRebirth=rebirth_condition(r),
                       PurchaseEnabled=r != 9, PurchaseType='Robux' if r == 9 else 'Rebirth') for r in range(6, 10)]
    auras = [dict(StrengthBonus=value('AH', r), PurchaseEnabled=r != 11,
                  **({'PriceWin': value('AG', r)} if r < 11 else {})) for r in range(6, 12)]
    eggs = [dict(PriceWin=value('AK', r), PurchaseEnabled=True) for r in range(6, 10)]
    probabilities = [value('AO', r) for r in range(6, 13)]
    assert abs(sum(probabilities)-1) < 1e-12
    pet_multipliers = [[value(column, r) for r in range(6, 13)] for column in ['AP', 'AQ', 'AR', 'AS', 'AT']]
    data = dict(Stages=stages, Rebirth=rebirth, Dumbbells=dumbbells, Items=items, Treadmills=treadmills,
                Auras=auras, Eggs=eggs, PetProbabilities=probabilities, PetMultipliers=pet_multipliers)
    evidence = dict(path=str(WORKBOOK), sha256=hashlib.sha256(raw).hexdigest(), sheet=sheets[0].get('name'),
                    cells=cells, formulas=formulas, independentTables=True, parsed=data)
    return data, evidence


def lua(value, depth=0):
    import json
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '{' + ','.join(lua(v, depth+1) for v in value) + '}'
    assert isinstance(value, dict)
    rows = [('[' + lua(k) + ']' if isinstance(k, int) or not k.isidentifier() else k) + '=' + lua(v, depth+1)
            for k, v in value.items()]
    return '{\n' + '\n'.join(' '*(depth+1) + row + ',' for row in rows) + '\n' + ' '*depth + '}'


def generate():
    data, evidence = load()
    # New identities reuse only current approved visual species, never World1 ownership.
    data['PetSources'] = [
        ['Dog', 'Grey Cat', 'Pink Bunny', 'Sheep', 'Bear', 'Camel', 'Slime'],
        ['Cow', 'Giraffe', 'Lion', 'Lizard', 'Spider', 'Bat', 'Shroom'],
        ['Elephant', 'Mammoth', 'Penguin', 'Crocodile', 'Octopus', 'Shark', 'Ninja'],
        ['Turtle', 'Alien', 'Anglerfish', 'Dino', 'Scorpion', 'Evil Dragon', 'Chimpanzini Bananini'],
        ['Pet_042', 'Pet_064', 'Pet_081', 'Pet_086', 'Pet_094', 'Pet_024', 'Pet_135'],
    ]
    data['EggIds'] = ['W2_Basic', 'W2_Rare', 'W2_Legendary', 'W2_Mythic', 'W2_Limited']
    data['EggNames'] = ['World 2 Basic', 'World 2 Rare', 'World 2 Legendary', 'World 2 Mythic', 'World 2 Limited']
    data['DumbbellImages'] = [117636801345125,87392597068250,90484814439233,92409856077185,
                             76660708269544,73514550426804,86006626767728,101543601215487,
                             70465860935084,89190858658364,135716155094439,116813512043021]
    text = '-- Generated from World2_数値一覧.xlsx; independent tables, no row-based unlock links.\n'
    text += '-- Workbook SHA256: ' + evidence['sha256'] + '\nlocal C=' + lua(data) + '\n'
    text += '''C.WorldId=2
C.Version="World2Workbook_20261020"
C.Pets={}
for eggIndex,sources in ipairs(C.PetSources) do
 for slot,source in ipairs(sources) do
  C.Pets["W2 "..source]={WorldId=2,SourcePet=source,Egg=C.EggIds[eggIndex],Slot=slot,
   Multiplier=C.PetMultipliers[eggIndex][slot],Percent=C.PetProbabilities[slot]*100}
 end
end
C.PaidOffers={
 Treadmill04={Multiplier=C.Treadmills[4].Multiplier,PurchaseEnabled=false},
 Aura={StrengthBonus=C.Auras[6].StrengthBonus,PurchaseEnabled=false},
 LimitedEgg={EggId=C.EggIds[5],PurchaseEnabled=false},
}
local function freeze(value)
 if type(value)=="table" and not table.isfrozen(value) then
  for _,child in pairs(value) do freeze(child) end
  table.freeze(value)
 end
end
freeze(C)
return C
'''
    root = Path(__file__).resolve().parents[1]
    (root / 'src/ReplicatedStorage/Config/World2GameplayConfig.luau').write_text(text, encoding='utf-8')
    import json
    (root / 'reports/World2Workbook_20261020.json').write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding='utf-8')
    print('Read all cells; generated one World2 numeric authority:', len(evidence['cells']), 'populated cells')


if __name__ == '__main__':
    generate()
