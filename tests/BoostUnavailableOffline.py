"""Load actual sources into an Edit-only dependency-isolated UI fixture."""
import json,subprocess,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
report=root/'reports/BoostUnavailable_20261120'
manifest=json.loads((report/'before/manifest.json').read_text(encoding='utf-8'))
before={x['Path']:x['Source']for x in json.loads((report/'before/studio.json').read_text(encoding='utf-8'))['Targets']}
paths={'Client':'src/ReplicatedStorage/Modules/RewardedStrengthBoostClient.luau','Config':'src/ReplicatedStorage/Config/RewardedStrengthBoostConfig.luau','Style':'src/ReplicatedStorage/Config/RewardedStrengthBoostStyle.luau','Visual':'src/ReplicatedStorage/Modules/RewardedStrengthBoostPresentation.luau','HUDStyle':'src/ReplicatedStorage/Config/StrengthHUDStyle.luau'}
sources={k:(root/p).read_text(encoding='utf-8-sig')for k,p in paths.items()}
sources['BeforeClient']=before['ReplicatedStorage.Modules.RewardedStrengthBoostClient']
sources['Test']=(root/'tests/BoostUnavailable.ui.spec.luau').read_text(encoding='utf-8')
if __name__=='__main__':sys.stdout.buffer.write(json.dumps(sources,ensure_ascii=False).encode('utf-8'))
