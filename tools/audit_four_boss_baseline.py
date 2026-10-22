"""Read-only comparison of the current place with recorded Sources/rig metadata."""
from pathlib import Path
import collections,functools,hashlib,json,difflib,sys
sys.stdout.reconfigure(encoding='utf-8')
from rbxl_rows import Editor,string,unf
ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r"C:\Users\kouji\MergeToForge_CurrentCloud.rbxl")
e=Editor(PLACE.read_bytes());e.path=functools.lru_cache(None)(e.path)
if '--weld-schema' in sys.argv:
 for cid,(name,refs) in e.doc.classes.items():
  if name=='WeldConstraint':
   print([(n,e.columns[c,n][1]) for c,n in e.columns if c==cid])
   r=next(r for r in refs if 'SCP173_Display' in e.path(r))
   for c,n in e.columns:
    if c==cid:print(n,repr(e.get(r,n)))
 sys.exit()
paths=collections.defaultdict(list)
for r in e.parents:paths[e.path(r)].append(r)
if '--geometry' in sys.argv:
 from rbxl_geometry import BASE_PARTS,matrix,unvector
 for boss in ['023','058','173','939']:
  prefix='ServerStorage.EnemyTemplates.World2SCPDisplays.SCP'+boss+'_Display'
  rows=[]
  for r in e.parents:
   path=e.path(r);kind=e.doc.classes[e.class_of[r]][0]
   if not path.startswith(prefix+'.') or kind not in BASE_PARTS:continue
   rotation,pos=e.get(r,'CFrame')
   rows.append({'ref':r,'path':path[len(prefix)+1:],'size':unvector(e.get(r,'size')),'position':unvector(pos),'rotation':matrix(rotation),'transparency':unf(e.get(r,'Transparency'))})
  if '--compact' in sys.argv:
   print('BOSS',boss)
   for row in rows:
    print(row['ref'],row['path'],'size',','.join(f'{v:.3f}' for v in row['size']),'pos',','.join(f'{v:.3f}' for v in row['position']))
  else:print(json.dumps({'boss':boss,'parts':rows},ensure_ascii=False))
 sys.exit()
if '--joints' in sys.argv:
 for r in e.parents:
  path=e.path(r);kind=e.doc.classes[e.class_of[r]][0]
  if '.SCP058_Display.' in path and (e.class_of[r],'Part0') in e.columns:
   print(kind,path,e.path(e.get(r,'Part0')),e.path(e.get(r,'Part1')))
 sys.exit()
changes=[];matched=0
for f in (ROOT/'src').rglob('*.luau'):
 rel=f.relative_to(ROOT/'src').as_posix()
 path=rel.removesuffix('.luau').removesuffix('.server').removesuffix('.client').replace('/','.')
 if len(paths[path])!=1:continue
 r=paths[path][0]
 if (e.class_of[r],'Source') not in e.columns:continue
 saved=string(e.get(r,'Source'),0)[0].decode().replace('\r\n','\n');repo=f.read_text(encoding='utf-8')
 if saved!=repo:
  changes.append({'path':path,'diff':list(difflib.unified_diff(repo.splitlines(),saved.splitlines(),fromfile='Git',tofile='Current rbxl'))[:40]})
 else:matched+=1
old=json.loads((ROOT/'reports/World2RemainingBossAnimations_20261022/AssetAudit.json').read_text(encoding='utf-8'))['Current']['bosses']
rig=[]
for boss,rows in old.items():
 for row in rows:
  candidates=paths[row['path']]
  if len(candidates)!=1:continue
  r=candidates[0]
  for key,value in row.get('props',{}).items():
   if (e.class_of[r],key) not in e.columns:continue
   typ=e.columns[e.class_of[r],key][1];v=e.get(r,key)
   if typ==1:v=string(v,0)[0].decode()
   elif typ==4:v=unf(v)
   elif typ==2:v=v!=b'\0'
   elif typ==19:v=e.path(v) if v>=0 else None
   elif typ==26:v=list(v)
   else:continue
   if v!=value:rig.append({'path':row['path'],'property':key,'before':value,'now':v})
print(json.dumps({'summary':e.doc.summary(),'repoSourcesMatched':matched,'sourceDifferences':changes,'recordedRigPropertyDifferences':rig},ensure_ascii=False,indent=2))
