"""Write only reviewed animation Sources to the owner's current place, no Studio save.

Clones existing script classes; validates every original property/parent and the
repaired dense reference graph. Rig corrections run on fresh actors, not templates.
"""
import argparse
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess
import uuid
from rbxl_rows import Editor, s, string

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='2404d5dec7831e7f551c481c680f357bbb0c44a7107f04b2ad101a1c3837933f'
FILES={
 'ReplicatedStorage.Config.World2BossAnimationConfig':('src/ReplicatedStorage/Config/World2BossAnimationConfig.luau','ReplicatedStorage.Config.World2BossMovementConfig'),
 'ReplicatedStorage.Modules.World2BossRig':('src/ReplicatedStorage/Modules/World2BossRig.luau','ReplicatedStorage.Modules.NumberFormat'),
 'ReplicatedStorage.Modules.World2BossClip':('src/ReplicatedStorage/Modules/World2BossClip.luau','ReplicatedStorage.Modules.NumberFormat'),
 'ServerScriptService.World.World2BossAnimationService':('src/ServerScriptService/World/World2BossAnimationService.luau','ServerScriptService.World.BossChaseService'),
 'StarterPlayer.StarterPlayerScripts.World2BossAnimationClient':('src/StarterPlayer/StarterPlayerScripts/World2BossAnimationClient.client.luau','StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview'),
 'ServerScriptService.World.BossChaseService':('src/ServerScriptService/World/BossChaseService.luau',None),
 'ServerScriptService.World.BossVisualPlacement':('src/ServerScriptService/World/BossVisualPlacement.luau',None),
 'ServerScriptService.World.EnemyManager':('src/ServerScriptService/World/EnemyManager.luau',None),
 'ServerScriptService.StudioBossAnimationPreview':('src/ServerScriptService/StudioBossAnimationPreview.server.luau',None),
 'StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview':('src/StarterPlayer/StarterPlayerScripts/StudioBossAnimationPreview.client.luau',None),
}
def sha(raw):return hashlib.sha256(raw).hexdigest()
def apply(raw,compiler,expected=EXPECTED,update=False):
 assert sha(raw)==expected,'Current file changed; inspect instead of overwriting'
 before,edit=Editor(raw),Editor(raw)
 edit.path=functools.lru_cache(None)(edit.path)
 paths={edit.path(r):r for r in edit.parents}
 changed={};new={};approved=set()
 manual=string(before.get(paths['ServerScriptService.StudioBossAnimationPreview'],'Source'),0)[0].decode()
 for candidate in ('507777826','125749145'):assert candidate in manual
 for path,(relative,donor) in FILES.items():
  text=(ROOT/relative).read_text(encoding='utf-8')
  if path=='ServerScriptService.StudioBossAnimationPreview':
   start=manual.index('\tlocal walkCandidates =');end=manual.index('\tlocal candidates, ids =',start)
   assert manual[start:end] in text,'Manual candidate block must remain exact'
  subprocess.run([compiler,str(ROOT/relative),'--null'],check=True,stdout=subprocess.DEVNULL)
  if donor and not update:
   assert path not in paths
   parent,name=path.rsplit('.',1)
   ref,_=edit.clone(paths[donor],paths[parent],recursive=False)
   edit.set(ref,'Name',s(name))
   if (edit.class_of[ref],'ScriptGuid') in edit.columns:
    edit.set(ref,'ScriptGuid',s('{'+str(uuid.uuid4()).upper()+'}'))
   paths[path]=ref;new[path]=ref
  else:
   ref=paths[path]
   old=string(before.get(ref,'Source'),0)[0].decode()
   if update:
    assert path in paths
   elif 'StudioBossAnimationPreview' not in path or not path.startswith('ServerScriptService'):
    git=subprocess.check_output(['git','show','f499141:'+relative],cwd=ROOT).decode().replace('\r\n','\n')
    assert old.replace('\r\n','\n')==git,('Existing target has newer manual edits',path)
   else:
    start=manual.index('\tlocal walkCandidates =')
    end=manual.index('\tlocal candidates, ids =',start)
    assert manual[start:end] in text,'Manual candidate block must remain exact'
   approved.add((ref,'Source'))
   changed[path]={'before':sha(old.encode()),'after':sha(text.encode())}
  edit.set(ref,'Source',s(text))
  if (edit.class_of[ref],'Disabled') in edit.columns:edit.set(ref,'Disabled',b'\0')
 result,_=edit.build()
 after=Editor(result)
 assert len(after.parents)==len(before.parents)+len(new)
 assert all(after.parents[r]==p for r,p in before.parents.items())
 verified=0
 for (cid,name),column in before.columns.items():
  if (cid,name) not in edit.changed:
   assert before.doc.chunks[column[0]][1]==after.doc.chunks[after.columns[cid,name][0]][1]
   verified+=len(before.classes[cid]);continue
  for ref,value in before.col(cid,name)[3].items():
   if (ref,name) not in approved:assert after.get(ref,name)==value,(before.path(ref),name)
   verified+=1
 for path,(relative,_) in FILES.items():
  assert string(after.get(paths[path],'Source'),0)[0].decode()==(ROOT/relative).read_text(encoding='utf-8')
 return result,dict(inputSha256=sha(raw),outputSha256=sha(result),before=before.doc.summary(),after=after.doc.summary(),
  changedSources=changed,newSources=new,verifiedOriginalProperties=verified,
  allOtherPropertiesSourcesParentsPreserved=True,allSavedRigTemplatesAndGeometryUnchanged=True,
  manualPreviewCandidatesPreserved=True,writtenAndReread=False)

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--write',action='store_true')
 p.add_argument('--compiler',default=r'C:\Users\kouji\stage_skip_work\luau\luau-compile.exe')
 p.add_argument('--refine',action='store_true',help='Source-only refinement after the initial reviewed write')
 p.add_argument('--expected-sha256');args=p.parse_args()
 if args.refine:assert args.expected_sha256,'Explicit current hash required for refinement'
 raw=PLACE.read_bytes();result,report=apply(raw,args.compiler,args.expected_sha256 or EXPECTED,args.refine)
 if args.write:
  assert not Path(str(PLACE)+'.lock').exists(),'Do not write while Studio holds the file'
  assert PLACE.read_bytes()==raw
  with PLACE.open('r+b') as stream:
   stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
  reread=PLACE.read_bytes();assert reread==result;Editor(reread).doc.assert_studio_bounds()
  report['writtenAndReread']=True
  folder=ROOT/'reports/World2BossWalk_20261022';folder.mkdir(exist_ok=True)
  (folder/('Refinement.json' if args.refine else 'Writeback.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 print(json.dumps(report,indent=2))
if __name__=='__main__':main()
