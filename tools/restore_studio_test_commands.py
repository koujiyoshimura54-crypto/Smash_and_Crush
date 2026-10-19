"""Restore only the two missing /test entrypoints to the same CurrentCloud.

Dry-run by default. Never replaces original Source or touches gameplay geometry.
The guarded input must be re-audited if another process changes the file.
"""
import argparse
import hashlib
import json
from pathlib import Path
import uuid

from rbxl_rows import Editor, s, string
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
INPUT_SHA = 'e25dc9e34a46a4021bded4ceec8405ba042c77a5c47a2791534860e52e94e650'
SCRIPTS = [
    ('ServerScriptService.Systems.Debug.StudioStartController', 'Script',
     'ServerScriptService.Systems.Debug.StudioDebugController',
     'src/ServerScriptService/Systems/Debug/StudioStartController.server.luau'),
    ('StarterPlayer.StarterPlayerScripts.StudioTestCommandClient', 'LocalScript',
     'StarterPlayer.StarterPlayerScripts.Debug.StudioDebugClient',
     'src/StarterPlayer/StarterPlayerScripts/StudioTestCommandClient.client.luau'),
]


def build(raw):
    assert hashlib.sha256(raw).hexdigest() == INPUT_SHA, 'Input changed: re-audit before writing'
    original, editor = Editor(raw), Editor(raw)
    paths = {editor.path(r): r for r in editor.parents}
    config = string(editor.get(paths['ServerScriptService.Config.StudioDebugConfig'], 'Source'), 0)[0]
    assert b'Enabled=true' in config and b'AutoApplyOnPlay=false' in config and b'ChatCommandsEnabled=true' in config
    restored = []
    for target, kind, donor_path, mirror in SCRIPTS:
        assert target not in paths, ('Not missing', target)
        donor = paths[donor_path]
        assert editor.doc.classes[editor.class_of[donor]][0] == kind
        parent, name = target.rsplit('.', 1)
        ref, mapping = editor.clone(donor, paths[parent], recursive=False)
        assert len(mapping) == 1
        editor.set(ref, 'Name', s(name))
        editor.set(ref, 'Source', s((ROOT / mirror).read_text(encoding='utf-8')))
        editor.set(ref, 'Disabled', b'\0')
        editor.set(ref, 'LinkedSource', s(''))
        editor.set(ref, 'ScriptGuid', s('{' + str(uuid.uuid4()).upper() + '}'))
        assert editor.get(ref, 'RunContext') == bytes(4), 'Expected legacy Script/LocalScript context'
        assert string(editor.get(ref, 'AttributesSerialize'), 0)[0] == b''
        assert editor.strings()[int.from_bytes(editor.get(ref, 'Tags'), 'big')][1] == b''
        restored.append(dict(path=target, className=kind, disabled=False, runContext='Legacy', sourceMirror=mirror))

    result, repair = editor.build()
    decoded = Editor(result)
    # Referents are already dense; every old row, Source and parent must be exact.
    assert not editor.final_mapping
    unchanged_properties = 0
    original_sources = 0
    changed_classes = {original.class_of[paths[entry[2]]] for entry in SCRIPTS}
    for (cid, prop) in original.columns:
        if cid not in changed_classes:
            # Untouched classes remain byte-identical, including opaque property
            # kinds that do not need a decoder for this two-script restoration.
            old_col = original.columns[cid, prop]
            new_col = decoded.columns[cid, prop]
            assert original.doc.chunks[old_col[0]][1] == decoded.doc.chunks[new_col[0]][1], (cid, prop)
            unchanged_properties += len(original.classes[cid])
            if prop == 'Source':
                original_sources += len(original.classes[cid])
            continue
        for ref in original.classes[cid]:
            assert original.get(ref, prop) == decoded.get(ref, prop), (original.path(ref), prop)
            unchanged_properties += 1
            if prop == 'Source':
                original_sources += 1
    assert all(decoded.parents[ref] == parent for ref, parent in original.parents.items())
    assert len(decoded.parents) == len(original.parents) + 2
    after_paths = {decoded.path(r): r for r in decoded.parents}
    for target, kind, _, mirror in SCRIPTS:
        ref = after_paths[target]
        assert decoded.doc.classes[decoded.class_of[ref]][0] == kind
        assert string(decoded.get(ref, 'Source'), 0)[0].decode() == (ROOT / mirror).read_text(encoding='utf-8')
        assert sum(decoded.path(r) == target for r in decoded.parents) == 1
    for path in ['TextChatService.StudioTestCommand', 'ReplicatedStorage.Remotes.StudioTestCommandResult']:
        assert path not in after_paths, 'These are created only by Studio runtime'
    strings = decoded.strings()
    shared_indexes = 0
    for (cid, prop), col in decoded.columns.items():
        if col[1] == 28:
            for ref in decoded.classes[cid]:
                assert int.from_bytes(decoded.get(ref, prop), 'big') < len(strings)
                shared_indexes += 1
    second, second_repair = canonicalize(result)
    assert second == result
    Document(result).assert_studio_bounds()
    report = dict(
        inputPath=str(PLACE), inputSha256=INPUT_SHA, outputSha256=hashlib.sha256(result).hexdigest(),
        cause='Both /test server Script and result LocalScript are absent from actual input; Start flags and override/progression/world dependencies exist.',
        restored=restored, originalInstanceCount=len(original.parents), finalInstanceCount=len(decoded.parents),
        addedInstances=2, originalInstancesRemoved=0, originalParentsUnchanged=True,
        originalPropertiesUnchanged=unchanged_properties, originalSourcesUnchanged=original_sources,
        originalWorkspaceAndGameplayUnchanged=True, playerDataServiceSourceChanged=False,
        startConfigSourceUnchanged=True, autoApplyOnPlay=False,
        runtimeGeneratedOnly=['TextChatService.StudioTestCommand', 'ReplicatedStorage.Remotes.StudioTestCommandResult'],
        binaryValidation=repair, canonicalizationIdempotent=True,
        sharedStrings=dict(count=len(strings), validatedIndexes=shared_indexes),
        localPlay=False, resetdataInvoked=False, realDataStoreOperations=False, studioSavePublish=False,
        realChatExecutionVerified=False,
    )
    return result, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = PLACE.read_bytes()
    result, report = build(raw)
    if args.write:
        assert PLACE.read_bytes() == raw, 'Input changed during validation'
        assert not Path(str(PLACE) + '.lock').exists(), 'Close only an owned file inspection first'
        PLACE.write_bytes(result)
        actual = PLACE.read_bytes()
        assert actual == result
        Document(actual).assert_studio_bounds()
        report['writtenToSameInputFile'] = True
        (ROOT / 'reports/StudioTestCommands_20261019.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({key: report[key] for key in ['inputPath', 'outputSha256', 'addedInstances',
                     'originalPropertiesUnchanged', 'originalSourcesUnchanged', 'sharedStrings']}))


if __name__ == '__main__':
    main()
