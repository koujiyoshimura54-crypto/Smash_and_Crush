"""Quarantine the newly imported Workspace model and extend only Studio Preview."""
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
BASE = '7e948d203176ccd6bd827a7182982388bd471c0489daeac4b7497af0508e7fc3'
REPORT = ROOT / 'reports/NewSCP682Audit_20261022'
FILES = {
    'ServerScriptService.StudioBossAnimationPreview': 'src/ServerScriptService/StudioBossAnimationPreview.server.luau',
    'StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview': 'src/StarterPlayer/StarterPlayerScripts/StudioBossAnimationPreview.client.luau',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == BASE, 'Current file changed; inspect it before writing'
    before, edit = Editor(raw), Editor(raw)
    edit.path = functools.lru_cache(None)(edit.path)
    paths = {edit.path(ref): ref for ref in edit.parents}
    allowed = set()
    archive = json.loads((REPORT / 'OriginalScripts.json').read_text(encoding='utf-8'))
    model = paths['Workspace.SCP-682']
    script_refs = {ref for ref in edit.subtree(model) if edit.doc.classes[edit.class_of[ref]][0] in ('Script', 'LocalScript', 'ModuleScript')}
    assert script_refs == {row['Ref'] for row in archive} and len(script_refs) == 14
    for row in archive:
        ref = paths[row['Path']]
        source = string(edit.get(ref, 'Source'), 0)[0]
        assert ref == row['Ref'] and source.decode() == row['Source']
        assert hashlib.sha256(source).hexdigest() == row['Sha256']
        if row['Class'] != 'ModuleScript':
            assert edit.get(ref, 'Disabled') == bytes([row['Disabled']])
            edit.set(ref, 'Disabled', b'\1')
            allowed.add((ref, 'Disabled'))
    assert len(allowed) == 8
    for path, file in FILES.items():
        ref = paths[path]
        original = subprocess.check_output(['git', 'show', '22c1618:' + file], cwd=ROOT).decode().replace('\r\n', '\n')
        assert string(edit.get(ref, 'Source'), 0)[0].decode().replace('\r\n', '\n') == original
        subprocess.run([str(Path(os.environ['TEMP']) / 'luau-compile.exe'), str(ROOT / file)], check=True, stdout=subprocess.DEVNULL)
        edit.set(ref, 'Source', s((ROOT / file).read_text(encoding='utf-8')))
        allowed.add((ref, 'Source'))
    result, repair = edit.build()
    assert not edit.final_mapping
    after = Editor(result)
    assert after.parents == before.parents
    checked = 0
    for (cid, prop), column in before.columns.items():
        if (cid, prop) not in edit.changed:
            assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[cid, prop][0]][1]
            checked += len(before.classes[cid])
        else:
            for ref, value in before.col(cid, prop)[3].items():
                expected = edit.get(ref, prop) if (ref, prop) in allowed else value
                assert after.get(ref, prop) == expected, (ref, prop)
                checked += 1
    report = {
        'InputSha256': BASE, 'OutputSha256': hashlib.sha256(result).hexdigest(),
        'ChangedProperties': [{'Path': edit.path(ref), 'Property': prop} for ref, prop in sorted(allowed)],
        'SourceFiles': FILES, 'PreservedOriginalImportedSources': 14, 'DisabledImportedScripts': 8,
        'ModuleEntrypointsBlocked': 'All imported callers disabled; no external caller in current Sources; preview strips every imported script/module',
        'VerifiedPropertyValues': checked, 'AllOtherPropertiesAndParentsPreserved': True,
        'AddedOrRemovedInstances': 0, 'Integrity': after.doc.summary(), 'Repair': repair,
        'WrittenAndReread': False, 'StudioSavePublish': False,
    }
    if args.write:
        assert not Path(str(PLACE) + '.lock').exists(), 'Studio file lock remains'
        assert PLACE.read_bytes() == raw, 'File changed during validation'
        with PLACE.open('r+b') as handle:
            handle.write(result)
            handle.truncate()
            handle.flush()
            os.fsync(handle.fileno())
        saved = PLACE.read_bytes()
        assert saved == result
        reread = Editor(saved)
        for ref, prop in allowed:
            assert reread.get(ref, prop) == edit.get(ref, prop)
        report['WrittenAndReread'] = True
        (REPORT / 'Writeback.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
