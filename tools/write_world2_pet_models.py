"""Register only the approved 35 World2 Pet templates on the current place."""
import argparse, copy, csv, functools, hashlib, json, os, re, subprocess
from pathlib import Path
from rbxl_rows import Editor, s, string
from rbxl_referents import Document, canonicalize

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='ed0180132ca96c00b62b3926faf88957ee25f2c518a8b0cfa115b911165f8293'
REPORT=ROOT/'reports/World2PetModels_20261021'
PATHS=['ReplicatedStorage.Config.World2GameplayConfig','ReplicatedStorage.Modules.Pet',
       'ReplicatedStorage.Modules.Egg','ReplicatedStorage.Modules.LimitedPetViewport']+[
       'StarterPlayer.StarterPlayerScripts.Services.'+name for name in
       ('EggClient','PetClient','PetFollowClient','HatchClient','StandClient')]
MODELS=[[27,28,32,52,30,141,98],[35,40,63,6,54,112,14],[115,82,92,72,4,168,113],
        [104,131,164,26,18,129,51],[107,89,93,172,133,117,178]]
ODDS=[25,25,25,15,6.5,3,.5]

def sha(raw):return hashlib.sha256(raw).hexdigest()
def classname(e,ref):return e.doc.classes[e.class_of[ref]][0]
def apply(raw):
 assert sha(raw)==EXPECTED,'Unexpected current-file edit: inspect before writing'
 before,e=Editor(raw),Editor(raw);e.path=functools.lru_cache(None)(e.path)
 paths={e.path(r):r for r in e.parents};allowed=set();source_hashes={}
 for path in PATHS:
  relative='src/'+path.replace('.','/')+'.luau';ref=paths[path]
  old=string(e.get(ref,'Source'),0)[0]
  baseline=subprocess.check_output(['git','show','58849b4:'+relative],cwd=ROOT).replace(b'\r\n',b'\n')
  assert old.replace(b'\r\n',b'\n')==baseline,path
  new=(ROOT/relative).read_text(encoding='utf8').encode()
  assert b'PetSwapTest' not in new and b'PurchasesTestEnvironment' not in new
  subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/relative)],check=True,stdout=subprocess.DEVNULL)
  e.set(ref,'Source',s(new));allowed.add((ref,'Source'))
  source_hashes[path]={'before':sha(old),'after':sha(new)}
 # Select the Pets branch structurally; the pack contains two siblings named Mod.
 roots=[r for r in e.parents if e.names.get(r)=='Pets' and classname(e,r)=='Folder'
        and e.path(r)=='Workspace.Stud Egg & Pet.Mod.Model.Pets']
 assert len(roots)==1;source_root=roots[0]
 runtime='ReplicatedStorage.Assets.World2Pets';assert runtime not in paths
 folder,_=e.clone(paths['ReplicatedStorage.Assets.LimitedEgg01Pets'],paths['ReplicatedStorage.Assets'],recursive=False)
 e.set(folder,'Name',s('World2Pets'))
 mappings=[];all_clones={}
 catalog=list(csv.DictReader((ROOT/'docs/Stud_Pet_Catalog.csv').open(encoding='utf-8-sig')))
 config=string(before.get(paths[PATHS[0]],'Source'),0)[0].decode()
 def table(key):return json.loads(re.search(r' '+key+r'=(\{.*\}),',config).group(1).replace('{','[').replace('}',']'))
 old_names=table('PetSources');effects=table('PetMultipliers');egg_ids=table('EggIds')
 for ei,row in enumerate(MODELS):
  assert sum(ODDS)==100
  for slot,num in enumerate(row):
   name=f'Pet_{num:03d}'
   matches=[r for r,parent in e.parents.items() if parent==source_root and e.names[r]==name]
   assert len(matches)==1,(name,matches);ref=matches[0]
   records=[record for record in catalog if record['モデル名']==name]
   assert len(records)==1 and records[0]['Full Path']==e.path(ref),name
   new,mapping=e.clone(ref,folder);all_clones.update(mapping)
   for old,clone in mapping.items():
    assert classname(e,old) not in ('Script','LocalScript','ModuleScript')
    # Preserve purchased attributes and all rig/visual properties; clone() only regenerates identity.
    for prop in ('AttributesSerialize','SerializedOverrides'):
     if (e.class_of[old],prop) in e.columns:e.set(clone,prop,e.get(old,prop))
    for (cid,prop),col in e.columns.items():
     if cid!=e.class_of[old]:continue
     expected=copy.deepcopy(e.get(old,prop))
     if prop in ('UniqueId','HistoryId'):continue
     if col[1]==19:
      assert expected==-1 or expected in mapping,(name,prop,'external rig reference',expected)
      expected=mapping.get(expected,expected)
     elif col[1]==34 and expected[0]==2:
      assert expected[1]==-1 or expected[1] in mapping
      expected=(2,mapping.get(expected[1],expected[1]))
     assert e.get(clone,prop)==expected,(name,prop)
   mappings.append({'Egg':egg_ids[ei],'Slot':slot+1,'ProbabilityPercent':ODDS[slot],
    'SavedSpeciesId':'W2 '+old_names[ei][slot],'NewModelId':name,'StrengthMultiplier':effects[ei][slot],
    'StrengthBonusPercent':round((effects[ei][slot]-1)*100,6),
    'SourceFullPath':e.path(ref),'RuntimeFullPath':runtime+'.'+name,'ClonedInstances':len(mapping)})
 assert len({r['NewModelId'] for r in mappings})==35
 result,repair=e.build();after=Editor(result);assert not e.removed and not e.final_mapping
 assert all(after.parents[r]==p for r,p in before.parents.items())
 verified=0
 for (cid,prop),column in before.columns.items():
  if (cid,prop) not in e.changed:
   assert before.doc.chunks[column[0]][1]==after.doc.chunks[after.columns[cid,prop][0]][1]
   verified+=len(before.classes[cid]);continue
  for ref,old in before.col(cid,prop)[3].items():
   actual=after.get(ref,prop)
   assert actual==(e.get(ref,prop) if (ref,prop) in allowed else old),(ref,prop)
   verified+=1
 # Validate every persisted clone property, including remapped joints, PrimaryPart and meshes.
 for new in [folder,*all_clones.values()]:
  assert after.parents[new]==e.parents[new]
  for cid,prop in e.columns:
   if cid==e.class_of[new]:assert after.get(new,prop)==e.get(new,prop),(new,prop)
 assert canonicalize(result)[0]==result;Document(result).assert_studio_bounds()
 return result,{'inputSha256':EXPECTED,'outputSha256':sha(result),'bytes':len(result),
  'changedSources':source_hashes,'models':mappings,'addedInstances':len(all_clones)+1,
  'verifiedExistingProperties':verified,'allOtherPropertiesSourcesParentsPreserved':True,
  'allClonePropertiesAndInternalReferencesVerified':True,'savedSpeciesAndReceiptVersionUnchanged':True,
  'writtenAndReread':False,'studioSaveOrPublishUsed':False,'testFixturesWritten':False}

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true');args=parser.parse_args()
 raw=PLACE.read_bytes();result,report=apply(raw)
 if args.write:
  assert not Path(str(PLACE)+'.lock').exists(),'Close only the owned verification Studio first'
  assert PLACE.read_bytes()==raw,'File changed during validation'
  with PLACE.open('r+b') as stream:
   stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
  saved=PLACE.read_bytes();assert saved==result
  Document(saved).assert_studio_bounds();report['writtenAndReread']=True
  REPORT.mkdir(exist_ok=True)
  (REPORT/'Writeback.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
  with (REPORT/'Assignments.csv').open('w',encoding='utf8',newline='') as f:
   w=csv.DictWriter(f,fieldnames=list(report['models'][0]));w.writeheader();w.writerows(report['models'])
 print(json.dumps({k:v for k,v in report.items() if k not in ('models','changedSources')},indent=2))
if __name__=='__main__':main()
