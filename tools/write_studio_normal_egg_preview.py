"""Apply only the reviewed Studio normal-Egg preview Sources to the current place."""
import argparse
import functools
import hashlib
import json
import os
import subprocess
from pathlib import Path

from rbxl_rows import Editor, s, string

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '4dda6dc2181bba4ef4e9b9d0a5411a80262712e9c1fa63717312ab64493e16b9'
PATHS = [
    'ServerScriptService.Services.PlayerDataService',
    'StarterPlayer.StarterPlayerScripts.Services.PetClient',
    'StarterPlayer.StarterPlayerScripts.Services.HatchClient',
]
REPORT = ROOT / 'reports/StudioNormalEggPreview_20261022/Writeback.json'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def apply(raw):
    assert sha(raw) == EXPECTED, 'Current file changed; inspect before writing'
    before, edit = Editor(raw), Editor(raw)
    edit.path = functools.lru_cache(None)(edit.path)
    paths = {edit.path(ref): ref for ref in edit.parents}
    allowed = set()
    hashes = {}
    for path in PATHS:
        relative = 'src/' + path.replace('.', '/') + '.luau'
        ref = paths[path]
        old = string(edit.get(ref, 'Source'), 0)[0]
        baseline = subprocess.check_output(['git', 'show', 'dadee41:' + relative], cwd=ROOT)
        assert old.replace(b'\r\n', b'\n') == baseline.replace(b'\r\n', b'\n'), path
        new = (ROOT / relative).read_text(encoding='utf-8').encode()
        assert all(marker not in new for marker in (b'PurchasesTestEnvironment', b'NormalEggAudit', b'NormalEggDetail', b'NormalEggReload'))
        subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'),
                        str(ROOT / relative)], check=True, stdout=subprocess.DEVNULL)
        edit.set(ref, 'Source', s(new))
        allowed.add((ref, 'Source'))
        hashes[path] = {'before': sha(old), 'after': sha(new)}
    result, _ = edit.build()
    after = Editor(result)
    assert before.parents == after.parents
    assert before.classes == after.classes
    verified = 0
    for (cid, prop), column in before.columns.items():
        if (cid, prop) not in edit.changed:
            assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[cid, prop][0]][1]
            verified += len(before.classes[cid])
            continue
        for ref, original in before.col(cid, prop)[3].items():
            expected = edit.get(ref, prop) if (ref, prop) in allowed else original
            assert after.get(ref, prop) == expected, (ref, prop)
            verified += 1
    for path in PATHS:
        expected = (ROOT / ('src/' + path.replace('.', '/') + '.luau')).read_text(encoding='utf-8')
        assert string(after.get(paths[path], 'Source'), 0)[0].decode() == expected
    return result, {
        'inputSha256': EXPECTED, 'outputSha256': sha(result), 'bytes': len(result),
        'changedSources': hashes, 'verifiedExistingProperties': verified,
        'allOtherSourcesPropertiesParentsAndInstancesPreserved': True,
        'testFixturesWritten': False, 'studioSaveOrPublishUsed': False,
        'writtenAndReread': False,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = PLACE.read_bytes()
    result, report = apply(raw)
    if args.write:
        assert not Path(str(PLACE) + '.lock').exists(), 'Release the owned Studio lock first'
        assert PLACE.read_bytes() == raw, 'File changed during validation'
        with PLACE.open('r+b') as stream:
            stream.write(result)
            stream.truncate()
            stream.flush()
            os.fsync(stream.fileno())
        saved = PLACE.read_bytes()
        assert saved == result
        reread = Editor(saved)
        reread.path = functools.lru_cache(None)(reread.path)
        saved_paths = {reread.path(ref): ref for ref in reread.parents}
        for path in PATHS:
            expected = (ROOT / ('src/' + path.replace('.', '/') + '.luau')).read_text(encoding='utf-8')
            assert string(reread.get(saved_paths[path], 'Source'), 0)[0].decode() == expected
        report['savedFileDecodedAndAllTargetSourcesMatched'] = True
        report['writtenAndReread'] = True
        REPORT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
