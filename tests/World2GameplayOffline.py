"""Actual World2 configuration/services with memory-only players/storage/engine adapters.

No Play, Marketplace, real DataStore, account data, reset or permanent test grants.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from rbxl_rows import Editor,string
from world2_gameplay_sources import build,PLACE


def between(source,start,end):
    i=source.index(start)
    return source[i:source.index(end,i)]


def function(source,name):
    i=source.index('function PlayerDataService.'+name+'(')
    j=source.find('\nfunction PlayerDataService.',i+1)
    return source[i:j if j>=0 else len(source)]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('luau',type=Path)
    parser.add_argument('--saved',action='store_true')
    args=parser.parse_args()
    raw=PLACE.read_bytes();editor=Editor(raw)
    sources={editor.path(r):string(editor.get(r,'Source'),0)[0].decode('utf-8') for r in editor.parents if(editor.class_of[r],'Source')in editor.columns}
    baseline={}
    if not args.saved:
        c=build(raw)
        baseline=dict(sources)
        sources.update(c.sources)
        sources['ReplicatedStorage.Config.World2GameplayConfig']=(ROOT/'src/ReplicatedStorage/Config/World2GameplayConfig.luau').read_text(encoding='utf-8')
    pds=sources['ServerScriptService.Services.PlayerDataService']
    # Run actual validation/normalization and transaction functions, not DSS startup.
    data=between(pds,'local function today()','local function applyAttributes(')
    data+='\n'+between(pds,'local function resolvePetMutation(','function PlayerDataService.ResolveItemMutation(')
    data+='\n'+between(pds,'function PlayerDataService.ResolveItemMutation(','-- Private validation and snapshot')
    data+='\n'+between(pds,'function PlayerDataService.ChangeItemCounts(','-- The shared receipt journal')
    for name in ['SetWin','SetEquippedDumbbell','SetEquippedAura','ResetStrengthProgress','SetRebirthCount','GetLevelState','AddStrengthGain']:
        data+='\n'+function(pds,name)
    data+='\nreturn {Normalize=normalize,Defaults=defaults}'
    sources['Test.DataFunctions']=data
    sources['Test.TrophyCollect']=between(sources['ServerScriptService.Services.TrophyRewardService'], 'local function collect(', '\nfunction M.Spawn(')+'\nreturn collect'
    win=sources['ServerScriptService.Services.GamePassService'];a=win.index('function M.GetWinReward(')
    sources['Test.WinReward']=win[a:win.index('\nlocal function releaseWinPrompt',a)]+'\nreturn M.GetWinReward'
    artifact=json.loads((ROOT/'reports/World2Workbook_20261020.json').read_text(encoding='utf-8'))
    declarations='local SOURCES={}\n'
    # Retain only used Sources in fixture; no historical reports or unrelated audit.
    chosen=[p for p in sources if p.startswith('ReplicatedStorage.Config.') or p.startswith('ReplicatedStorage.Modules.')]
    chosen+=['ServerScriptService.Services.'+n for n in ['DumbbellService','ItemService','ItemMergeService','AuraService','EggServer','PetServer','StrengthManager','TrainingManager','EnemyDropRoller']]
    chosen+=['ServerScriptService.World.BossCombatService','ServerScriptService.World.Stage1WallManager','ServerScriptService.Services.RunReturnService','ServerScriptService.Systems.Controllers.RebirthService','ServerScriptService.Systems.Controllers.TrainingController','Test.DataFunctions','Test.TrophyCollect','Test.WinReward']
    for name in chosen:
        declarations+='SOURCES['+json.dumps(name)+']='+json.dumps(sources[name],ensure_ascii=False)+'\n'
    declarations+='local BASELINE={}\n'
    for name in ['ReplicatedStorage.Config.DumbbellItemMaster','ReplicatedStorage.Config.ItemMaster','ReplicatedStorage.Config.AuraConfig','ReplicatedStorage.Config.RebirthConfig','ReplicatedStorage.Modules.Egg','ReplicatedStorage.Modules.Pet','ReplicatedStorage.Modules.Config']:
        if name in baseline:declarations+='BASELINE['+json.dumps(name)+']='+json.dumps(baseline[name],ensure_ascii=False)+'\n'
    # Canonical workbook expectation is independent of the generated Lua Config.
    sys.path.insert(0,str(ROOT/'tools'));from world2_workbook import lua
    declarations+='local EXPECTED='+lua(artifact['parsed'])+'\n'
    fixture=declarations+(ROOT/'tests/World2GameplayOffline.spec.luau').read_text(encoding='utf-8')
    with tempfile.TemporaryDirectory(prefix='world2_gameplay_')as directory:
        path=Path(directory)/'fixture.luau';path.write_text(fixture,encoding='utf-8')
        result=subprocess.run([str(args.luau),str(path)],capture_output=True,text=True,encoding='utf-8')
    print(result.stdout,end='')
    if result.returncode:
        print(result.stderr,file=sys.stderr);raise SystemExit(result.returncode)
    print('Evidence: saved-file Sources' if args.saved else 'Evidence: candidate actual-Source patches; unchanged World1 baseline from actual file')


if __name__=='__main__':main()
