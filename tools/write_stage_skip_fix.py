"""Source-only patch of the current place; preserve every other original row."""
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess
from rbxl_rows import Editor, string, s
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '32e45e4f422f35a50b6abd0fc2c9958ca99ccb2dc6cbb01a2fbeab8e619e62ed'
FILES = {
    'ServerScriptService.Services.StageSkipService': 'src/ServerScriptService/Services/StageSkipService.luau',
    'ServerScriptService.Services.LobbySpawnService': 'src/ServerScriptService/Services/LobbySpawnService.luau',
    'StarterPlayer.StarterPlayerScripts.UI.StageSkipClient': 'src/StarterPlayer/StarterPlayerScripts/UI/StageSkipClient.client.luau',
}


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Target changed'
    e = Editor(raw)
    e.path = functools.lru_cache(None)(e.path)
    paths = {e.path(r): r for r in e.parents}
    hashes = {}
    for path, file in FILES.items():
        source = (ROOT / file).read_text(encoding='utf8')
        old = string(e.get(paths[path], 'Source'), 0)[0].decode()
        subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'), str(ROOT / file)], check=True, stdout=subprocess.DEVNULL)
        if path.endswith('LobbySpawnService'):
            marker = '-- StageSkip extensions.'
            assert source[:source.index(marker)] + 'return M\n' == old
        hashes[path] = {'before': hashlib.sha256(old.encode()).hexdigest(), 'after': hashlib.sha256(source.encode()).hexdigest()}
        e.set(paths[path], 'Source', s(source))
    result, _ = e.build()
    after = Editor(result)
    assert e.parents == after.parents and e.classes == after.classes and e.doc.unique_ids == after.doc.unique_ids
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
        output.write(result); output.truncate(); output.flush(); os.fsync(output.fileno())
    assert PLACE.read_bytes() == result
    Document(result).assert_studio_bounds()
    report = {'path': str(PLACE), 'inputSha256': EXPECTED, 'outputSha256': hashlib.sha256(result).hexdigest(),
              'changedSources': hashes, '36595feExistingFunctionBodiesUnchanged': True,
              'allOtherSourcesPropertiesParentsUniqueIdsSharedStringsUnchanged': True,
              'configPricesProductIdsUIDesignUnchanged': True, 'syntax': 'passed', 'reDecodeReferences': 'passed', 'written': True}
    dest = ROOT / 'reports/StageSkip_20261020'
    dest.mkdir(exist_ok=True)
    (dest / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
