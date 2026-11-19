"""Build a send-free Edit fixture; never starts Studio/Play or contacts Roblox APIs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def build():
    paths = {
        'Config': 'src/ReplicatedStorage/Config/OfflineRewardUIConfig.luau',
        'Style': 'src/ReplicatedStorage/Config/StrengthHUDStyle.luau',
        'Visual': 'src/ReplicatedStorage/Modules/OfflineRewardPresentation.luau',
        'Client': 'src/ReplicatedStorage/Modules/OfflineRewardNoticeClient.luau',
        'Test': 'tests/OfflineRewardUI.spec.luau',
    }
    sources = {k:(ROOT/v).read_text(encoding='utf-8-sig') for k,v in paths.items()}
    data=json.dumps(json.dumps(sources,ensure_ascii=False),ensure_ascii=False)
    return ('assert(not game:GetService("RunService"):IsRunning(),"Edit only")\n'
            'local H=game:GetService("HttpService")\n'
            f'local s=H:JSONDecode({data})\n'
            'return H:JSONEncode(assert(loadstring(s.Test))()(s))')

if __name__ == '__main__':
    import sys
    sys.stdout.buffer.write(build().encode('utf-8'))
