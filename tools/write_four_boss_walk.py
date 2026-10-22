"""Apply the approved four-boss delta to the current place, preserving every other row."""
from pathlib import Path
import argparse,collections,functools,hashlib,json,os,struct,subprocess
from rbxl_rows import Editor,s,string,vector,unvector
from rbxl_geometry import BASE_PARTS
from prepare_four_boss_test import FILES,ROOT
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
BASE='f4850f737eddeb0ecf6aae87e3b0be396daf35f06a3eb2ca3f89d6654023165f'
REPORT=ROOT/'reports/World2FourBossWalk_20261022'
def main():
 p=argparse.ArgumentParser();p.add_argument('--write',action='store_true');p.add_argument('--verify',action='store_true');a=p.parse_args()
 raw=PLACE.read_bytes()
 if a.verify:
  import ctypes
  e=Editor(raw);e.doc.assert_studio_bounds()
  saved=json.loads((REPORT/'Writeback.json').read_text(encoding='utf-8'))
  assert hashlib.sha256(raw).hexdigest()==saved['after']['sha256'],'Place changed after writeback'
  for path,file in FILES.items():assert string(e.get(e.find(path),'Source'),0)[0].decode().replace('\r\n','\n')==(ROOT/file).read_text(encoding='utf-8')
  kernel=ctypes.WinDLL('kernel32',use_last_error=True)
  kernel.CreateFileW.restype=ctypes.c_void_p
  kernel.CreateFileW.argtypes=[ctypes.c_wchar_p,ctypes.c_ulong,ctypes.c_ulong,ctypes.c_void_p,ctypes.c_ulong,ctypes.c_ulong,ctypes.c_void_p]
  handle=kernel.CreateFileW(str(PLACE),0x80000000,0,None,3,0,None)
  assert handle!=ctypes.c_void_p(-1).value,('File still held',ctypes.get_last_error())
  kernel.CloseHandle.argtypes=[ctypes.c_void_p];kernel.CloseHandle(handle)
  report={'File':str(PLACE),'Integrity':e.doc.summary(),'SavedSourcesMatch':len(FILES),'ExclusiveReadOpen':True,'LockFilePresent':Path(str(PLACE)+'.lock').exists(),'StudioSavePublishUsed':False}
  assert not report['LockFilePresent']
  (REPORT/'FinalFileVerification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,indent=2));return
 assert hashlib.sha256(raw).hexdigest()==BASE,'Current place changed: do not overwrite'
 e=Editor(raw);old=Editor(raw);e.path=functools.lru_cache(None)(e.path)
 allowed=set();added=[];removed=[];changes=[]
 def setv(r,k,v):
  if e.get(r,k)!=v:e.set(r,k,v);allowed.add((r,k));changes.append((e.path(r),k))
 module=e.find('ReplicatedStorage.Modules.World2BossRig')
 for path,file in FILES.items():
  try:r=e.find(path)
  except StopIteration:
   assert path in ('ReplicatedStorage.Modules.World2BossGait','ReplicatedStorage.Modules.World2BossGaitRig')
   r,_=e.clone(module,e.parents[module],recursive=False);added.append(r);e.set(r,'Name',s(path.split('.')[-1]))
  if r not in added:
   baseline=subprocess.check_output(['git','show','a1c8285:'+file],cwd=ROOT).decode().replace('\r\n','\n')
   assert string(e.get(r,'Source'),0)[0].decode().replace('\r\n','\n')==baseline,('Unexpected target Source edit',path)
  setv(r,'Source',s((ROOT/file).read_text(encoding='utf-8')))
 recipe=json.loads((REPORT/'RigRecipe.json').read_text(encoding='utf-8'))
 motor=next(r for r in e.parents if e.doc.classes[e.class_of[r]][0]=='Motor6D')
 def cf(v):return (b'\0'+struct.pack('<9f',*v[3:]),vector(*v[:3]))
 for boss in recipe:
  model=e.find('ServerStorage.EnemyTemplates.World2SCPDisplays.SCP'+boss['Number']+'_Display')
  refs=e.subtree(model);parts=[r for r in refs if e.doc.classes[e.class_of[r]][0] in BASE_PARTS]
  ids={};used=set()
  for row in boss['Parts']:
   matches=[r for r in parts if e.names[r]==row['Name'] and max(abs(x-y) for x,y in zip(unvector(e.get(r,'CFrame')[1]),row['Position']))<.0001 and max(abs(x-y) for x,y in zip(unvector(e.get(r,'size')),row['Size']))<.0001]
   assert len(matches)==1,('Part identity ambiguous',boss['Number'],row,len(matches))
   ids[row['Id']]=matches[0];assert matches[0] not in used;used.add(matches[0])
  assert len(used)==len(parts)
  def identify(j):
   def endpoint(r,name):
    if (e.class_of[r],name) not in e.columns:
     name+='Internal'
     assert (e.class_of[r],name) in e.columns,[n for c,n in e.columns if c==e.class_of[r]]
    return e.get(r,name)
   matches=[r for r in refs if r not in e.removed and e.doc.classes[e.class_of[r]][0]==j['Class'] and e.names[r]==j['Name'] and e.parents[r]==ids.get(j.get('Parent'),model) and endpoint(r,'Part0')==ids.get(j.get('Part0'),-1) and endpoint(r,'Part1')==ids.get(j.get('Part1'),-1)]
   assert len(matches)==1,('Joint identity ambiguous',boss['Number'],j,len(matches))
   return matches[0]
  for j in boss['Removed']:
   r=identify(j);assert len(e.subtree(r))==1;e.remove(r);removed.append(r)
  for j in boss['Joints']:
   if j['Existed']:r=identify(j['Original'])
   else:
    assert j['Class']=='Motor6D',j
    r,_=e.clone(motor,ids.get(j.get('Parent'),model),recursive=False);added.append(r);e.set(r,'Name',s(j['Name']))
   for prop in ('Part0','Part1'):setv(r,prop if (e.class_of[r],prop) in e.columns else prop+'Internal',ids.get(j.get(prop),-1))
   if not j['Existed'] or j['FramesChanged']:
    setv(r,'C0',cf(j['C0']));setv(r,'C1',cf(j['C1']))
  attrs=string(e.get(model,'AttributesSerialize'),0)[0]
  assert b'GaitRigVersion' not in attrs
  count=struct.unpack('<I',attrs[:4])[0] if attrs else 0
  setv(model,'AttributesSerialize',s(struct.pack('<I',count+1)+(attrs[4:] if attrs else b'')+s('GaitRigVersion')+b'\x06'+struct.pack('<d',1)))
 result,repair=e.build();after=Editor(result);mapping=e.final_mapping
 # All row deltas must be explicitly authorized above. Also covers auto-null refs.
 checked=0
 for (cid,name),col in e.columns.items():
  if (cid,name) not in e.changed:continue
  before=old.col(cid,name)[3];current=e.col(cid,name)[3];saved=after.col(cid,name)[3]
  for r,v in before.items():
   if r in e.removed:continue
   if (r,name) not in allowed:assert current[r]==v,('Unexpected mutation',old.path(r),name)
   value=current[r]
   if col[1]==19:value=mapping.get(value,value)
   elif col[1]==34 and value[0]==2:value=(2,mapping.get(value[1],value[1]))
   assert saved[mapping.get(r,r)]==value,('Saved property mismatch',r,name)
   checked+=1
 for r,parent in old.parents.items():
  if r not in e.removed:assert after.parents[mapping.get(r,r)]==mapping.get(parent,parent)
 assert set(e.removed)==set(removed)
 assert len(added)==16 and len(removed)==14,(len(added),len(removed))
 summary={'before':old.doc.summary(),'after':after.doc.summary(),'AddedInstances':len(added),'RemovedObsoleteJoints':len(removed),'PreservedPropertyRowsChecked':checked,'AllowedChangedProperties':changes,'SourceFiles':FILES,'Repair':repair,'Written':a.write,'StudioOpen':'Checked separately by native saved-file runner; not implied by decoding'}
 if a.write:
  assert not Path(str(PLACE)+'.lock').exists(),'Studio holds current file'
  assert PLACE.read_bytes()==raw,'Current file changed during validation'
  with PLACE.open('r+b') as handle:handle.write(result);handle.truncate();handle.flush();os.fsync(handle.fileno())
  assert PLACE.read_bytes()==result
  Editor(PLACE.read_bytes()).doc.assert_studio_bounds()
  (REPORT/'Writeback.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
 else:(REPORT/'WritebackDryRun.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
 print(json.dumps({k:v for k,v in summary.items() if k not in ('AllowedChangedProperties','Repair','SourceFiles')},indent=2))
if __name__=='__main__':main()
