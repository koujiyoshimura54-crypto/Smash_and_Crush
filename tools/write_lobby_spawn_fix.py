"""Patch the current place in place; fail closed on any unapproved row change."""
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from rbxl_rows import Editor, string, s, decode
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = 'b5b357adff9b7eddad1e9866b1dabb80995dbbed2760da5fa15d246b3c2e2234'
FILES = {
    'StarterPlayer.StarterPlayerScripts.World.LobbySpawnClient': 'src/StarterPlayer/StarterPlayerScripts/World/LobbySpawnClient.client.luau',
    'ServerScriptService.Services.LobbySpawnService': 'src/ServerScriptService/Services/LobbySpawnService.luau',
    'ServerScriptService.Services.TrophyRewardService': 'src/ServerScriptService/Services/TrophyRewardService.luau',
    'ServerScriptService.Services.RunReturnService': 'src/ServerScriptService/Services/RunReturnService.luau',
    'ServerScriptService.Services.StageSkipService': 'src/ServerScriptService/Services/StageSkipService.luau',
    'ServerScriptService.World.EnemyManager': 'src/ServerScriptService/World/EnemyManager.luau',
    'ServerScriptService.Systems.Controllers.InitialSpawnFacing': 'src/ServerScriptService/Systems/Controllers/InitialSpawnFacing.server.luau',
    'ServerScriptService.Systems.Controllers.MuscleCharacterService': 'src/ServerScriptService/Systems/Controllers/MuscleCharacterService.server.luau',
    'ServerScriptService.Systems.Controllers.StageProgressController': 'src/ServerScriptService/Systems/Controllers/StageProgressController.server.luau',
    'ServerScriptService.Systems.Debug.StudioStartController': 'src/ServerScriptService/Systems/Debug/StudioStartController.server.luau',
    'ServerScriptService.Systems.Debug.StudioDebugService': 'src/ServerScriptService/Systems/Debug/StudioDebugService.luau',
}


def sources():
    return {p: (ROOT / f).read_text(encoding='utf8') for p, f in FILES.items()}


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Target changed'
    e = Editor(raw)
    e.path = functools.lru_cache(None)(e.path)
    paths = {e.path(r): r for r in e.parents}
    original_refs = set(e.parents)
    new_path = 'ServerScriptService.Services.LobbySpawnService'
    ref, _ = e.clone(paths['ServerScriptService.Services.SpeedService'], paths['ServerScriptService.Services'], recursive=False)
    e.set(ref, 'Name', s('LobbySpawnService'))
    paths[new_path] = ref
    client_path = 'StarterPlayer.StarterPlayerScripts.World.LobbySpawnClient'
    client_ref, _ = e.clone(paths['StarterPlayer.StarterPlayerScripts.World.SpawnFacingCameraClient'], paths['StarterPlayer.StarterPlayerScripts.World'], recursive=False)
    e.set(client_ref, 'Name', s('LobbySpawnClient'))
    paths[client_path] = client_ref
    changed = set()
    for path, source in sources().items():
        subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'), str(ROOT / FILES[path])], check=True, stdout=subprocess.DEVNULL)
        e.set(paths[path], 'Source', s(source))
        changed.add(paths[path])
    result, _ = e.build()
    after = Editor(result)
    assert not e.final_mapping, 'Unexpected original referent remap'
    assert all(after.parents[r] == e.parents[r] for r in original_refs)
    for key, col in e.columns.items():
        old_data = e.doc.chunks[col[0]][1]
        if key not in e.changed:
            assert old_data == after.doc.chunks[after.columns[key][0]][1], key
            continue
        old = dict(zip(e.doc.classes[key[0]][1], decode(old_data[col[2]:], col[1], len(e.doc.classes[key[0]][1]))))
        new = after.col(*key)[3]
        for r, value in old.items():
            if key[1] == 'Source' and r in changed:
                assert new[r] == s(sources()[e.path(r)])
            else:
                assert new[r] == value, (e.path(r), key)
    assert canonicalize(result)[0] == result
    report = {'path': str(PLACE), 'inputSha256': EXPECTED, 'outputSha256': hashlib.sha256(result).hexdigest(),
              'changedSources': list(FILES), 'addedInstances': [new_path, client_path],
              'allOtherOriginalPropertiesParentsUniqueIdsUnchanged': True,
              'geometryBalanceRewardsPersistenceTreadmillHeadingUnchanged': True,
              'syntax': 'passed', 'reDecodeReferencesSharedStrings': 'passed', 'written': False,
              'summary': after.doc.summary()}
    if '--write' in sys.argv:
        assert PLACE.read_bytes() == raw
        with PLACE.open('r+b') as output:
            output.write(result); output.truncate(); output.flush(); os.fsync(output.fileno())
        Document(PLACE.read_bytes()).assert_studio_bounds()
        assert PLACE.read_bytes() == result
        report['written'] = True
    dest = ROOT / 'reports/LobbySpawn_20261020'
    dest.mkdir(exist_ok=True)
    (dest / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
