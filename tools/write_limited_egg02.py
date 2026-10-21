"""Source-only Limited Egg 02 connection on the current e83fa54 place."""
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess
from rbxl_rows import Editor, s, string
from rbxl_referents import Document, canonicalize

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='8afea7a24a37d00aa360f36d73fb02cf2aa3f8593d375498ff69892c87d94703'
FILES={
 'ReplicatedStorage.Config.LimitedEggConfig':'src/ReplicatedStorage/Config/LimitedEggConfig.luau',
 'ReplicatedStorage.Config.World2GameplayConfig':'src/ReplicatedStorage/Config/World2GameplayConfig.luau',
 'ServerScriptService.Systems.Purchases.ReceiptService':'src/ServerScriptService/Systems/Purchases/ReceiptService.luau',
 'ServerScriptService.Services.PlayerDataService':'src/ServerScriptService/Services/PlayerDataService.luau',
 'StarterPlayer.StarterPlayerScripts.Services.StandClient':'src/StarterPlayer/StarterPlayerScripts/Services/StandClient.luau',
 'StarterPlayer.StarterPlayerScripts.Services.EggClient':'src/StarterPlayer/StarterPlayerScripts/Services/EggClient.luau',
 'StarterPlayer.StarterPlayerScripts.Services.HatchClient':'src/StarterPlayer/StarterPlayerScripts/Services/HatchClient.luau',
}

def main():
 raw=PLACE.read_bytes()
 assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Unexpected user edit; inspect before writing'
 e=Editor(raw);e.path=functools.lru_cache(None)(e.path)
 paths={e.path(ref):ref for ref in e.parents}
 sources,changes,refs={},{},set()
 for path,relative in FILES.items():
  ref=paths[path];old=string(e.get(ref,'Source'),0)[0]
  source=(ROOT/relative).read_text(encoding='utf8')
  assert 'PurchasesTest' not in source and 'EggTest' not in source
  subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/relative)],check=True,stdout=subprocess.DEVNULL)
  sources[path]=source.encode();e.set(ref,'Source',s(sources[path]));refs.add(ref)
  changes[path]={'before':hashlib.sha256(old).hexdigest(),'after':hashlib.sha256(sources[path]).hexdigest()}
 result,_=e.build();before,after=Editor(raw),Editor(result)
 assert before.parents==after.parents and before.classes==after.classes
 for key,column in before.columns.items():
  cid,name=key
  if key not in e.changed:
   assert before.doc.chunks[column[0]][1]==after.doc.chunks[after.columns[key][0]][1]
  else:
   assert name=='Source'
   for ref,old in before.col(cid,name)[3].items():
    assert after.get(ref,name)==(e.get(ref,name) if ref in refs else old)
 assert canonicalize(result)[0]==result
 Document(result).assert_studio_bounds()
 assert PLACE.read_bytes()==raw,'Current file changed during validation'
 with PLACE.open('r+b') as stream:
  stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
 saved=PLACE.read_bytes();assert saved==result
 reread=Editor(saved)
 for path,source in sources.items():assert string(reread.get(paths[path],'Source'),0)[0]==source
 report={'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(saved).hexdigest(),'bytes':len(saved),
  'sources':changes,'syntaxCompiled':True,'writtenAndReread':True,
  'allOtherSourcesPropertiesParentsUniqueIdsUnchanged':True,
  'bossTrophyPremiumPassConnectionsAndPetModelsPreserved':True,
  'productId':3720640383,'quantityPerPurchase':1,'button':'Open1',
  'studioSaveOrPublishUsed':False,'testFixturesWritten':False}
 out=ROOT/'reports/LimitedEgg02_20261021';out.mkdir(exist_ok=True)
 (out/'Writeback.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
 print(json.dumps(report,indent=2))

if __name__=='__main__':main()
