"""Persist Trophy choices in the current place, preserving unrelated rows."""
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess
from rbxl_rows import Editor, s, string, vector, unvector, f, i, udim2
from rbxl_geometry import matrix, point, transform

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '4c374c4af576e427ba84af9a81d7c222928159419fb29650a77822aed0b6699d'
FILES = {
 'ServerScriptService.Services.TrophyRewardService': 'src/ServerScriptService/Services/TrophyRewardService.luau',
 'ServerScriptService.Services.GamePassService': 'src/ServerScriptService/Services/GamePassService.luau',
 'StarterPlayer.StarterPlayerScripts.Combat.CombatClient': 'src/StarterPlayer/StarterPlayerScripts/Combat/CombatClient.client.luau',
}

def main():
 raw=PLACE.read_bytes()
 assert hashlib.sha256(raw).hexdigest()==EXPECTED, 'Place changed since inspection'
 e=Editor(raw);e.path=functools.lru_cache(None)(e.path)
 paths={e.path(r):r for r in e.parents}
 sources={}
 for path,relative in FILES.items():
  ref=paths[path];old=string(e.get(ref,'Source'),0)[0]
  baseline=subprocess.check_output(['git','show','HEAD:'+relative],cwd=ROOT)
  assert old.replace(b'\r\n',b'\n')==baseline.replace(b'\r\n',b'\n'),path
  new=(ROOT/relative).read_text(encoding='utf8').encode()
  subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/relative)],check=True,stdout=subprocess.DEVNULL)
  e.set(ref,'Source',s(new));sources[path]=hashlib.sha256(new).hexdigest()

 def new(kind,parent,name,props):
  cid=next(c for c,(n,_) in e.doc.classes.items() if n==kind)
  ref,_=e.clone(e.doc.classes[cid][1][0],parent,False)
  # No inherited external references, tags, UI state, or localization captures.
  for (c,p),col in e.columns.items():
   if c==cid and col[1]==19:e.set(ref,p,-1)
  e.set(ref,'Name',s(name));e.set(ref,'Tags',bytes(4))
  for p,v in props.items():e.set(ref,p,v)
  return ref

 def board(handle,text):
  gui=new('BillboardGui',handle,'TrophyRewardBillboard',dict(
   Adornee=handle,Active=b'\0',AlwaysOnTop=b'\1',Enabled=b'\1',AutoLocalize=b'\1',
   Size=udim2(0,176,0,51),StudsOffset=vector(0,0,0),StudsOffsetWorldSpace=vector(0,12.15,0),
   ExtentsOffset=vector(0,0,0),ExtentsOffsetWorldSpace=vector(0,0,0),SizeOffset=vector(0,0),
   LightInfluence=f(0),MaxDistance=f(60)))
  common=dict(AnchorPoint=vector(0,0),Position=udim2(0,0,0,0),Size=udim2(1,0,1,0),
   AutomaticSize=bytes(4),Rotation=f(0),Visible=b'\1',ClipsDescendants=b'\0',
   ZIndex=i(1),BorderSizePixel=i(0),AutoLocalize=b'\1')
  panel=new('Frame',gui,'Panel',dict(common,BackgroundColor3=vector(1,224/255,112/255),BackgroundTransparency=f(.18),Style=bytes(4)))
  new('UICorner',panel,'UICorner',{p:f(0)+i(14) for p in ['TopLeftRadius','TopRightRadius','BottomLeftRadius','BottomRightRadius']})
  new('UIStroke',panel,'UIStroke',dict(Color=vector(83/255,49/255,12/255),Thickness=f(3),Transparency=f(0),Enabled=b'\1'))
  icon=paths['StarterGui.StrengthGui.WinLabel.TrophyIcon']
  new('ImageLabel',panel,'TrophyIcon',dict(common,Position=udim2(0,8,0,6),Size=udim2(0,40,0,40),
   BackgroundTransparency=f(1),Image=e.get(icon,'Image'),ImageColor3=vector(1,1,1),ImageTransparency=f(0),
   ImageRectOffset=vector(0,0),ImageRectSize=vector(0,0),ScaleType=(3).to_bytes(4,'big')))
  label=new('TextLabel',panel,'Amount',dict(common,Position=udim2(0,52,0,3),Size=udim2(1,-58,1,-6),
   BackgroundTransparency=f(1),Text=s(text),FontFace=s('rbxasset://fonts/families/FredokaOne.json')+(400).to_bytes(2,'little')+b'\0'+s(''),
   TextScaled=b'\1',TextWrapped=b'\1',TextColor3=vector(1,1,1),TextStrokeColor3=vector(67/255,38/255,7/255),
   TextStrokeTransparency=f(0),TextTransparency=f(0),MaxVisibleGraphemes=i(-1),RichText=b'\0',
   TextXAlignment=(2).to_bytes(4,'big'),TextYAlignment=(1).to_bytes(4,'big'),
   LocalizationMatchIdentifier=s(''),LocalizationMatchedSourceText=s('')))
  new('UITextSizeConstraint',label,'UITextSizeConstraint',dict(MinTextSize=i(14),MaxTextSize=i(27)))

 template=paths['ReplicatedStorage.UI.Templates.TrophyRewardTemplate']
 template_handle=paths['ReplicatedStorage.UI.Templates.TrophyRewardTemplate.Handle']
 handle_size=unvector(e.get(template_handle,'size'))
 template_pos=unvector(e.get(template_handle,'CFrame')[1])
 placements=[]
 rewards={1:[1,3,7,15,30,50,75,150,500,1000]}
 # World2 amounts are parsed from the current config, not copied from historical rewards.
 config=string(e.get(paths['ReplicatedStorage.Config.World2GameplayConfig'],'Source'),0)[0].decode()
 import re
 rewards[2]=[int(x) for x in re.findall(r'WinReward\s*=\s*(\d+)',config)]
 assert len(rewards[2])==10
 for world,mapname in [(1,'GeneratedMap'),(2,'World2Map')]:
  for stage in range(1,11):
   path=f'Workspace.{mapname}.BattleCorridor.Stage{stage:02d}'
   floor=paths[path+f'.Stage{stage}.5.Floor']
   rot,pos=e.get(floor,'CFrame');pos=unvector(pos);size=unvector(e.get(floor,'size'))
   assert matrix(rot)==[1,0,0,0,1,0,0,0,1], 'Review rotated corridor before placement'
   boss=unvector(e.get(paths[path+f'.Stage{stage}.5.EnemySpawn'],'CFrame')[1])
   assert boss[2]>pos[2], 'Entry-to-Boss must be +Z; right is -X'
   inset=max(handle_size[0]/2+4,size[0]*.12)
   offset=size[0]/2-inset
   assert 2*offset>handle_size[0]+1.5
   for double,name in [(False,'TrophyNormalButton'),(True,'TrophyDoubleButton')]:
    existing=paths.get(path+'.'+name)
    if existing is not None:
     model=existing;mapping=None
     handle=paths[path+'.'+name+'.Handle']
    else:
     model,mapping=e.clone(template,paths[path]);handle=mapping[template_handle]
     e.set(model,'Name',s(name))
    target=[pos[0]+(offset if double else -offset),pos[1]+size[1]/2+handle_size[1]/2+.03,pos[2]]
    transform(e,e.subtree(model),[1,0,0,0,1,0,0,0,1],template_pos if mapping else unvector(e.get(handle,'CFrame')[1]),target)
    e.set(handle,'Anchored',b'\1');e.set(handle,'CanTouch',b'\1');e.set(handle,'CanQuery',b'\1')
    if mapping:board(handle,'\u00d72 Wins' if double else f'+{rewards[world][stage-1]} Win')
    placements.append(dict(path=path+'.'+name,position=target,size=handle_size,created=mapping is not None))
 result,_=e.build()
 after=Editor(result)
 # Compare every existing property row; only the three requested Sources may change.
 allowed={paths[p] for p in FILES}
 before=Editor(raw)
 for (cid,name),col in before.columns.items():
  if (cid,name) not in e.changed:
   assert before.doc.chunks[col[0]][1]==after.doc.chunks[after.columns[cid,name][0]][1]
   continue
  for ref,value in before.col(cid,name)[3].items():
   assert after.get(ref,name)==(e.get(ref,name) if name=='Source' and ref in allowed else value),(ref,name)
 assert all(after.parents[r]==parent for r,parent in before.parents.items())
 assert PLACE.read_bytes()==raw,'Concurrent owner edit'
 with PLACE.open('r+b') as stream:
  stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
 saved=PLACE.read_bytes();assert saved==result
 reread=Editor(saved);reread.path=functools.lru_cache(None)(reread.path)
 savedpaths={reread.path(r):r for r in reread.parents}
 for path,relative in FILES.items():
  assert string(reread.get(savedpaths[path],'Source'),0)[0]==(ROOT/relative).read_text(encoding='utf8').encode()
 for row in placements:
  handle=savedpaths[row['path']+'.Handle']
  assert unvector(reread.get(handle,'size'))==row['size']
  assert all(abs(a-b)<.001 for a,b in zip(unvector(reread.get(handle,'CFrame')[1]),row['position']))
  label=savedpaths[row['path']+'.Handle.TrophyRewardBillboard.Panel.Amount']
  if row['path'].endswith('TrophyDoubleButton'):assert string(reread.get(label,'Text'),0)[0].decode()=='\u00d72 Wins'
 report=dict(inputSha256=EXPECTED,outputSha256=hashlib.sha256(saved).hexdigest(),sources=sources,buttons=placements,
  unrelatedExistingRowsUnchanged=True,syntaxCompiled=True,writtenAndReread=True,runtimeTested=False)
 out=ROOT/'reports/TrophyChoice_20261021';out.mkdir(exist_ok=True)
 (out/'Writeback.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
 print(json.dumps({k:v for k,v in report.items() if k!='buttons'},indent=2));print('Saved buttons:',len(placements))

if __name__=='__main__':main()
