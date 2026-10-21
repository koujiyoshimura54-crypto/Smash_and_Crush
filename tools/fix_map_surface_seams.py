"""Trim proved exposed block-face overlaps at seams; never infer Mesh surfaces."""
import argparse
import collections
import functools
import hashlib
import itertools
import json
import math
import os
from pathlib import Path
from rbxl_rows import Editor, unvector, vector, unf
from rbxl_geometry import matrix
from rbxl_referents import Document, canonicalize

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='aa1bc4ed9ce762e687b7a798e23899fa6e0ef443506c7cbe2a8b5dab3b7d1274'


def world(path,pos):
 if path.startswith('Workspace.World2Map.'):return 2
 if path.startswith(('Workspace.GeneratedMap.','Workspace.Map.Spawn.','Workspace.Treadmills.','Workspace.Ramp.')) and 140<pos[0]<430 and -110<pos[2]<1720:return 1
 return 0


def raybox(origin,target,p):
 low,high=0.,1.
 for a in range(3):
  d=target[a]-origin[a]
  if abs(d)<1e-8:
   if not p['lo'][a]<origin[a]<p['hi'][a]:return False
  else:
   t0,t1=sorted(((p['lo'][a]-origin[a])/d,(p['hi'][a]-origin[a])/d))
   low=max(low,t0);high=min(high,t1)
   if high<=low:return False
 return high>1e-5 and low<.99999


def visible(p,q,axis,sign,parts,unknown):
 axes=[i for i in range(3)if i!=axis]
 target=[0.,0.,0.];target[axis]=p['hi' if sign>0 else 'lo'][axis]
 for a in axes:target[a]=(max(p['lo'][a],q['lo'][a])+min(p['hi'][a],q['hi'][a]))/2
 w=p['world'];lobby='.TrainingArea.'in p['path'] or '.Map.Spawn.'in p['path']
 if axis==1:
  if sign<0 or target[1]>10:return False
  origin=[target[0],target[1]+8,target[2]]
 else:
  if not 1<target[1]<25:return False
  center=274.5 if w==1 and lobby else 287.8 if w==1 else 14.62 if lobby else 27.92
  zlo,zhi=(-56,77)if w==1 and lobby else (1859,2012)if lobby else (90,1673)if w==1 else (2040,3630)
  origin=[center,10 if w==1 else 8,max(zlo,min(zhi,target[2]+(sign*12 if axis==2 else 0)))]
  if (origin[axis]-target[axis])*sign<=.01:return False
 for other in parts+unknown:
  if other['world']==w and other['ref'] not in (p['ref'],q['ref']) and raybox(origin,target,other):return False
 return True


