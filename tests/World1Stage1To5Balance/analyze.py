"""Analyze native earned-route events; injected boundary tests are excluded."""
from pathlib import Path
import json,csv,statistics,collections
root=Path(__file__).resolve().parents[2]
out=root/'reports/World1Stage1To5Balance_20261112'
runs=[];event_rows=[];funnel_rows=[]
for file in sorted(out.glob('native_*_*.json')):
 if not any(s in file.name for s in ['before','after']):continue
 data=json.loads(file.read_text(encoding='utf8'))
 if 'Runs' not in data:continue
 for run in data['Runs']:
  mode=run['Mode'];rep=run['Repetition'];variant=run['Variant'];events=run['Events']
  # First cohort predates the explicit UserId observer; its fixed sorted3 mapping is recorded.
  uid=run.get('UserId',{'Auto':-3,'Manual':-2,'Mixed':-1}[mode])
  joined=(run.get('Joined')or{}).get('Time')
  if joined is None and variant=='Before' and rep==1:
   audit=json.loads((out/'before_1_acquisition.json').read_text(encoding='utf8'))
   values=json.loads(audit['content'][0]['text'])
   joined=next(x['Acquisition']['StrengthNow']for x in values if x['UserId']==uid)
  finish={};cumulative={};gear=[];parts=collections.defaultdict(float);active={};stage_gear={};rebirths=[]
  activity=collections.defaultdict(float);activity_since=None;activity_kind=None
  end5=next((e['Seconds']for e in events if e['Kind']=='Stage5RouteCompleted'),None)
  stage_attempts=collections.Counter();deaths=0
  for e in events:
   # Activity can be observed between profile readiness and the common start.
   kind=e['Kind'];sec=e.get('Seconds',e['Time']-data['Started']);state=e['State'];detail=e.get('Details')
   event_rows.append([variant,rep,mode,uid,kind,e['Time'],sec,e['Time']-joined if joined else '',state.get('Strength'),state.get('Level'),state.get('Progress'),state.get('Curve','unversioned baseline'),state.get('Rebirth'),state.get('EquippedDumbbell'),state.get('Health'),json.dumps(detail,ensure_ascii=False)])
   if kind.startswith('StageFightEnd'):
    stage=int(kind.removeprefix('StageFightEnd'));finish.setdefault(stage,sec);cumulative.setdefault(stage,e['Time']-joined if joined else None)
    stage_gear.setdefault(stage,state.get('EquippedDumbbell'))
   if kind=='Activity' and end5 is not None and sec<=end5:
    moment=max(0,sec)
    if activity_since is not None:activity[activity_kind]+=moment-activity_since
    activity_since=moment;activity_kind=detail
   if kind.startswith('Rebirth')and kind[7:].isdigit():rebirths.append({'Count':state['Rebirth'],'Seconds':sec,'Curve':state.get('Curve')})
   if kind=='DumbbellEquipped':gear.append(str(detail))
   if kind=='Death':deaths+=1
   if kind=='ExpeditionStart':stage_attempts[detail['Goal']]+=1
   if kind=='TrainStart':active['Training']=sec
   if kind=='TrainEnd' and 'Training'in active:parts['Training']+=sec-active.pop('Training')
   if kind=='MergeStart':active['MergeEquip']=sec
   if kind=='MergeEnd' and 'MergeEquip'in active:
    elapsed=sec-active.pop('MergeEquip');parts['MergeEquip']+=elapsed
    if 'Training'in active:parts['MergeInsideTraining']+=elapsed
   if kind=='RebirthRequested':active['Rebirth']=sec
   if (kind.startswith('Rebirth')and kind[7:].isdigit()or kind=='RebirthDeferred')and'Rebirth'in active:parts['Rebirth']+=sec-active.pop('Rebirth')
   if kind.startswith('TrophyApproach'):active['TrophyReturn']=sec
   if kind.startswith('TrophyReturned')and'TrophyReturn'in active:parts['TrophyReturn']+=sec-active.pop('TrophyReturn')
  if activity_since is not None:activity[activity_kind]+=end5-activity_since
  row={'Variant':variant,'Repetition':rep,'Mode':mode,'Success':run.get('Success',False),'EquipmentRoute':' -> '.join(gear),'Deaths':deaths,'Retries':sum(max(0,n-1)for n in stage_attempts.values()),'JoinPrecision':'acquisition whole-second proxy'if variant=='Before'and rep==1 else 'observed server PlayerAdded'if not(run.get('Joined')or{}).get('Late')else 'observer attached after join','InitialAuto':next((e.get('Details',{}).get('InitialAuto')for e in events if e['Kind']=='Operable'),None),'Rebirths':json.dumps(rebirths)}
  row['OperableFromJoin']=next((e['Time']-joined for e in events if e['Kind']=='Operable'),None)if joined else None
  row['FirstReadyFromJoin']=run['FirstReadyAt']-joined if run.get('FirstReadyAt')and joined else None
  prev=0
  for stage in range(1,6):
   current=finish.get(stage)
   row[f'Stage{stage}Segment']=current-prev if current is not None else None
   row[f'Stage{stage}FromOperable']=current
   row[f'Stage{stage}FromJoin']=cumulative.get(stage)
   row[f'Stage{stage}Dumbbell']=stage_gear.get(stage)
   if current is not None:prev=current
  a=next((e['Seconds']for e in events if e['Kind']=='Stage6FirstWallStart'),None)
  b=next((e['Seconds']for e in events if e['Kind']=='Stage6FirstWallEnd'),None)
  row['Stage6FirstWall']=b-a if a is not None and b is not None else None
  row['CompleteSeconds']=next((e['Seconds']for e in events if e['Kind']=='Complete'),None)
  row.update(parts)
  row['TrainingExcludingMerge']=parts['Training']-parts['MergeInsideTraining']
  for category,seconds in activity.items():row['ExclusiveToStage5_'+category]=seconds
  runs.append(row)
  for e in data['Analytics']:
   if e['UserId']==uid and e['Kind']=='Funnel':funnel_rows.append([variant,rep,mode,e['Name'],e['Step'],e['StepName']])
