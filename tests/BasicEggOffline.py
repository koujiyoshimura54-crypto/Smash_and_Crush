"""Run exact production Pet transaction functions in Luau with an in-memory store.

Usage: python tests/BasicEggOffline.py /path/to/luau
No Studio, Roblox network, DataStore, or player data is accessed.
"""
from pathlib import Path
import json
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
pet = (root / 'src/ReplicatedStorage/Modules/Pet.luau').read_text(encoding='utf-8')
pds = (root / 'src/ServerScriptService/Services/PlayerDataService.luau').read_text(encoding='utf-8')
egg = (root / 'src/ServerScriptService/Services/EggServer.luau').read_text(encoding='utf-8')

def between(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]

functions = between(pds, 'local function resolvePetMutation(', 'function PlayerDataService.ResolveItemMutation(')
set_win = between(pds, 'function PlayerDataService.SetWin(', 'function PlayerDataService.RecordStrengthGain(')
fixture = (root / 'tests/BasicEggOffline.spec.luau').read_text(encoding='utf-8')
fixture = fixture.replace('-- INSERT PET', 'local Pet=(function()\n' + pet + '\nend)()')
fixture = fixture.replace('-- INSERT TRANSACTIONS', set_win + '\n' + functions)
fixture = fixture.replace('-- INSERT EGG SERVER', 'local EggServer=(function()\n' + egg + '\nend)()')
command = 'assert(loadstring(' + json.dumps(fixture) + ', "BasicEggOffline"))()\n'
result = subprocess.run([sys.argv[1]], input=command, text=True, capture_output=True)
print(result.stdout)
if result.stderr or result.returncode or 'BASIC_EGG_OFFLINE_PASS' not in result.stdout:
    print(result.stderr, file=sys.stderr)
    raise SystemExit(1)
