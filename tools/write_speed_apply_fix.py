"""Patch only the current place's RunReturnService Source, without Studio Save."""
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
EXPECTED = '262460fa3466aa0fa88203dd257e66db2778274e9279fdda3625f6703c3a5589'
SCRIPT = 'ServerScriptService.Services.RunReturnService'
SOURCE = ROOT / 'src/ServerScriptService/Services/RunReturnService.luau'


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Target changed'
    e = Editor(raw)
    e.path = functools.lru_cache(None)(e.path)
    paths = {e.path(r): r for r in e.parents}
    ref = paths[SCRIPT]
    old = string(e.get(ref, 'Source'), 0)[0].decode()
    source = SOURCE.read_text(encoding='utf8')
    assert 'local speed = Speed.GetState(player).WalkSpeed' in old
    assert 'hum.WalkSpeed = speed' in old
    assert 'hum.WalkSpeed = speed' not in source and '\tSpeed.Apply(player)' in source
    subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'), str(SOURCE)],
                   check=True, stdout=subprocess.DEVNULL)
    e.set(ref, 'Source', s(source))
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
    report = {
        'path': str(PLACE), 'inputSha256': EXPECTED,
        'outputSha256': hashlib.sha256(result).hexdigest(),
        'changedSources': {SCRIPT: {
            'before': hashlib.sha256(old.encode()).hexdigest(),
            'after': hashlib.sha256(source.encode()).hexdigest()}},
        'allOtherSourcesPropertiesParentsUniqueIdsSharedStringsUnchanged': True,
        'treadmill_ba1186f_spawn_36595fe_stageSkip_07c2518_preserved': True,
        'syntaxAndReferences': 'passed', 'written': True,
    }
    dest = ROOT / 'reports/SpeedApplication_20261020'
    dest.mkdir(exist_ok=True)
    (dest / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
