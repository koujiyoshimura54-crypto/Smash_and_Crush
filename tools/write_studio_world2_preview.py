"""Write the Studio-only session arrival preview into the existing current place."""
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
EXPECTED='d46942552d9d5419611db79f750f8c881ee27dd2a57f90dda70ebc0e5e3db7b4'
FILES={
 'ServerScriptService.Config.DataStoreConfig':'src/ServerScriptService/Config/DataStoreConfig.luau',
 'ServerScriptService.Services.PlayerDataService':'src/ServerScriptService/Services/PlayerDataService.luau',
}
CONFIG_BEFORE='''-- Names only; production schema and keys are unchanged.
local Studio=game:GetService("RunService"):IsStudio()
local M={}
function M.GetName(productionName)
 return productionName..(Studio and "_Studio" or "")
end
return table.freeze(M)
'''


def main():
 raw=PLACE.read_bytes();assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Unexpected owner edit'
 e=Editor(raw);e.path=functools.lru_cache(None)(e.path);paths={e.path(r):r for r in e.parents}
 changed={};refs=set()
 for path,relative in FILES.items():
  ref=paths[path];refs.add(ref);old=string(e.get(ref,'Source'),0)[0]
  baseline=CONFIG_BEFORE.encode() if path.endswith('.DataStoreConfig') else subprocess.check_output(['git','show','00b68f8:'+relative],cwd=ROOT)
  assert old.replace(b'\r\n',b'\n')==baseline.replace(b'\r\n',b'\n'),path
  new=(ROOT/relative).read_text(encoding='utf8').encode()
  subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/relative)],check=True,stdout=subprocess.DEVNULL)
  e.set(ref,'Source',s(new));changed[path]={'before':hashlib.sha256(old).hexdigest(),'after':hashlib.sha256(new).hexdigest()}
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
 assert canonicalize(result)[0]==result;Document(result).assert_studio_bounds()
 assert PLACE.read_bytes()==raw
 with PLACE.open('r+b')as stream:
  stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
 saved=PLACE.read_bytes();assert saved==result
 reread=Editor(saved)
 for path,relative in FILES.items():assert string(reread.get(paths[path],'Source'),0)[0]==(ROOT/relative).read_text(encoding='utf8').encode()
 record={'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(saved).hexdigest(),'sources':changed,
  'allOtherSourcesPropertiesParentsUniqueIdsUnchanged':True,'syntaxCompiled':True,'writtenAndReread':True,
  'runtimeTested':False,'productionDataAccessed':False,'studioLaunched':False}
 out=ROOT/'reports/StudioWorld2ArrivalPreview_20261021';out.mkdir(exist_ok=True)
 (out/'Writeback.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf8');print(json.dumps(record,indent=2))


if __name__=='__main__':main()
