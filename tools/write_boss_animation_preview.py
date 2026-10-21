"""Add the two reviewed Studio preview scripts without changing existing rows."""
import argparse
import functools
import hashlib
import json
import os
import subprocess
import uuid
from pathlib import Path
from rbxl_rows import Editor, s, string

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '5d0d6407bc505f79436d697682f4f8f02c47d698cba44b853c6d52f923823433'
REPORT = ROOT / 'reports/World2BossAnimationPreview_20261022/Writeback.json'
FILES = {
    'ServerScriptService.StudioBossAnimationPreview':
        ('src/ServerScriptService/StudioBossAnimationPreview.server.luau', 'ServerScriptService.InventoryCapacityController'),
    'StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview':
        ('src/StarterPlayer/StarterPlayerScripts/StudioBossAnimationPreview.client.luau', 'StarterPlayer.StarterPlayerScripts.StudioTestCommandClient'),
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def apply(raw):
    assert sha(raw) == EXPECTED, 'Current place changed; inspect before writing'
    before, edit = Editor(raw), Editor(raw)
    edit.path = functools.lru_cache(None)(edit.path)
    paths = {edit.path(ref): ref for ref in edit.parents}
    sources, new_refs = {}, {}
    for path, (relative, donor) in FILES.items():
        assert path not in paths, 'Do not overwrite an existing user object'
        text = (ROOT / relative).read_text(encoding='utf-8')
        assert 'IsStudio()' in text and 'PreviewInputProbe' not in text
        assert 'DataStoreService' not in text and 'PlayerDataService' not in text
        subprocess.run([str(Path(os.environ['TEMP']) / 'luau-compile.exe'), str(ROOT / relative)],
                       check=True, stdout=subprocess.DEVNULL)
        parent, name = path.rsplit('.', 1)
        ref, _ = edit.clone(paths[donor], paths[parent], recursive=False)
        edit.set(ref, 'Name', s(name))
        edit.set(ref, 'Source', s(text))
        edit.set(ref, 'Disabled', b'\0')
        if (edit.class_of[ref], 'ScriptGuid') in edit.columns:
            edit.set(ref, 'ScriptGuid', s('{' + str(uuid.uuid4()).upper() + '}'))
        new_refs[path], sources[path] = ref, text.encode()
    result, _ = edit.build()
    assert not edit.final_mapping, 'Unexpected original referent remap'
    after = Editor(result)
    assert len(after.parents) == len(before.parents) + 2
    assert all(after.parents[ref] == parent for ref, parent in before.parents.items())
    verified = 0
    for (cid, prop), column in before.columns.items():
        if (cid, prop) not in edit.changed:
            assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[cid, prop][0]][1]
            verified += len(before.classes[cid])
        else:
            for ref, value in before.col(cid, prop)[3].items():
                assert after.get(ref, prop) == value, (ref, prop)
                verified += 1
    for path, ref in new_refs.items():
        assert string(after.get(ref, 'Source'), 0)[0] == sources[path]
        assert after.get(ref, 'Disabled') == b'\0'
    return result, {'inputSha256': EXPECTED, 'outputSha256': sha(result),
                    'newSources': {p: sha(v) for p, v in sources.items()},
                    'newInstances': list(FILES), 'verifiedExistingProperties': verified,
                    'allExistingSourcesModelsPropertiesParentsPreserved': True,
                    'runtimeModelsOrTestFixturesWritten': False, 'studioSaveOrPublishUsed': False,
                    'writtenAndReread': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = PLACE.read_bytes()
    result, report = apply(raw)
    if args.write:
        assert not Path(str(PLACE) + '.lock').exists(), 'Release only the owned Studio lock first'
        assert PLACE.read_bytes() == raw, 'File changed during validation'
        with PLACE.open('r+b') as stream:
            stream.write(result); stream.truncate(); stream.flush(); os.fsync(stream.fileno())
        saved = PLACE.read_bytes()
        assert saved == result
        reread = Editor(saved)
        reread.path = functools.lru_cache(None)(reread.path)
        paths = {reread.path(ref): ref for ref in reread.parents}
        for path, (relative, _) in FILES.items():
            assert string(reread.get(paths[path], 'Source'), 0)[0] == (ROOT / relative).read_text(encoding='utf-8').encode()
        report['writtenAndReread'] = True
        REPORT.parent.mkdir(parents=True, exist_ok=True)
        REPORT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
