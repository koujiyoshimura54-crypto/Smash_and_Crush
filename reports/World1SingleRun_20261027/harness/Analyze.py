import json
from pathlib import Path
REPORT=Path(__file__).resolve().parents[1]
events=[json.loads(x)for x in (REPORT/'run01/events.jsonl').read_text(encoding='utf-8').splitlines()]
r=json.loads((REPORT/'run01/finished.json').read_text(encoding='utf-8'))
assert r.get('FinishUTC') and len(r['FirstClears'])==10
starts=[e for e in events if e['Kind']=='Start'];finishes=[e for e in events if e['Kind']=='Finished']
assert len(starts)==len(finishes)==1
assert [e['Index'] for e in events]==list(range(1,len(events)+1))
duration=r['FinishUTC']-r['StartUTC']
assert abs(sum(r['Totals'].values())-duration)<1
assert abs(r['FirstClears'][9]['Elapsed']-duration)<1
encounters=[];active={};pending={}
def sample(row,p):
 row['MotionSamples']+=1;row['HealthSamples'].append(p['Health'])
 y=p['Position'][1];row['MinRootY']=min(row.get('MinRootY',y),y);row['MaxRootY']=max(row.get('MaxRootY',y),y)
for e in events:
 p=e.get('Payload',{})
 if e['Kind']=='ClientEvent'and isinstance(p,dict):
  if p.get('Type')=='ObservedCombat':
   d=p['Data'];stage=d.get('Stage')
   if d.get('Type')=='BossInitialize':
    row={'Stage':stage,'Start':e['Elapsed'],'SpawnGeneration':d.get('SpawnGeneration'),'Result':'Unfinished','HealthSamples':[],'MotionSamples':0,'LastAttack':0,'JumpCalibrations':[]}
    encounters.append(row);active[stage]=row
    if stage in pending:sample(row,pending.pop(stage))
   elif stage in active:
    row=active[stage]
    if d.get('Type')=='BossGauge':row['LastAttack']=d.get('Attack',row['LastAttack']);row['LastBossHP']=d.get('Current')
    if d.get('Type')=='BossResult':row['Result']=d.get('Result');row['End']=e['Elapsed']
  elif p.get('Type')=='KiteObservation':
   if p.get('Elapsed',1)<.05:pending[p['Stage']]=p
   elif p.get('Stage')in active:sample(active[p['Stage']],p)
  elif p.get('Type')=='JumpCalibration'and p.get('Stage')in active:active[p['Stage']]['JumpCalibrations'].append({'Elapsed':e['Elapsed'],'Health':p['Health'],'Delay':p['Delay']})
 elif e['Kind']=='Death'and p.get('Stage')in active:
  row=active[p['Stage']];row['Result']='Death';row['End']=e['Elapsed'];row['HealthSamples'].append(0)
metrics={'Complete':True,'BenchmarkRuns':len(starts),'ElapsedSeconds':duration,'TimeFormat':'real elapsed; includes reasoning, blocked input and concurrent growth','RawCategoriesSeconds':r['Totals'],'RawCategoriesMinutes':{k:v/60 for k,v in r['Totals'].items()},'Deaths':r['Snapshot']['Deaths'],'FirstClearedStages':len(r['FirstClears']),'Events':len(events),'FinishedUTC':r['FinishUTC'],'UnpaidMultipliers':r['Snapshot']['Multipliers'],'FinalEquipment':{'Dumbbell':r['Snapshot']['EquippedDumbbell'],'Aura':r['Snapshot']['Aura'],'Items':r['Snapshot']['EquippedItems'],'Pets':r['Snapshot']['Pets']},'Encounters':encounters,'Assertions':['One Start/Finished','Ten first clears','Contiguous event indexes','Raw category sum matches real duration within1s','Final first-clear elapsed matches finish within1s']}
(REPORT/'metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(metrics,ensure_ascii=False))
