"""Patch only the seven tested World2 parity Sources in the current saved place."""
import functools
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from rbxl_rows import Editor, s, string
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '189a0007a13fcd649cdc4bc3fc3b8e53175d94d24f1281e82cbc497d37bee3aa'
FILES = {
 'ReplicatedStorage.Config.World2BossVisualConfig': 'src/ReplicatedStorage/Config/World2BossVisualConfig.luau',
 'ServerScriptService.World.BossAttackService': 'src/ServerScriptService/World/BossAttackService.luau',
 'ServerScriptService.World.BossChaseService': 'src/ServerScriptService/World/BossChaseService.luau',
 'ServerScriptService.World.BossCombatService': 'src/ServerScriptService/World/BossCombatService.luau',
 'ServerScriptService.World.BossVisualPlacement': 'src/ServerScriptService/World/BossVisualPlacement.luau',
 'ServerScriptService.World.EnemyManager': 'src/ServerScriptService/World/EnemyManager.luau',
 'StarterPlayer.StarterPlayerScripts.Combat.CombatClient': 'src/StarterPlayer/StarterPlayerScripts/Combat/CombatClient.client.luau',
}

def main():
 raw = PLACE.read_bytes()
 assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Unexpected current-place edit; inspect before writing'
 e = Editor(raw)
 e.path = functools.lru_cache(None)(e.path)
 paths = {e.path(ref): ref for ref in e.parents}
 sources, changes, refs = {}, {}, set()
 compiler = Path.home() / 'AppData/Local/Temp/luau-compile.exe'
 with tempfile.TemporaryDirectory(prefix='world2-parity-syntax-') as tmp:
  for path, relative in FILES.items():
   ref = paths[path]
   old = string(e.get(ref, 'Source'), 0)[0]
   new = (ROOT / relative).read_text(encoding='utf8')
   if path.endswith('.BossChaseService'):
    # The actual place is authoritative. Preserve its manual 16/4 settings;
    # do not import either repository HEAD's 28/12 or the owner's dirty 20/12.
    for name in ('CHASE_SPEED', 'TURN_RESPONSE'):
     pattern = rf'local {name} = [^\r\n]+'
     actual = re.search(pattern, old.decode()).group()
     new, count = re.subn(pattern, lambda _: actual, new)
     assert count == 1
   assert 'World2Parity' not in new
   source_file = Path(tmp) / (path + '.luau')
   source_file.write_text(new, encoding='utf8')
   subprocess.run([str(compiler), str(source_file)], check=True, stdout=subprocess.DEVNULL)
   sources[path] = new.encode()
   e.set(ref, 'Source', s(sources[path]))
   refs.add(ref)
   changes[path] = {'before': hashlib.sha256(old).hexdigest(), 'after': hashlib.sha256(sources[path]).hexdigest()}
 result, _ = e.build()
 before, after = Editor(raw), Editor(result)
 assert before.parents == after.parents and before.classes == after.classes
 for key, column in before.columns.items():
  cid, name = key
  if key not in e.changed:
   assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[key][0]][1]
  else:
   assert name == 'Source'
   for ref, old in before.col(cid, name)[3].items():
    assert after.get(ref, name) == (e.get(ref, name) if ref in refs else old)
 assert canonicalize(result)[0] == result
 Document(result).assert_studio_bounds()
 assert PLACE.read_bytes() == raw, 'File changed during validation'
 with PLACE.open('r+b') as stream:
  stream.write(result)
  stream.truncate()
  stream.flush()
  os.fsync(stream.fileno())
 saved = PLACE.read_bytes()
 assert saved == result
 reread = Editor(saved)
 for path, source in sources.items():
  assert string(reread.get(paths[path], 'Source'), 0)[0] == source
 report = {
  'inputSha256': EXPECTED, 'outputSha256': hashlib.sha256(saved).hexdigest(),
  'bytes': len(saved), 'sources': changes,
  'syntaxCompiled': True, 'writtenAndReread': True,
  'allOtherSourcesPropertiesParentsUniqueIdsUnchanged': True,
  'existingBossTemplatesAndNumericBalanceUnchanged': True,
  'existing40TrophyButtonsAndPurchaseSourcesUnchanged': True,
  'actualChaseSpeed': 16, 'actualTurnResponse': 4,
  'testFixturesWritten': False, 'studioSaveOrPublishUsed': False,
 }
 out = ROOT / 'reports/World2BossParity_20261021'
 out.mkdir(exist_ok=True)
 (out / 'Writeback.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
 print(json.dumps(report, indent=2))

if __name__ == '__main__':
 main()
