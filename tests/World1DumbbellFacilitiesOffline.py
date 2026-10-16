"""Actual station presentation/float Source and saved Press geometry, memory only.

No Roblox rendering, physical input, DataStore or payment verification.
"""
from pathlib import Path
import json
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
geometry_path = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'reports/World1DumbbellFacilities_20261016.json'
geometry = json.loads(geometry_path.read_text(encoding='utf-8'))
if isinstance(geometry, dict):
    geometry = geometry['facilities']
fixture = (root / 'tests/World1DumbbellFacilitiesOffline.spec.luau').read_text(encoding='utf-8')
sources = {
    'Master': 'ReplicatedStorage/Config/DumbbellItemMaster.luau',
    'Config': 'ReplicatedStorage/Config/DumbbellStandConfig.luau',
    'Format': 'ReplicatedStorage/Modules/NumberFormat.luau',
    'Client': 'StarterPlayer/StarterPlayerScripts/Services/DumbbellStandClient.luau',
    'Float': 'StarterPlayer/StarterPlayerScripts/Services/FloatClient.luau',
}
for key, path in sources.items():
    fixture = fixture.replace('-- SOURCE ' + key, 'local source' + key + '=' + json.dumps((root / 'src' / path).read_text(encoding='utf-8')))
rows = []
for g in geometry:
    assert g['pressRotationId'] == 14
    rows.append('{position={' + ','.join(map(str, g['pressPosition'])) + '},size={' + ','.join(map(str, g['pressSize'])) + '}}')
fixture = fixture.replace('-- GEOMETRY', 'local geometry={' + ','.join(rows) + '}')
result = subprocess.run([r'C:\Users\kouji\stage_skip_work\luau\luau.exe'],
    input='assert(loadstring(' + json.dumps(fixture) + '))()\n', text=True, encoding='utf-8', capture_output=True)
print(result.stdout)
if result.returncode or result.stderr or 'WORLD1_DUMBBELL_FACILITIES_PASS' not in result.stdout:
    raise SystemExit(result.stderr or 'Missing pass marker')
