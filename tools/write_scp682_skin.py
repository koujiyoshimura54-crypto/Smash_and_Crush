"""Apply only the audited current-file SCP682 skin/locomotion delta, without Studio Save."""
from pathlib import Path
import argparse,functools,hashlib,json,os,subprocess
from rbxl_rows import Editor,s,string

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
BASE='db08f1f7a0dff736033f88dd5d4cf555b15b1c147da94cbd033a30046c0b5371'
REPORT=ROOT/'reports/World2SCP682Skin_20261022'
FILES={
 'ReplicatedStorage.Config.World2BossAnimationConfig':'src/ReplicatedStorage/Config/World2BossAnimationConfig.luau',
 'ReplicatedStorage.Config.World2BossVisualConfig':'src/ReplicatedStorage/Config/World2BossVisualConfig.luau',
 'ReplicatedStorage.Modules.World2BossGait':'src/ReplicatedStorage/Modules/World2BossGait.luau',
 'ReplicatedStorage.Modules.World2BossRig':'src/ReplicatedStorage/Modules/World2BossRig.luau',
 'ReplicatedStorage.Modules.World2SCP682Gait':'src/ReplicatedStorage/Modules/World2SCP682Gait.luau',
 'ServerScriptService.World.BossVisualPlacement':'src/ServerScriptService/World/BossVisualPlacement.luau',
 'ServerScriptService.StudioBossAnimationPreview':'src/ServerScriptService/StudioBossAnimationPreview.server.luau',
 'StarterPlayer.StarterPlayerScripts.World2BossAnimationClient':'src/StarterPlayer/StarterPlayerScripts/World2BossAnimationClient.client.luau',
 'StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview':'src/StarterPlayer/StarterPlayerScripts/StudioBossAnimationPreview.client.luau',
}
def main():
 p=argparse.ArgumentParser();p.add_argument('--write',action='store_true');a=p.parse_args()
 raw=PLACE.read_bytes();assert hashlib.sha256(raw).hexdigest()==BASE,'Current file changed: inspect before writing'
 old,e=Editor(raw),Editor(raw);e.path=functools.lru_cache(None)(e.path)
 allowed=set();added=[]
 def setv(r,prop,value):
  if e.get(r,prop)!=value:e.set(r,prop,value);allowed.add((r,prop))
 for path,file in FILES.items():
  try:r=e.find(path)
  except StopIteration:
   assert path=='ReplicatedStorage.Modules.World2SCP682Gait'
   source=e.find('ReplicatedStorage.Modules.World2BossGait')
   r,_=e.clone(source,e.parents[source],recursive=False);added.append(r);e.set(r,'Name',s('World2SCP682Gait'))
  if r not in added:
   baseline=subprocess.check_output(['git','show','82e8981:'+file],cwd=ROOT).decode().replace('\r\n','\n')
   assert string(e.get(r,'Source'),0)[0].decode().replace('\r\n','\n')==baseline,path
  subprocess.run([str(Path(os.environ['TEMP'])/'luau-compile.exe'),str(ROOT/file)],check=True,stdout=subprocess.DEVNULL)
  setv(r,'Source',s((ROOT/file).read_text(encoding='utf-8')))
 model=e.find('Workspace.SCP-682');mesh=e.find('Workspace.SCP-682.scp_crock_reference')
 refs=e.subtree(model);classes=[e.doc.classes[e.class_of[r]][0]for r in refs]
 assert classes.count('Bone')==32 and classes.count('MeshPart')==1
 assert not set(classes)&{'Script','LocalScript','ModuleScript'}
 assert b'10775394100' in e.get(mesh,'MeshId')
 e.parents[model]=e.find('ServerStorage.EnemyTemplates.World2SCPDisplays')
 setv(model,'Name',s('SCP682_Skinned_Display'));setv(model,'PrimaryPart',mesh);setv(mesh,'Anchored',b'\1')
 e.path.cache_clear()
 result,repair=e.build();after=Editor(result);mapping=e.final_mapping
 checked=0
 for (cid,prop),col in old.columns.items():
  if (cid,prop) not in e.changed:
   # Build may canonicalize references even in untouched columns.
   if col[1] not in (19,34):
    assert old.doc.chunks[col[0]][1]==after.doc.chunks[after.columns[cid,prop][0]][1]
    checked+=len(old.classes[cid]);continue
  for r,value in old.col(cid,prop)[3].items():
   current=e.get(r,prop)
   if (r,prop) not in allowed:assert current==value,('Unexpected delta',old.path(r),prop)
   if col[1]==19:current=mapping.get(current,current)
   elif col[1]==34 and current[0]==2:current=(2,mapping.get(current[1],current[1]))
   assert after.get(mapping.get(r,r),prop)==current,('Saved mismatch',r,prop)
   checked+=1
 for r,parent in old.parents.items():
  expected=e.parents[r] if r==model else parent
  assert after.parents[mapping.get(r,r)]==mapping.get(expected,expected)
 assert not e.removed and len(added)==1
 report={'InputSha256':BASE,'OutputSha256':hashlib.sha256(result).hexdigest(),'Sources':FILES,
  'MovedFrom':'Workspace.SCP-682','MovedTo':'ServerStorage.EnemyTemplates.World2SCPDisplays.SCP682_Skinned_Display',
  'OriginalBonesPreserved':32,'OriginalMeshSkinTextureSizeAndInitialPosesPreserved':True,
  'OtherPropertiesPreservedChecked':checked,'AddedModules':1,'RemovedInstances':0,
  'AllowedChanges':[{'Path':e.path(r),'Property':p}for r,p in sorted(allowed)],
  'Integrity':after.doc.summary(),'Repair':repair,'WrittenAndReread':False}
 if a.write:
  assert not Path(str(PLACE)+'.lock').exists(),'Studio lock remains'
  assert PLACE.read_bytes()==raw,'Current file changed during validation'
  with PLACE.open('r+b')as handle:
   handle.write(result);handle.truncate();handle.flush();os.fsync(handle.fileno())
  assert PLACE.read_bytes()==result
  saved=Editor(PLACE.read_bytes())
  for path,file in FILES.items():assert string(saved.get(saved.find(path),'Source'),0)[0].decode().replace('\r\n','\n')==(ROOT/file).read_text(encoding='utf-8')
  report['WrittenAndReread']=True
 REPORT.mkdir(exist_ok=True)
 (REPORT/('Writeback.json'if a.write else 'WritebackDryRun.json')).write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps({k:v for k,v in report.items()if k not in ('Sources','AllowedChanges','Repair')},indent=2))
if __name__=='__main__':main()
