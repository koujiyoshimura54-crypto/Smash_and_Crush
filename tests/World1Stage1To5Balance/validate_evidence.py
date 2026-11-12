"""Validate recorded native evidence; this is not another simulated play count."""
from pathlib import Path
import json,collections
root=Path(__file__).resolve().parents[2]/'reports/World1Stage1To5Balance_20261112'
checks=0;runs=[];streams=[];sessions=[];interleavings=[];failures=[];context={}
existing=('MTF_Entry_v1','MTF_FirstCombat_v1','MTF_FirstOreMerge_v1','MTF_FirstStage2Combat_v1')
def check(v,label):
 global checks
 checks+=1
 if not v:failures.append({**context,'Check':label})
for file in sorted(root.glob('native_*_*.json')):
 if not any(s in file.name for s in ['before','after']):continue
 data=json.loads(file.read_text(encoding='utf8'))
 if 'Runs'not in data:continue
 for r in data['Runs']:
  context={'File':file.name,'Variant':r['Variant'],'Mode':r['Mode'],'Repetition':r.get('Repetition'),'UserId':r.get('UserId')}
  runs.append(r);uid=r.get('UserId',{'Auto':-3,'Manual':-2,'Mixed':-1}[r['Mode']])
  check(r['Initial']['Strength']==0 and r['Initial']['Level']==1 and r['Initial']['Progress']==0,'fresh route')
  check(r['Initial']['Health']==100,'unchanged initial Player HP')
  if r['Variant']=='After':check(r['Initial']['Curve']==2,'fresh curve2')
  events=r['Events'];check(r['Success'],'route success')
  check(next(e['Details']['InitialAuto']for e in events if e['Kind']=='Operable')is False,'initial Auto OFF')
  check(all(a['Time']<=b['Time']for a,b in zip(events,events[1:])),'monotonic observation')
  hp=[200,2250,12500,30000,75000]if r['Variant']=='Before'else[200,1800,10000,25000,70000]
  for stage in range(1,6):
   check(any(e['Kind']==f'StageFightEnd{stage}'for e in events),'stage completion')
   damage=next((e for e in events if e['Kind']==f'BossDamage{stage}'),None)
   check(damage is not None and damage['Details']['Before']==hp[stage-1],'native initial Boss HP and wall/Boss boundary')
  check(any(e['Kind']=='Stage6FirstWallEnd'for e in events),'stage6 wall')
  funnel=[e for e in data['Analytics']if e['UserId']==uid and e['Kind']=='Funnel']
  session={e['Session']for e in funnel}
  check(len(session)==1 and all(session),'same participation GUID across funnels')
  sessions.extend(session)
  check(all(e['Fields']['CustomField01']=='PlaceVersion:577' and e['Fields']['CustomField03']=='Normal' for e in funnel),'unchanged version/normal fields')
  check(all(e['Fields']['CustomField02']==('AllSessions' if e['Name']=='MTF_Entry_v1' else 'NewFirstSession')for e in funnel),'unchanged cohort fields')
  stream=[(e['Name'],e['Step'],e['StepName'])for e in funnel]
  check(len(stream)==len(set(stream)),'no repeated funnel step')
  for name,length in [('MTF_Entry_v1',3),('MTF_FirstCombat_v1',6),('MTF_FirstOreMerge_v1',1),('MTF_FirstStage2Combat_v1',5)]:
   check([e[1]for e in stream if e[0]==name]==list(range(1,length+1)),name+' observed prefix')
  # Death rows depend on measured natural deaths; Back never occurs in this route.
  check([e[1]for e in stream if e[0]=='MTF_FirstStage2BossBack_v1']==[1],'no false Trophy-as-Back')
  if not any(e['Kind']=='Death'for e in events):check([e[1]for e in stream if e[0]=='MTF_FirstStage2BossDeath_v1']==[1],'no false death')
  # Independent funnels can naturally interleave: time rewards can make Ore
  # eligible before Stage1 combat completes. Preserve order WITHIN each funnel.
  interleavings.append(tuple(e for e in stream if e[0]in existing))
  streams.append(tuple((name,tuple((e[1],e[2])for e in stream if e[0]==name))for name in existing))
counts=collections.Counter((r['Variant'],r['Mode'])for r in runs)
context={'Scope':'all retained native routes'}
for variant in ['Before','After']:
 for mode in ['Manual','Auto','Mixed']:check(counts[(variant,mode)]>=4,f'{variant} {mode} four retained samples')
check(len(set(streams))==1,'existing four per-funnel observed steps match')
check(len(sessions)==len(set(sessions)),'independent new participation GUIDs')
result={'Checks':checks,'Passed':not failures,'Failures':failures,'Routes':len(runs),'Counts':{v+'/'+m:n for (v,m),n in counts.items()},'ExistingFourPerFunnelObservedStepsIdentical':len(set(streams))==1,'NaturalCrossFunnelInterleavings':len(set(interleavings)),'Kind':'Assertions over recorded native evidence; not additional Play runs; failures are retained rather than backfilled'}
(root/'evidence_validation.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result,indent=2))
raise SystemExit(0 if result['Passed']else 1)
