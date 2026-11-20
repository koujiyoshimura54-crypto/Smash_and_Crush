"""Build dependency-isolated Edit fixtures from preserved Studio and this change.
No DataStore, purchases, ads, notifications, Play, or executable service startup.
"""
import json, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/'reports/RewardedStrengthBoostRecovery_20261120'
BASE=json.loads((REPORT/'before/manifest.json').read_text(encoding='utf-8'))['RemoteBase']
BEFORE={r['Path']:r['Source'] for r in json.loads((REPORT/'before/studio.json').read_text(encoding='utf-8'))['Targets']}
PATHS={
 'Config':'src/ReplicatedStorage/Config/RewardedStrengthBoostConfig.luau',
 'Controller':'src/ServerScriptService/Services/RewardedStrengthBoostController.luau',
 'Client':'src/ReplicatedStorage/Modules/RewardedStrengthBoostClient.luau',
 'State':'src/ServerScriptService/Services/RewardedStrengthBoostState.luau',
 'Persistence':'src/ServerScriptService/Services/RewardedStrengthBoostPersistence.luau',
 'Style':'src/ReplicatedStorage/Config/RewardedStrengthBoostStyle.luau',
 'HUDStyle':'src/ReplicatedStorage/Config/StrengthHUDStyle.luau',
 'Visual':'src/ReplicatedStorage/Modules/RewardedStrengthBoostPresentation.luau',
 'Calculation':'src/ReplicatedStorage/Modules/StrengthCalculation.luau',
}
def base(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT).decode('utf-8-sig')
def sources(suite):
 if suite=='training':
  p=BEFORE['ServerScriptService.Services.PlayerDataService']
  spec=base('tests/StudioPremiumTreadmillEvent.spec.luau')
  marker=' -- Exact AddStrengthGain and RecordStrengthGain bodies from PlayerDataService.'
  assert spec.count(marker)==1
  spec=spec.replace(marker,' local boostState=assert(loadstring(Sources.BoostState))()\n local boostConfig=assert(loadstring(Sources.BoostConfig))()\n runSource("BoostGetter",Sources.BoostGetter,{PlayerDataService=data,sessions=sessions,BoostState=boostState,BoostConfig=boostConfig,os={time=function()return math.floor(now)end}})\n'+marker)
  marker=' -- No pending training workers or modified prototype values at handoff.'
  assert spec.count(marker)==1
  spec=spec.replace(marker,base('tests/RewardedStrengthBoost.training.spec.luau')+'\n'+marker)
  runner=base('reports/PremiumTreadmillPublicEvent_20261119/edit_test_runner.luau')
  at=runner.index('local test=assert(loadstring(TestSource')
  extra='S.BoostState=game.ServerScriptService.Services.RewardedStrengthBoostState.Source\nS.BoostConfig=game.ReplicatedStorage.Config.RewardedStrengthBoostConfig.Source\nS.BoostGetter='+json.dumps(p[p.index('function PlayerDataService.GetStrengthBoostBonus'):p.index('function PlayerDataService.Get(player)')])+'\n'
  return {'Runner':'local Suite="integration"\nlocal TestSource='+json.dumps(spec,ensure_ascii=False)+'\n'+runner[:at]+extra+runner[at:]}
 if suite=='save':
  paths={'Config':'src/ReplicatedStorage/Config/EngagementConfig.luau','State':'src/ServerScriptService/Services/OfflineNotificationState.luau','RewardConfig':'src/ReplicatedStorage/Config/StrengthRewardConfig.luau','RewardState':'src/ServerScriptService/Services/StrengthRewardState.luau'}
  data={k:base(v) for k,v in paths.items()}
  p=BEFORE['ServerScriptService.Services.PlayerDataService']
  data['PlayerData']=p[p.index('function PlayerDataService.Save('):p.index('-- Called only by EnemyManager',p.index('function PlayerDataService.Save('))]+'-- Called only by EnemyManager'
  spec=base('tests/EngagementSaveHook.spec.luau')
  spec=spec.replace('local raw=copy(d);raw.SessionOwnerToken="one"','local raw=copy(d);raw.SessionOwnerToken="one"\n d.StrengthBoost={ExpiresAt=100,Receipts={}}\n raw.StrengthBoost={ExpiresAt=200,Receipts={durable=true}}')
  spec=spec.replace('eq(raw.Strength,10000);','eq(raw.StrengthBoost.ExpiresAt,200);eq(raw.StrengthBoost.Receipts.durable,true);\n eq(raw.Strength,10000);')
  data['Test']=spec
  return data
 data={k:((ROOT/v).read_text(encoding='utf-8-sig') if k in ('Config','Controller','Client','Style','Visual') else base(v)) for k,v in PATHS.items()}
 p=BEFORE['ServerScriptService.Services.PlayerDataService']
 data['Commit']=p[p.index('function PlayerDataService.CommitStrengthBoostReceipt'):p.index('function PlayerDataService.CommitStrengthOperation')]
 data['Bonus']=p[p.index('function PlayerDataService.GetStrengthBoostBonus'):p.index('function PlayerDataService.Get(player)')]
 data['ScheduleRetry']=p[p.index('local ITEM_MUTATION_RETRY_DELAYS'):p.index('-- Size selection uses the existing write gate')]
 o=base('src/ServerScriptService/Services/PlayerDataOwnership.luau');data['OwnedUpdate']=o[o.index('function M.Update('):o.rindex('return M')]
 sm=base('src/ServerScriptService/Services/StrengthManager.luau')
 data['Training']=sm[sm.index('function StrengthManager.AddStrength('):sm.index('function StrengthManager.ResetStrength(')]
 data['Direct']=sm[sm.index('function StrengthManager.AddRewardStrength('):sm.index('-- Normal equipment reference')]
 data['BeforeController']=BEFORE['ServerScriptService.Services.RewardedStrengthBoostController']
 data['BeforeClient']=BEFORE['ReplicatedStorage.Modules.RewardedStrengthBoostClient']
 data['Test']=base('tests/RewardedStrengthBoost.core.spec.luau') if suite=='core' else (ROOT/f'tests/RewardedStrengthBoostRecovery.{suite}.spec.luau').read_text(encoding='utf-8')
 return data
if __name__=='__main__':
 sys.stdout.buffer.write(json.dumps(sources(sys.argv[1]),ensure_ascii=False).encode('utf-8'))
