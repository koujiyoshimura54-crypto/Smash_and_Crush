"""Execute final catalogue, purchase/equip/stand and UI Source with memory adapters.

No Roblox Play, real players, datastore writes or payments. UI geometry assertions
are simulations, not rendering/asset-load or physical-input verification.
"""
from pathlib import Path
import json
import subprocess

root = Path(__file__).resolve().parents[1]
def read(path):
    return (root / 'src' / path).read_text(encoding='utf-8')
def between(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]

fixture = (root / 'tests/World1DumbbellTwelveOffline.spec.luau').read_text(encoding='utf-8')
sources = {
    'Master': 'ReplicatedStorage/Config/DumbbellItemMaster.luau',
    'Stand': 'ReplicatedStorage/Config/DumbbellStandConfig.luau',
    'Service': 'ServerScriptService/Services/DumbbellService.luau',
    'Monitor': 'ServerScriptService/Services/DumbbellStandService.luau',
    'Controller': 'ServerScriptService/Systems/Controllers/DumbbellController.server.luau',
    'Strength': 'ServerScriptService/Services/StrengthManager.luau',
    'Format': 'ReplicatedStorage/Modules/NumberFormat.luau',
}
for key, path in sources.items():
    fixture = fixture.replace('-- SOURCE ' + key + '\n', 'local source' + key + '=' + json.dumps(read(path)) + '\n')
pds = read('ServerScriptService/Services/PlayerDataService.luau')
setter = between(pds, 'function PlayerDataService.SetEquippedDumbbell(', '-- Single-slot Aura authority.')
ownership = between(pds, '  if raw.OwnedDumbbells~=nil then', '  if raw.OwnedAuras~=nil then')
valid = between(pds, 'local function validEquipped(', 'local function normalize(raw)')
fixture = fixture.replace('-- PERSISTENCE', setter + '\n' + valid + '\nlocal function reload(raw)\n local d={OwnedDumbbells={}}\n' + ownership + '\n d.EquippedDumbbell=validEquipped(raw.EquippedDumbbell,d.OwnedDumbbells)\n return d\nend\n')
nodes = (root / 'tests/MergeShopPresentationOffline.py').read_text(encoding='utf-8')
nodes = between(nodes, 'local clones=0', 'local materialState=')
fixture = fixture.replace('-- UI NODES', nodes)
client = read('StarterGui/StrengthGui/InventoryPanelClient.client.luau')
shop = read('StarterGui/StrengthGui/EssentialStudShopClient.client.luau')
fixture = fixture.replace('-- INVENTORY HELPERS', between(client, 'local function round(', 'local function updateButtons()'))
fixture = fixture.replace('-- INVENTORY BUILD', between(client, 'local sortedItems=Master.GetSorted()', 'local function updateWin()'))
fixture = fixture.replace('-- INVENTORY STATE', between(client, 'local function updateButtons()', 'local function refreshState()'))
fixture = fixture.replace('-- INVENTORY LAYOUT', between(client, 'local function layout()', 'list:GetPropertyChangedSignal("AbsoluteSize")'))
fixture = fixture.replace('-- SHOP BUILD', between(shop, 'local function syncDumbbellCards()', 'local ItemMaster='))
fixture = fixture.replace('-- SHOP STATE', between(shop, 'local function renderDumbbellState(', 'local function refreshDumbbellState()'))
result = subprocess.run([str(Path(r'C:\Users\kouji\stage_skip_work\luau\luau.exe'))],
    input='assert(loadstring(' + json.dumps(fixture) + '))()\n', text=True, encoding='utf-8', capture_output=True)
print(result.stdout)
if result.returncode or result.stderr or 'WORLD1_DUMBBELL_TWELVE_PASS' not in result.stdout:
    raise SystemExit(result.stderr or 'Missing pass marker')
