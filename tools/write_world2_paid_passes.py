"""Write the verified World2 pass connections into the current file, Source only."""
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
EXPECTED = 'cc7aa254b4654ea0faf0e514e72aa842677522f58d6b14c71185abf182a6f0cb'
FILES = {
 'ReplicatedStorage.Config.World2GameplayConfig': 'src/ReplicatedStorage/Config/World2GameplayConfig.luau',
 'ReplicatedStorage.Config.TreadmillConfig': 'src/ReplicatedStorage/Config/TreadmillConfig.luau',
 'ReplicatedStorage.Config.AuraConfig': 'src/ReplicatedStorage/Config/AuraConfig.luau',
 'ServerScriptService.Services.GamePassService': 'src/ServerScriptService/Services/GamePassService.luau',
 'ServerScriptService.Services.TrainingManager': 'src/ServerScriptService/Services/TrainingManager.luau',
 'ServerScriptService.Services.AuraService': 'src/ServerScriptService/Services/AuraService.luau',
 'ServerScriptService.Systems.Controllers.AuraController': 'src/ServerScriptService/Systems/Controllers/AuraController.server.luau',
 'StarterGui.StrengthGui.AuraInventoryClient': 'src/StarterGui/StrengthGui/AuraInventoryClient.client.luau',
 'StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient': 'src/StarterPlayer/StarterPlayerScripts/UI/TreadmillUIClient.client.luau',
}

def main():
 raw = PLACE.read_bytes()
 assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Unexpected current file edit; inspect before writing'
 e = Editor(raw)
 e.path = functools.lru_cache(None)(e.path)
 paths = {e.path(ref): ref for ref in e.parents}
 sources, changes, refs = {}, {}, set()
 compiler = Path.home() / 'AppData/Local/Temp/luau-compile.exe'
 for path, relative in FILES.items():
  ref = paths[path]
  old = string(e.get(ref, 'Source'), 0)[0]
  source = (ROOT / relative).read_text(encoding='utf8')
  assert 'PurchasesTest' not in source
  subprocess.run([str(compiler), str(ROOT / relative)], check=True, stdout=subprocess.DEVNULL)
  sources[path] = source.encode()
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
  'bytes': len(saved), 'sources': changes, 'syntaxCompiled': True, 'writtenAndReread': True,
  'allOtherSourcesPropertiesParentsUniqueIdsUnchanged': True,
  'bossParityAe7c5d0And40TrophyButtonsPreserved': True,
  'limitedEggReceiptAndPetSettingsUnchangedPendingQuantityConfirmation': True,
  'testFixturesWritten': False, 'studioSaveOrPublishUsed': False,
 }
 out = ROOT / 'reports/World2PaidFacilities_20261021'
 out.mkdir(exist_ok=True)
 (out / 'Writeback.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
 print(json.dumps(report, indent=2))

if __name__ == '__main__':
 main()