def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true');args=parser.parse_args()
 raw=PLACE.read_bytes();assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Unexpected local edit'
 e=Editor(raw);e.path=functools.lru_cache(None)(e.path);children=collections.defaultdict(list)
 for r,parent in e.parents.items():children[parent].append(r)
 parts=[];unknown=[];skipped=collections.Counter()
 for r in e.parents:
  kind=e.doc.classes[e.class_of[r]][0]
  if kind not in ('Part','MeshPart','UnionOperation','WedgePart','CornerWedgePart'):continue
  if unf(e.get(r,'Transparency'))>=.99:continue
  cf=e.get(r,'CFrame');pos=unvector(cf[1]);path=e.path(r);w=world(path,pos)
  if not w:continue
  m=matrix(cf[0]);sz=unvector(e.get(r,'size'));h=[sum(abs(m[a*3+k])*sz[k]/2 for k in range(3))for a in range(3)]
  item={'ref':r,'path':path,'world':w,'lo':[pos[a]-h[a]for a in range(3)],'hi':[pos[a]+h[a]for a in range(3)],'matrix':m}
  mesh=any(e.doc.classes[e.class_of[c]][0]in('SpecialMesh','BlockMesh','CylinderMesh')for c in children[r])
  if kind!='Part' or mesh or int.from_bytes(e.get(r,'shape'),'big')!=1 or any(abs(v-round(v))>.0001 for v in m):
   unknown.append(item);skipped[kind+('WithMesh'if mesh else '')]+=1;continue
  parts.append(item)
 buckets=collections.defaultdict(list)
 for p in parts:
  for a in range(3):
   for sign in (-1,1):
    if a==1 and(sign<0 or p['hi'][1]>10):continue
    buckets[p['world'],a,sign,round(p['hi'if sign>0 else'lo'][a],3)].append(p)
 candidates=[]
 for(w,a,sign,plane),rows in buckets.items():
  for p,q in itertools.combinations(rows,2):
   if all(min(p['hi'][k],q['hi'][k])-max(p['lo'][k],q['lo'][k])>.001 for k in range(3)if k!=a):candidates.append((p,q,a,sign))
 # Only seam trims with an exact volume-union proof are permitted.
 changes={};details=[];rejected=collections.Counter()
 for p,q,face,sign in candidates:
  if abs(p['hi'if sign>0 else'lo'][face]-q['hi'if sign>0 else'lo'][face])>.00025:continue
  if any(min(p['hi'][k],q['hi'][k])-max(p['lo'][k],q['lo'][k])<=.001 for k in range(3)if k!=face):continue
  options=[]
  for small,cover in ((p,q),(q,p)):
   for axis in range(3):
    if axis==face:continue
    if not all(cover['lo'][k]<=small['lo'][k]+.0002 and cover['hi'][k]>=small['hi'][k]-.0002 for k in range(3)if k!=axis):continue
    if small['lo'][axis]<cover['lo'][axis]<small['hi'][axis]<cover['hi'][axis]+.0002:
     options.append((small['hi'][axis]-cover['lo'][axis],small,cover,axis,'hi',cover['lo'][axis]))
    elif cover['lo'][axis]-.0002<small['lo'][axis]<cover['hi'][axis]<small['hi'][axis]:
     options.append((cover['hi'][axis]-small['lo'][axis],small,cover,axis,'lo',cover['hi'][axis]))
  if not options:rejected['No shape-preserving single-axis seam trim']+=1;continue
  amount,small,cover,axis,side,bound=min(options,key=lambda o:o[0])
  if amount<=.0005 or amount>.25:rejected['Larger overlap; appearance/role confirmation needed']+=1;continue
  if not visible(p,q,face,sign,parts,unknown):rejected['Hidden/backside/unknown Mesh occlusion']+=1;continue
  ref=small['ref'];oldcf=e.get(ref,'CFrame');oldsize=unvector(e.get(ref,'size'));oldpos=unvector(oldcf[1])
  if ref not in changes:changes[ref]={'path':small['path'],'ref':ref,'world':small['world'],'beforePosition':oldpos,'beforeSize':oldsize}
  small[side][axis]=bound
  pos=[(small['lo'][k]+small['hi'][k])/2 for k in range(3)];extent=[small['hi'][k]-small['lo'][k]for k in range(3)]
  m=small['matrix'];sz=[sum(abs(m[k*3+j])*extent[k]for k in range(3))for j in range(3)]
  e.set(ref,'CFrame',(oldcf[0],vector(*pos)));e.set(ref,'size',vector(*sz))
  changes[ref].update(afterPosition=pos,afterSize=sz)
  details.append({'part':ref,'against':cover['ref'],'againstPath':cover['path'],'faceAxis':face,'faceSign':sign,'trimAxis':axis,'trimStuds':amount,'cause':'Coplanar exposed block faces; removed overlap slab is fully covered by adjoining Part'})
 record={'inputSha256':EXPECTED,'changedParts':list(changes.values()),'seams':details,'worldCounts':dict(collections.Counter(v['world']for v in changes.values())),
  'deferredReasons':dict(rejected),'unknownGeometryNotModified':dict(skipped),'studioStarted':False,'playTested':False,'appearanceVerified':False}
 if args.write:
  assert changes,'No proved edits'
  result,_=e.build();before,after=Editor(raw),Editor(result);assert before.parents==after.parents
  for key,col in before.columns.items():
   if key not in e.changed:assert before.doc.chunks[col[0]][1]==after.doc.chunks[after.columns[key][0]][1]
   else:
    cid,name=key;assert name in('CFrame','size')
    for ref,val in before.col(cid,name)[3].items():assert after.get(ref,name)==(e.get(ref,name)if ref in changes else val)
  assert canonicalize(result)[0]==result;Document(result).assert_studio_bounds();assert PLACE.read_bytes()==raw
  with PLACE.open('r+b')as stream:stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
  assert PLACE.read_bytes()==result
  record.update(outputSha256=hashlib.sha256(result).hexdigest(),writtenAndReread=True,allOtherPropertiesSourcesParentsUniqueIdsUnchanged=True)
  out=ROOT/'reports/MapSurfaceSeams_20261021';out.mkdir(exist_ok=True);(out/'Writeback.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf8')
 print(json.dumps({k:v for k,v in record.items()if k not in('changedParts','seams')},indent=2))
 print('Changed:',[(p['world'],p['ref'],p['path'])for p in changes.values()])


if __name__=='__main__':main()
