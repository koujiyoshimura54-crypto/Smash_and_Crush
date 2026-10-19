"""Execute only /test restoration paths with memory-only Roblox adapters.

No Play, real player sessions, DataStore handles or /resetdata invocation.
--place reads the actual saved Sources; PlayerData functions are extracted without
executing its DataStore initialization. This is simulation, not real chat input.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from rbxl_rows import Editor, string

SERVER = 'ServerScriptService.Systems.Debug.StudioStartController'
CLIENT = 'StarterPlayer.StarterPlayerScripts.StudioTestCommandClient'
MIRRORS = {
    SERVER: 'src/ServerScriptService/Systems/Debug/StudioStartController.server.luau',
    CLIENT: 'src/StarterPlayer/StarterPlayerScripts/StudioTestCommandClient.client.luau',
}


def between(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('luau', type=Path)
    parser.add_argument('--place', type=Path, required=True)
    parser.add_argument('--candidate', action='store_true', help='Before write: use only the two candidate scripts with actual saved dependencies')
    args = parser.parse_args()
    if args.place:
        editor = Editor(args.place.read_bytes())
        paths = {editor.path(r): r for r in editor.parents}
        def read(path):
            if args.candidate and path in MIRRORS:
                return (ROOT / MIRRORS[path]).read_text(encoding='utf-8')
            return string(editor.get(paths[path], 'Source'), 0)[0].decode('utf-8')
        assert read(SERVER) == (ROOT / MIRRORS[SERVER]).read_text(encoding='utf-8')
        assert read(CLIENT) == (ROOT / MIRRORS[CLIENT]).read_text(encoding='utf-8')
    data = read('ServerScriptService.Services.PlayerDataService')
    # Keep actual rejection, snapshot, attribute, restoration and Save guard code.
    data_functions = between(data, 'function PlayerDataService.ApplyStudioStartLevel(', '-- Output mirrors only;')
    save_guard = between(data, 'function PlayerDataService.Save(', ' PlayerDataService.GetTimeRewards(player)')
    save_guard += ' error("Persistence is forbidden in this memory-only fixture")\nend\n'
    sources = {
        'server': read(SERVER), 'client': read(CLIENT),
        'config': read('ServerScriptService.Config.StudioDebugConfig'),
        'requirements': read('ReplicatedStorage.Config.LevelRequirements'),
        'progression': read('ReplicatedStorage.Modules.LevelProgression'),
        'data': data_functions + save_guard,
    }
    if args.place:
        hud = read('StarterGui.StrengthGui.StrengthDisplay')
        sources['hud'] = between(hud, 'local function update()', 'gui:GetPropertyChangedSignal("AbsoluteSize")')
    else:
        # The repository HUD mirror can differ; the saved-file run covers actual HUD.
        sources['hud'] = ''
    declarations = '\n'.join('SOURCES.' + key + '=' + json.dumps(value, ensure_ascii=False)
                              for key, value in sources.items())
    fixture = 'local SOURCES={}\n' + declarations + '\n' + (ROOT / 'tests/StudioTestCommandsOffline.spec.luau').read_text(encoding='utf-8')
    with tempfile.TemporaryDirectory(prefix='studio_test_commands_') as directory:
        test = Path(directory) / 'fixture.luau'
        test.write_text(fixture, encoding='utf-8')
        result = subprocess.run([str(args.luau), str(test)], capture_output=True, text=True, encoding='utf-8')
    print(result.stdout, end='')
    if result.returncode:
        print(result.stderr, file=sys.stderr)
        raise SystemExit(result.returncode)
    print('Evidence: candidate entrypoints with actual saved dependencies (memory-only)' if args.candidate
          else 'Evidence: actual saved Sources in memory-only adapters')


if __name__ == '__main__':
    main()
