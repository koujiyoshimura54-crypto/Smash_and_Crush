"""Guarded Source-only patch of the current place. No alternate place or map changes."""
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from rbxl_rows import Editor, string, s
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = 'b790ac43e6093e503540c5ef25ee89b4feb946dbd71916540bc5ba18596e0b5a'
FILES = {
    'ServerScriptService.World.EnemyManager': 'src/ServerScriptService/World/EnemyManager.luau',
    'ServerScriptService.World.BossAttackService': 'src/ServerScriptService/World/BossAttackService.luau',
    'ServerScriptService.World.BossChaseService': 'src/ServerScriptService/World/BossChaseService.luau',
    'StarterPlayer.StarterPlayerScripts.Combat.CombatClient': 'src/StarterPlayer/StarterPlayerScripts/Combat/CombatClient.client.luau',
    'StarterPlayer.StarterPlayerScripts.Combat.Stage03AttackVisual': 'src/StarterPlayer/StarterPlayerScripts/Combat/Stage03AttackVisual.luau',
}
UNREGISTER = 'function M.Unregister(enemy)\n records[enemy]=nil\nend\n'


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Target changed; inspect before editing'
    editor = Editor(raw)
    editor.path = functools.lru_cache(None)(editor.path)
    paths = {editor.path(ref): ref for ref in editor.parents}
    hashes = {}
    for path, file in FILES.items():
        old = string(editor.get(paths[path], 'Source'), 0)[0].decode()
        source = (ROOT / file).read_text(encoding='utf8')
        compile_file = ROOT / file
        if path.endswith('BossChaseService'):
            # The actual place has16/4; HEAD has28/12 and an unrelated dirty
            # mirror has20/12. Add only deregistration to each existing version.
            assert 'local CHASE_SPEED = 16 ' in old and 'local TURN_RESPONSE = 4 ' in old
            assert old.endswith('return M\n') and UNREGISTER in source
            source = old[:-len('return M\n')] + UNREGISTER + 'return M\n'
            compile_file = Path(tempfile.gettempdir()) / 'mtf-boss-isolation' / 'BossChaseService.compile.luau'
            compile_file.parent.mkdir(exist_ok=True)
            compile_file.write_text(source, encoding='utf8')
        subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau-compile.exe'), str(compile_file)],
                       check=True, stdout=subprocess.DEVNULL)
        assert 'BossIsolationAudit' not in source and 'BossIsolationMemoryOnly' not in source
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
              'actualChaseSpeed16TurnResponse4Preserved': True,
              'syntaxReDecodeReferences': 'passed', 'alternatePlaceCreated': False}
    dest = ROOT / 'reports/BossIsolation_20261020'
    dest.mkdir(exist_ok=True)
    (dest / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
