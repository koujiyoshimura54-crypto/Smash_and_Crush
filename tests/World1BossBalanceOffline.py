"""World1 provisional balance regression using real Sources and memory-only adapters.

Usage: python tests/World1BossBalanceOffline.py <luau.exe> [--place CurrentCloud.rbxl]
The optional place supplies its actual consumers; Config must match the src mirror.
No Studio, Play, real input, network, player data or saving is involved.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from rbxl_referents import Document, string, u32


def place_sources(raw):
    doc = Document(raw)
    doc.assert_studio_bounds()
    names, sources = {}, {}
    for kind, data, _, _ in doc.chunks:
        if kind != b'PROP':
            continue
        cid = u32(data)
        name, pos = string(data, 4)
        if name not in (b'Name', b'Source'):
            continue
        assert data[pos] == 1
        pos += 1
        target = names if name == b'Name' else sources
        for ref in doc.classes[cid][1]:
            value, pos = string(data, pos)
            target[ref] = value.decode('utf-8')
        assert pos == len(data)
    parents = dict(doc.parent_pairs)
    def full_path(ref):
        return (full_path(parents[ref]) + '.' if parents[ref] != -1 else '') + names[ref]
    return {full_path(ref): source for ref, source in sources.items()}


def between(source, start, end):
    pos = source.index(start)
    return source[pos:source.index(end, pos)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('luau')
    parser.add_argument('--place', type=Path)
    args = parser.parse_args()
    actual = place_sources(args.place.read_bytes()) if args.place else None
    def read(path):
        if actual:
            return actual[path]
        base = ROOT / 'src' / path.replace('.', '/')
        candidates = [Path(str(base) + suffix) for suffix in ('.luau', '.client.luau', '.server.luau')]
        return next(p for p in candidates if p.exists()).read_text(encoding='utf-8')
    sources = {key: read(path) for key, path in {
        'Config': 'ReplicatedStorage.Config.World1BossConfig',
        'Wall': 'ServerScriptService.World.Stage1WallManager',
        'Boss': 'ServerScriptService.World.BossCombatService',
        'World2': 'ReplicatedStorage.Config.World2Config',
        'World2Boss': 'ReplicatedStorage.Config.World2BossConfig',
        'Combat': 'ReplicatedStorage.Config.CombatConfig',
        'NumberFormat': 'ReplicatedStorage.Modules.NumberFormat',
    }.items()}
    mirror = (ROOT / 'src/ReplicatedStorage/Config/World1BossConfig.luau').read_text(encoding='utf-8')
    assert sources['Config'].replace('\r\n', '\n') == mirror
    sources['Before'] = subprocess.check_output(['git', 'show', '5bf7d96:src/ReplicatedStorage/Config/World1BossConfig.luau'], cwd=ROOT).decode()
    enemy = read('ServerScriptService.World.EnemyManager')
    client = read('StarterPlayer.StarterPlayerScripts.Combat.CombatClient')
    # Existing world1 wall path deliberately discards the third (surplus) return.
    assert 'local cleared,nextIndex=Wall.ApplyDamageForStage(attackPlayer,attackStage,attackPower)' in enemy
    assert 'Boss.QueueDamage(' not in enemy
    assert 'Boss.Reset(p) Wall.InitializePlayer(p' in enemy or ('Boss.Reset(p)' in enemy and 'Wall.InitializePlayer(p' in enemy)
    assert 'Boss.ResetEncounterForHeal(p,n)' in enemy
    assert 'Current=maxHP,Max=maxHP' in enemy
    assert 'Current=bs.HP,Max=bs.MaxHP' in enemy
    assert 'state.Gauges[index],state.Maxes[index]' in client or 'state.Gauges[i],state.Maxes[i]' in client
    sources['SpawnAttributes'] = 'return function(e,i)\n' + between(enemy, ' e:SetAttribute("MaxGauge"', ' for _,d in e:GetDescendants()') + '\nend'
    sources['InitialGauges'] = between(enemy, 'local function state(p)', '\n') + '\nreturn state'
    sources['BossGauge'] = 'return function(d)\n' + between(client, '  local f=fills[d.Stage] if f then f.Current=d.Current;', '\n elseif d.Type=="BossResult"') + '\nend'
    sources['WallGauge'] = between(client, 'local function wallGauge(', '\n-- One renderer') + '\nreturn wallGauge' if 'PurchasedWallHealth.format' in client else ''
    fixture = (ROOT / 'tests/World1BossBalanceOffline.spec.luau').read_text(encoding='utf-8')
    encoded = 'local sources={' + ','.join('[' + json.dumps(k) + ']=' + json.dumps(v) for k, v in sources.items()) + '}\n'
    result = subprocess.run([args.luau], input='assert(loadstring(' + json.dumps(encoded + fixture) + '))()\n', text=True, capture_output=True)
    print(result.stdout)
    if result.returncode or result.stderr or 'WORLD1_BOSS_BALANCE_OFFLINE_PASS' not in result.stdout:
        print(result.stderr, file=sys.stderr)
        raise SystemExit(1)
    print('Evidence: simulated actual place Sources' if actual else 'Evidence: simulated repository Sources')


if __name__ == '__main__':
    main()
