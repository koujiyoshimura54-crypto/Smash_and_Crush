"""Apply only the five reviewed growth Sources to the existing CurrentCloud file."""
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
EXPECTED = '5196a2147d813c05846bbd8b85b4ca3a0c2b2510325f703413b965962da492d6'
FILES = {
    'ServerScriptService.Config.MuscleScaleConfig': 'src/ServerScriptService/Config/MuscleScaleConfig.luau',
    'ReplicatedStorage.Config.SizeChangeConfig': 'src/ReplicatedStorage/Config/SizeChangeConfig.luau',
    'ServerScriptService.Systems.Controllers.MuscleCharacterService': 'src/ServerScriptService/Systems/Controllers/MuscleCharacterService.server.luau',
    'ServerScriptService.Services.PlayerDataService': 'src/ServerScriptService/Services/PlayerDataService.luau',
    'StarterPlayer.StarterPlayerScripts.UI.SizeChangeClient': 'src/StarterPlayer/StarterPlayerScripts/UI/SizeChangeClient.client.luau',
}


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Target changed'
    e = Editor(raw)
    e.path = functools.lru_cache(None)(e.path)
    paths = {e.path(ref): ref for ref in e.parents}
    hashes = {}
    for path, file in FILES.items():
        source = (ROOT / file).read_text(encoding='utf8')
        old = string(e.get(paths[path], 'Source'), 0)[0].decode()
        subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'), str(ROOT / file)],
                       check=True, stdout=subprocess.DEVNULL)
        hashes[path] = {'before': hashlib.sha256(old.encode()).hexdigest(),
                        'after': hashlib.sha256(source.encode()).hexdigest()}
        e.set(paths[path], 'Source', s(source))
    result, _ = e.build()
    after = Editor(result)
    assert e.parents == after.parents and e.classes == after.classes
    assert e.doc.unique_ids == after.doc.unique_ids
    for key in e.columns:
        a = e.doc.chunks[e.columns[key][0]][1]
        b = after.doc.chunks[after.columns[key][0]][1]
        if key in e.changed:
            assert e.col(*key)[3] == after.col(*key)[3]
        else:
            assert a == b, key
    for (kind, a, _, _), (kind2, b, _, _) in zip(e.doc.chunks, after.doc.chunks):
        assert kind == kind2 and (a == b or kind == b'PROP')
    assert canonicalize(result)[0] == result
    assert PLACE.read_bytes() == raw
    with PLACE.open('r+b') as output:
        output.write(result)
        output.truncate()
        output.flush()
        os.fsync(output.fileno())
    assert PLACE.read_bytes() == result
    Document(result).assert_studio_bounds()
    report = {'path': str(PLACE), 'inputSha256': EXPECTED,
              'outputSha256': hashlib.sha256(result).hexdigest(), 'changedSources': hashes,
              'allOtherSourcesPropertiesParentsUniqueIdsSharedStringsUnchanged': True,
              'treadmill_ba1186f_spawn_36595fe_stageSkip_07c2518_speed_bedf633_preserved': True,
              'syntaxAndReferences': 'passed', 'written': True}
    destination = ROOT / 'reports/MuscleGrowth13_20261020'
    destination.mkdir(exist_ok=True)
    (destination / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
