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
client = (root / 'src/StarterPlayer/StarterPlayerScripts/Services/PetClient.luau').read_text(encoding='utf-8')
follow = (root / 'src/StarterPlayer/StarterPlayerScripts/Services/PetFollowClient.luau').read_text(encoding='utf-8')

def between(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]

limited = (root / 'src/ReplicatedStorage/Config/LimitedEggConfig.luau').read_text(encoding='utf-8')
hatch_client = (root / 'src/StarterPlayer/StarterPlayerScripts/Services/HatchClient.luau').read_text(encoding='utf-8')
pet_server = (root / 'src/ServerScriptService/Services/PetServer.luau').read_text(encoding='utf-8')

functions = between(pds, 'local function resolvePetMutation(', 'function PlayerDataService.ResolveItemMutation(')
set_win = between(pds, 'function PlayerDataService.SetWin(', 'function PlayerDataService.RecordStrengthGain(')
fixture = (root / 'tests/BasicEggOffline.spec.luau').read_text(encoding='utf-8')
fixture = fixture.replace('-- INSERT PET\n', 'local Pet=(function()\n' + pet + '\nend)()\n')
fixture = fixture.replace('-- INSERT TRANSACTIONS', set_win + '\n' + functions)
fixture = fixture.replace('-- INSERT EGG SERVER', 'local EggServer=(function()\n' + egg + '\nend)()')
fixture = fixture.replace('-- INSERT PET UI CHECKS', between(client, 'local function refreshChecks()', 'local function buildTile('))
fixture = fixture.replace('-- INSERT FOLLOW REFRESH', between(follow, 'local function indexOf(', 'local function update('))
fixture = fixture.replace('-- INSERT LIMITED CONFIG', 'modules.Limited=(function()\n'+limited+'\nend)()')
fixture = fixture.replace('-- INSERT LIMITED SERVER', 'local limitedServer=(function()\n'+pet_server+'\nend)()')
fixture = fixture.replace('-- INSERT LIMITED HATCH GATE', between(hatch_client, 'function HatchClient.play(Results:', 'function HatchClient.start()'))
command = 'assert(loadstring(' + json.dumps(fixture) + ', "BasicEggOffline"))()\n'
result = subprocess.run([sys.argv[1]], input=command, text=True, capture_output=True)
print(result.stdout)
if result.stderr or result.returncode or 'BASIC_EGG_OFFLINE_PASS' not in result.stdout:
    print(result.stderr, file=sys.stderr)
    raise SystemExit(1)
