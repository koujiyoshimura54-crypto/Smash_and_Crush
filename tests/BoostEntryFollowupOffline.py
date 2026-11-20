import importlib.util,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('boost',root/'tests/BoostUnavailableOffline.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
sources=module.sources
before=json.loads((root/'reports/BoostEntryFollowup_20261120/before.json').read_text(encoding='utf-8'))
sources['BeforeDuplicateClient']=before['Sources']['ReplicatedStorage.Modules.RewardedStrengthBoostClient']
sources['BeforeTreadmill']=before['Sources']['ReplicatedStorage.Config.TreadmillConfig']
sources['Treadmill']=(root/'src/ReplicatedStorage/Config/TreadmillConfig.luau').read_text(encoding='utf-8')
sources['DuplicateTest']=(root/'tests/BoostEntryDuplicate.spec.luau').read_text(encoding='utf-8')
sources['GlyphTest']=(root/'tests/TreadmillGlyph.spec.luau').read_text(encoding='utf-8')
marker='  return {Assertions=checks,Cases=cases,'
assert sources['Test'].count(marker)==1
sources['Test']=sources['Test'].replace(marker,'  cases.Duplicate=assert(loadstring(s.DuplicateTest))()(s,fixture,eq,settle)\n  cases.Treadmill=assert(loadstring(s.GlyphTest))()(s)\n'+marker)
if __name__=='__main__':sys.stdout.buffer.write(json.dumps(sources,ensure_ascii=False).encode('utf-8'))
