"""Execute final World1 Egg/Pet/Strength Sources with memory-only adapters.

Usage: python tests/World1PetStrengthOffline.py <luau.exe>
No Roblox, real players, purchases, persistence, or Studio Play is used.
"""
from pathlib import Path
import json
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
def read(path):
    return (root / 'src' / path).read_text(encoding='utf-8')
def between(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]

config = read('ReplicatedStorage/Modules/Config.luau')
client = read('StarterPlayer/StarterPlayerScripts/Services/EggClient.luau')
pds = read('ServerScriptService/Services/PlayerDataService.luau')
sources = {
    'ConfigEggs': 'local Config={}\n' + between(config, 'Config.Eggs =', 'Config.Speed =') + '\nreturn Config',
    'Limited': read('ReplicatedStorage/Config/LimitedEggConfig.luau'),
    'Egg': read('ReplicatedStorage/Modules/Egg.luau'),
    'Pet': read('ReplicatedStorage/Modules/Pet.luau'),
    'PetServer': read('ServerScriptService/Services/PetServer.luau'),
    'EggServer': read('ServerScriptService/Services/EggServer.luau'),
    'Strength': read('ServerScriptService/Services/StrengthManager.luau'),
    'NumberFormat': read('ReplicatedStorage/Modules/NumberFormat.luau'),
}
fixture = (root / 'tests/World1PetStrengthOffline.spec.luau').read_text(encoding='utf-8')
for name, source in sources.items():
    fixture = fixture.replace('-- SOURCE ' + name + '\n', 'local source' + name + '=' + json.dumps(source) + '\n')
fixture = fixture.replace('-- TRANSACTIONS',
    between(pds, 'function PlayerDataService.SetWin(', 'function PlayerDataService.RecordStrengthGain(') + '\n' +
    between(pds, 'local function resolvePetMutation(', 'function PlayerDataService.ResolveItemMutation('))
fixture = fixture.replace('-- PRICE UI',
    between(client, 'local function setText(', 'local function setIcon(') + '\n' +
    between(client, 'local function stampSheet(', '\tlocal background = open:FindFirstChild(BACKGROUND_NAME)') + '\nend\n')
result = subprocess.run([sys.argv[1]], input='assert(loadstring(' + json.dumps(fixture) + '))()\n',
                        text=True, capture_output=True)
print(result.stdout)
if result.returncode or result.stderr or 'WORLD1_PET_STRENGTH_OFFLINE_PASS' not in result.stdout:
    print(result.stderr, file=sys.stderr)
    raise SystemExit(1)
