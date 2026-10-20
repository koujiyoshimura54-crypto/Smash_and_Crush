"""Guarded Source-only update of the current place; no alternate place or Save."""
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess

from rbxl_rows import Editor, s, string
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '97bb8db77963f5d5c7c050bbc93793b4e244545cbb6e11bc25679ea086d89dcd'
FILES = {
    'ServerScriptService.Services.PlayerDataService': 'src/ServerScriptService/Services/PlayerDataService.luau',
    'ServerScriptService.Services.GamePassService': 'src/ServerScriptService/Services/GamePassService.luau',
    'ServerScriptService.Services.SpeedService': 'src/ServerScriptService/Services/SpeedService.luau',
    'ServerScriptService.Systems.Controllers.SpeedController': 'src/ServerScriptService/Systems/Controllers/SpeedController.server.luau',
    'ReplicatedStorage.Modules.InventoryPresentation': 'src/ReplicatedStorage/Modules/InventoryPresentation.luau',
    'StarterGui.StrengthGui.InventoryCapacityUpgradeClient': 'src/StarterGui/StrengthGui/InventoryCapacityUpgradeClient.client.luau',
    'StarterGui.StrengthGui.SpeedInventoryClient': 'src/StarterGui/StrengthGui/SpeedInventoryClient.client.luau',
    'StarterGui.StrengthGui.InventoryPanelClient': 'src/StarterGui/StrengthGui/InventoryPanelClient.client.luau',
    'StarterGui.StrengthGui.ItemInventoryTabClient': 'src/StarterGui/StrengthGui/ItemInventoryTabClient.client.luau',
    'StarterGui.StrengthGui.AuraInventoryClient': 'src/StarterGui/StrengthGui/AuraInventoryClient.client.luau',
    'StarterGui.StrengthGui.EssentialStudShopClient': 'src/StarterGui/StrengthGui/EssentialStudShopClient.client.luau',
    'StarterPlayer.StarterPlayerScripts.Services.PetClient': 'src/StarterPlayer/StarterPlayerScripts/Services/PetClient.luau',
    'StarterPlayer.StarterPlayerScripts.Services.DumbbellStandClient': 'src/StarterPlayer/StarterPlayerScripts/Services/DumbbellStandClient.luau',
    'StarterPlayer.StarterPlayerScripts.UI.SizeChangeClient': 'src/StarterPlayer/StarterPlayerScripts/UI/SizeChangeClient.client.luau',
}


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Target changed; inspect concurrent changes before writing'
    editor = Editor(raw)
    editor.path = functools.lru_cache(None)(editor.path)
    paths = {editor.path(ref): ref for ref in editor.parents}
    hashes = {}
    for path, relative in FILES.items():
        file = ROOT / relative
        source = file.read_text(encoding='utf8')
        assert 'SpeedEquipmentMemory' not in source and 'SpeedEquipmentAudit' not in source
        subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'), str(file)],
                       check=True, stdout=subprocess.DEVNULL)
        old = string(editor.get(paths[path], 'Source'), 0)[0].decode()
        assert old != source, path
        hashes[path] = {'before': hashlib.sha256(old.encode()).hexdigest(),
                        'after': hashlib.sha256(source.encode()).hexdigest()}
        editor.set(paths[path], 'Source', s(source))
    result, _ = editor.build()
    after = Editor(result)
    assert editor.parents == after.parents and editor.classes == after.classes
    assert editor.doc.unique_ids == after.doc.unique_ids
    for key in editor.columns:
        if key in editor.changed:
            assert editor.col(*key)[3] == after.col(*key)[3]
        else:
            assert editor.doc.chunks[editor.columns[key][0]][1] == after.doc.chunks[after.columns[key][0]][1], key
    for (kind, a, _, _), (kind2, b, _, _) in zip(editor.doc.chunks, after.doc.chunks):
        assert kind == kind2 and (a == b or kind == b'PROP')
    assert canonicalize(result)[0] == result
    Document(result).assert_studio_bounds()
    assert PLACE.read_bytes() == raw, 'Target changed during validation'
    with PLACE.open('r+b') as output:
        output.write(result)
        output.truncate()
        output.flush()
        os.fsync(output.fileno())
    assert PLACE.read_bytes() == result
    report = {'path': str(PLACE), 'inputSha256': EXPECTED,
              'outputSha256': hashlib.sha256(result).hexdigest(), 'changedSources': hashes,
              'allOtherSourcesPropertiesParentsUniqueIdsSharedStringsUnchanged': True,
              'boss_stageSkip_rebirth_growth_returnSpeed_sourcesUnchanged': True,
              'syntaxReDecodeReferences': 'passed', 'alternatePlaceCreated': False}
    directory = ROOT / 'reports/SpeedEquipment_20261020'
    directory.mkdir(exist_ok=True)
    (directory / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
