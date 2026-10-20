"""Shared Rebirth contract checks against the effective current-file baseline."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
read = lambda path: (root / path).read_text(encoding='utf8')
common = read('src/ReplicatedStorage/Config/RebirthConfig.luau')
alias = read('src/ReplicatedStorage/Config/RebirthMultiplierConfig.luau')
world2 = read('src/ReplicatedStorage/Config/World2GameplayConfig.luau')
assert 'World2GameplayConfig' not in common and 'require(' not in common
assert 'World2.Rebirth' not in read('src/ReplicatedStorage/Config/RebirthConfig.luau')
assert 'RebirthMultiplierConfig' not in read('src/ServerScriptService/Services/StrengthManager.luau')
assert 'RebirthMultiplierConfig' not in read('src/StarterGui/StrengthGui/RebirthMenuClient.client.luau')
script = 'local C=(function()\n' + common + '\nend)()\n'
script += '''local alias=(function()
local script={Parent={WaitForChild=function(_,name)assert(name=='RebirthConfig')return name end}}
local require=function(name)assert(name=='RebirthConfig')return C end
''' + alias + '\nend)()\n'
script += 'local W=(function()\n' + world2 + '\nend)()\n'
script += '''
local levels={10,15,22,30,45,70,90,110,140,160,45,50,300,400,500,600,750,900,1000,1250,1500,2000,2500,3000,4000,5000,6000,7500,9000,10000}
local refs={955,2840,10485,37315,462965,61420025,314953025,1073937025,4677580025,12226986025}
assert(W.Rebirth==nil and C.World1MaxRebirth==5)
assert(alias==C and alias.Multipliers==C.Multipliers)
assert(#C.RebirthRequiredLevels==#levels)
for count=0,30 do
 assert(C.GetRequiredLevel(count)==levels[count+1])
 assert(C.IsWorld1Max(count)==(levels[count+1]==nil))
 assert(C.GetMultiplier(count)==1+count*.5)
 assert(C.Multipliers[count]==1+count*.5)
 assert(C.GetReferenceStrength(count)==refs[count+1])
end
assert(not C.IsWorld1Max(5) and not C.IsWorld1Max(10))
assert(C.GetRequiredLevel(5)==70 and C.GetRequiredLevel(9)==160)
assert(C.GetRequiredLevel(10)==45 and C.GetRequiredLevel(29)==10000)
assert(C.IsWorld1Max(30) and C.GetMultiplier(31)==16.5)
for _,value in {'invalid',false,math.huge,-math.huge,0/0}do assert(C.GetMultiplier(value)==1)end
assert(C.GetMultiplier()==1 and C.GetMultiplier(-3)==1)
assert(C.GetMultiplier('5')==3.5 and C.GetMultiplier(5.9)==3.5)
-- Equipment-specific unlock definitions are independent of shared Rebirth.
assert(W.Treadmills[1].RequiredRebirth==0)
assert(W.Treadmills[2].RequiredRebirth==7)
assert(W.Treadmills[3].RequiredRebirth==9)
assert(W.Treadmills[4].PurchaseEnabled==false)
print('PASS: all30 requirements/caps,0..30 lookup,unbounded +0.5 API,compatibility alias,references and equipment unlocks')
'''
with tempfile.TemporaryDirectory(prefix='mtf-rebirth-') as temp:
    test = Path(temp) / 'check.luau'
    test.write_text(script, encoding='utf8')
    subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau.exe'), str(test)], check=True)
