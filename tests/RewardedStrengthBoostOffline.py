"""Compile current sources into an Edit-only fixture. No stores, ads, purchases or Play."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PATHS={
    'Config':'src/ReplicatedStorage/Config/RewardedStrengthBoostConfig.luau',
    'State':'src/ServerScriptService/Services/RewardedStrengthBoostState.luau',
    'Persistence':'src/ServerScriptService/Services/RewardedStrengthBoostPersistence.luau',
    'Controller':'src/ServerScriptService/Services/RewardedStrengthBoostController.luau',
    'Calculation':'src/ReplicatedStorage/Modules/StrengthCalculation.luau',
    'Style':'src/ReplicatedStorage/Config/RewardedStrengthBoostStyle.luau',
    'HUDStyle':'src/ReplicatedStorage/Config/StrengthHUDStyle.luau',
    'Visual':'src/ReplicatedStorage/Modules/RewardedStrengthBoostPresentation.luau',
    'Client':'src/ReplicatedStorage/Modules/RewardedStrengthBoostClient.luau',
}
def build(suite):
    sources={k:(ROOT/v).read_text(encoding='utf-8-sig') for k,v in PATHS.items()}
    p=(ROOT/'src/ServerScriptService/Services/PlayerDataService.luau').read_text(encoding='utf-8-sig')
    if suite=='save':
        from EngagementOffline import PATHS as EP
        data={k:(ROOT/EP[v]).read_text(encoding='utf-8-sig') for k,v in {'Config':'Config','State':'State','RewardConfig':'RewardConfig','RewardState':'RewardState'}.items()}
        data['PlayerData']=p[p.index('function PlayerDataService.Save('):p.index('-- Called only by EnemyManager',p.index('function PlayerDataService.Save('))]+'-- Called only by EnemyManager'
        spec=(ROOT/'tests/EngagementSaveHook.spec.luau').read_text(encoding='utf-8-sig')
        spec=spec.replace('local raw=copy(d);raw.SessionOwnerToken="one"','local raw=copy(d);raw.SessionOwnerToken="one"\n d.StrengthBoost={ExpiresAt=100,Receipts={}}\n raw.StrengthBoost={ExpiresAt=200,Receipts={durable=true}}')
        spec=spec.replace('eq(raw.Strength,10000);','eq(raw.StrengthBoost.ExpiresAt,200);eq(raw.StrengthBoost.Receipts.durable,true);\n eq(raw.Strength,10000);')
        data['Test']=spec
        encoded=json.dumps(json.dumps(data,ensure_ascii=False),ensure_ascii=False)
        return 'assert(not game:GetService("RunService"):IsRunning())\nlocal H=game:GetService("HttpService")\nlocal s=H:JSONDecode('+encoded+')\nreturn H:JSONEncode(assert(loadstring(s.Test))()(s))'
    sources['Commit']=p[p.index('function PlayerDataService.CommitStrengthBoostReceipt'):p.index('function PlayerDataService.CommitStrengthOperation')]
    sources['Bonus']=p[p.index('function PlayerDataService.GetStrengthBoostBonus'):p.index('function PlayerDataService.Get(player)')]
    o=(ROOT/'src/ServerScriptService/Services/PlayerDataOwnership.luau').read_text(encoding='utf-8-sig')
    sources['OwnedUpdate']=o[o.index('function M.Update('):o.rindex('return M')]
    s=(ROOT/'src/ServerScriptService/Services/StrengthManager.luau').read_text(encoding='utf-8-sig')
    sources['Training']=s[s.index('function StrengthManager.AddStrength('):s.index('function StrengthManager.ResetStrength(')]
    sources['Direct']=s[s.index('function StrengthManager.AddRewardStrength('):s.index('-- Normal equipment reference')]
    if suite=='training':
        # Reuse the established dependency-isolated treadmill fixture, without editing its historical checks.
        spec=(ROOT/'tests/StudioPremiumTreadmillEvent.spec.luau').read_text(encoding='utf-8-sig')
        marker=' -- Exact AddStrengthGain and RecordStrengthGain bodies from PlayerDataService.'
        spec=spec.replace(marker,''' local boostState=assert(loadstring(Sources.BoostState))()
 local boostConfig=assert(loadstring(Sources.BoostConfig))()
 runSource("BoostGetter",Sources.BoostGetter,{PlayerDataService=data,sessions=sessions,BoostState=boostState,BoostConfig=boostConfig,os={time=function()return math.floor(now)end}})
'''+marker)
        extension=(ROOT/'tests/RewardedStrengthBoost.training.spec.luau').read_text(encoding='utf-8-sig')
        marker=' -- No pending training workers or modified prototype values at handoff.'
        assert spec.count(marker)==1
        spec=spec.replace(marker,extension+'\n'+marker)
        runner=(ROOT/'reports/PremiumTreadmillPublicEvent_20261119/edit_test_runner.luau').read_text(encoding='utf-8-sig')
        marker='local test=assert(loadstring(TestSource'
        at=runner.index(marker)
        extra=('S.BoostState=game.ServerScriptService.Services.RewardedStrengthBoostState.Source\n'
               'S.BoostConfig=game.ReplicatedStorage.Config.RewardedStrengthBoostConfig.Source\n'
               f'S.BoostGetter={json.dumps(sources["Bonus"],ensure_ascii=False)}\n')
        return 'local Suite="integration"\nlocal TestSource='+json.dumps(spec,ensure_ascii=False)+'\n'+runner[:at]+extra+runner[at:]
    sources['Test']=(ROOT/f'tests/RewardedStrengthBoost.{suite}.spec.luau').read_text(encoding='utf-8-sig')
    data=json.dumps(json.dumps(sources,ensure_ascii=False),ensure_ascii=False)
    return ('assert(not game:GetService("RunService"):IsRunning(),"Edit only")\n'
            f'local s=game:GetService("HttpService"):JSONDecode({data})\n'
            'return game:GetService("HttpService"):JSONEncode(assert(loadstring(s.Test))()(s))')
if __name__=='__main__':
    import sys
    sys.stdout.buffer.write(build(sys.argv[1]).encode('utf-8'))
