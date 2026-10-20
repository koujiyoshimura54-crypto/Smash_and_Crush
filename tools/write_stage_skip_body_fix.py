"""Guarded Source-only update of the existing CurrentCloud place; no alternate rbxl."""
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
EXPECTED = '8e48706f979fc890e068e51de88d8608fa7cc7bad7a47d6e19b79e1847a52a83'
FILES = {
    'ServerScriptService.Services.StageSkipService': 'src/ServerScriptService/Services/StageSkipService.luau',
    'ServerScriptService.Services.LobbySpawnService': 'src/ServerScriptService/Services/LobbySpawnService.luau',
}


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Target changed; inspect before editing'
    editor = Editor(raw)
    editor.path = functools.lru_cache(None)(editor.path)
    paths = {editor.path(ref): ref for ref in editor.parents}
    hashes = {}
    for path, file in FILES.items():
        source = (ROOT / file).read_text(encoding='utf8')
        old = string(editor.get(paths[path], 'Source'), 0)[0].decode()
        subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'), str(ROOT / file)],
                       check=True, stdout=subprocess.DEVNULL)
        assert 'StageSkipAudit' not in source
        if path.endswith('LobbySpawnService'):
            marker = '-- StageSkip extensions.'
            assert source[:source.index(marker)] == old[:old.index(marker)]
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
              'original36595feLobbyFunctionsUnchanged': True,
              'syntaxReDecodeReferences': 'passed', 'alternatePlaceCreated': False}
    dest = ROOT / 'reports/StageSkipBody_20261020'
    dest.mkdir(exist_ok=True)
    (dest / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