def table(name,rows,header=None):
 with (out/name).open('w',encoding='utf8',newline='')as f:
  if header:
   w=csv.writer(f);w.writerow(header);w.writerows(rows)
  elif rows:
   fields=list(dict.fromkeys(k for row in rows for k in row));w=csv.DictWriter(f,fields);w.writeheader();w.writerows(rows)
table('individual_runs.csv',runs)
table('route_events.csv',event_rows,['Variant','Repetition','Mode','SyntheticUserId','Event','ServerTime','SecondsFromStart','SecondsFromJoin','Strength','LV','Progress','Curve','Rebirth','Dumbbell','HP','Details'])
table('funnel_outputs.csv',funnel_rows,['Variant','Repetition','Mode','Funnel','Step','StepName'])
aggregates=[]
for mode in ['Manual','Auto','Mixed']:
 for stage in range(1,6):
  groups={v:[r for r in runs if r['Mode']==mode and r['Variant']==v and r['Success']and r.get(f'Stage{stage}FromOperable')is not None]for v in ['Before','After']}
  row={'Mode':mode,'Stage':stage,'BeforeN':len(groups['Before']),'AfterN':len(groups['After'])}
  for kind in ['Segment','FromOperable']:
   for v,items in groups.items():row[v+kind]=statistics.mean(r[f'Stage{stage}{kind}']for r in items)if items else None
   a,b=row['Before'+kind],row['After'+kind]
   row['SpeedRatio'+kind]=a/b if a is not None and b else None
   row['Reached1_5'+kind]=(a/b>=1.5)if a is not None and b else None
  aggregates.append(row)
table('aggregates.csv',aggregates)
strata=[]
for mode in ['Manual','Auto','Mixed']:
 for route in sorted({r['EquipmentRoute']for r in runs if r['Mode']==mode}):
  groups={v:[r for r in runs if r['Mode']==mode and r['Variant']==v and r['EquipmentRoute']==route and r['Success']]for v in ['Before','After']}
  row={'Mode':mode,'EquipmentRoute':route,'BeforeN':len(groups['Before']),'AfterN':len(groups['After'])}
  for v,items in groups.items():row[v+'Stage5']=statistics.mean(r['Stage5FromOperable']for r in items)if items else None
  a,b=row['BeforeStage5'],row['AfterStage5'];row['SpeedRatio']=a/b if a is not None and b else None
  strata.append(row)
table('equipment_strata.csv',strata)
print(json.dumps({'Routes':len(runs),'Successful':sum(r['Success']for r in runs),'Events':len(event_rows),'FunnelEvents':len(funnel_rows)},indent=2))
