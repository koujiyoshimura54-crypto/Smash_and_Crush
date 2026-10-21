"""Apply the reviewed Battle source delta to the current place, preserving all other rows."""
import argparse
import functools
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path
from rbxl_rows import Editor, s, string

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '17ce9238d4db65dfb34d82e375768bada63b79b19651036c85f0a1c1650f108d'
PATHS = {
 'ServerScriptService.World.EnemyManager': 'src/ServerScriptService/World/EnemyManager.luau',
 'ServerScriptService.World.BossChaseService': 'src/ServerScriptService/World/BossChaseService.luau',
 'StarterPlayer.StarterPlayerScripts.Combat.CombatClient': 'src/StarterPlayer/StarterPlayerScripts/Combat/CombatClient.client.luau',
 'ReplicatedStorage.Config.World2BossMovementConfig': 'src/ReplicatedStorage/Config/World2BossMovementConfig.luau',
}
NEW = 'ReplicatedStorage.Config.World2BossMovementConfig'
REPORT = ROOT / 'reports/World2Battle_20261021/Writeback.json'
def sha(raw): return hashlib.sha256(raw).hexdigest()
def source(path, relative):
 text = (ROOT / relative).read_text(encoding='utf-8')
 if path.endswith('.BossChaseService'):
  # Preserve the authoritative saved World1 16/4, and the owner's unstaged 20/12 mirror.
  text = text.replace('local CHASE_SPEED = 20', 'local CHASE_SPEED = 16').replace('local TURN_RESPONSE = 12', 'local TURN_RESPONSE = 4')
 assert 'PurchasesTestEnvironment' not in text and 'BattleAudit' not in text
 return text.encode()
def apply(raw):
 assert sha(raw) == EXPECTED, 'Current place changed; inspect before writing'
 before, edit = Editor(raw), Editor(raw)
 edit.path = functools.lru_cache(None)(edit.path)
 paths = {edit.path(ref): ref for ref in edit.parents}
 assert NEW not in paths
 ref, _ = edit.clone(paths['ReplicatedStorage.Config.World2Config'], paths['ReplicatedStorage.Config'], recursive=False)
 edit.set(ref, 'Name', s('World2BossMovementConfig'));paths[NEW] = ref
 allowed, hashes, sources = set(), {}, {}
 with tempfile.TemporaryDirectory(prefix='world2-battle-syntax-') as temporary:
  for path, relative in PATHS.items():
   ref = paths[path];new = source(path, relative);sources[path] = new
   old = string(edit.get(ref, 'Source'), 0)[0] if path != NEW else None
   if old is not None:
    baseline = subprocess.check_output(['git', 'show', '5fddbec:' + relative], cwd=ROOT)
    if path.endswith('.BossChaseService'):
     baseline = baseline.replace(b'local CHASE_SPEED = 28', b'local CHASE_SPEED = 16').replace(b'local TURN_RESPONSE = 12', b'local TURN_RESPONSE = 4')
    assert old.replace(b'\r\n', b'\n') == baseline.replace(b'\r\n', b'\n'), path
   check = Path(temporary) / (path + '.luau');check.write_bytes(new)
   subprocess.run([str(Path(os.environ['TEMP']) / 'luau-compile.exe'), str(check)], check=True, stdout=subprocess.DEVNULL)
   edit.set(ref, 'Source', s(new));allowed.add((ref, 'Source'))
   hashes[path] = {'before': sha(old) if old is not None else None, 'after': sha(new)}
 result, _ = edit.build();after = Editor(result)
 assert all(after.parents[ref] == parent for ref, parent in before.parents.items())
 assert len(after.parents) == len(before.parents) + 1
 verified = 0
 for (cid, name), column in before.columns.items():
  if (cid, name) not in edit.changed:
   assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[cid, name][0]][1]
   verified += len(before.classes[cid]);continue
  for ref, original in before.col(cid, name)[3].items():
   expected = edit.get(ref, name) if (ref, name) in allowed else original
   assert after.get(ref, name) == expected, (ref, name)
   verified += 1
 for path, new in sources.items(): assert string(after.get(paths[path], 'Source'), 0)[0] == new
 return result, {'inputSha256': EXPECTED, 'outputSha256': sha(result), 'bytes': len(result), 'sources': hashes,
  'verifiedExistingProperties': verified, 'newInstances': [NEW], 'otherSourcesModelsPropertiesParentsPreserved': True,
  'world1ActualMovementPreserved': {'Speed': 16, 'TurnResponse': 4}, 'testFixturesWritten': False,
  'studioSaveOrPublishUsed': False, 'writtenAndReread': False}
def main():
 parser = argparse.ArgumentParser(description=__doc__);parser.add_argument('--write', action='store_true');args = parser.parse_args()
 raw = PLACE.read_bytes();result, report = apply(raw)
 if args.write:
  assert not Path(str(PLACE) + '.lock').exists(), 'Release the owned Studio lock first'
  assert PLACE.read_bytes() == raw, 'Place changed during validation'
  with PLACE.open('r+b') as stream:
   stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
  assert PLACE.read_bytes() == result
  reread = Editor(PLACE.read_bytes());reread.path = functools.lru_cache(None)(reread.path);paths = {reread.path(r):r for r in reread.parents}
  for path, relative in PATHS.items(): assert string(reread.get(paths[path], 'Source'), 0)[0] == source(path, relative)
  report['writtenAndReread'] = True;REPORT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
 print(json.dumps(report, indent=2))
if __name__ == '__main__': main()
