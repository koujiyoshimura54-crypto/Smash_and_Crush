"""Rebuild the Studio-derived comparison CSV and verify preserved artifacts (offline).
Never imports Roblox services or accesses Player data. Run from any directory.
"""
import csv, decimal, gzip, hashlib, json, math, pathlib, re, subprocess
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[1]
def sha(data): return hashlib.sha256(data).hexdigest()
def readjson(path): return json.loads(path.read_text(encoding="utf-8"))
checks={}
for row in readjson(HERE/"before/source_manifest.json"):
 data=(HERE/row["SourceFile"]).read_bytes()
 assert sha(data)==row["SourceSHA256"] and len(data)==row["SourceBytes"]
 assert row["EditorMatchesSource"] and row["EditorSHA256"]==sha(data)
checks["SourceBackupHashes"]=3
meta=readjson(HERE/"before/gui_manifest.json")
data=(HERE/meta["File"]).read_bytes()
assert sha(data)==meta["SHA256"]
decoded=gzip.decompress(data)
assert sha(decoded)==meta["DecodedJSONSHA256"]
snapshot=json.loads(decoded)
assert len(snapshot["Records"])==meta["Instances"]==2888
checks["GUIInstances"]=len(snapshot["Records"])
pure=readjson(HERE/"verification_pure.json")
rows=pure["Rows"]
assert len(rows)==402
studio=dict((int(m[0]),int(m[1])) for m in re.findall(r"\[(\d+)\]\s*=\s*(\d+)",(HERE/"before/sources/ReplicatedStorage.Config.LevelRequirements.luau").read_text(encoding="utf-8").split("local APPROVED_HIGH_REQUIREMENTS=table.freeze({",1)[1].split("})",1)[0]))
assert set(studio)==set(range(51,201))
oldcsv=ROOT/"reports/Level_Curve_20260915/level_51_200_thresholds.csv"
reference={int(r["Level"]):int(r["RequiredStrength"]) for r in csv.DictReader(oldcsv.open(encoding="utf-8-sig"))}
reference_results=[]
for level in range(51,201):
 def smooth(t): return t*t*(3-2*t)
 factor=10**smooth((level-50)/50) if level<=100 else 10**(1+2*smooth((level-100)/40)) if level<=140 else 1000
 expected=math.ceil(reference[level]*factor/10)*10
 assert studio[level]==expected,(level,studio[level],expected)
 reference_results.append({"Level":level,"OldCSVRequirement":reference[level],"DerivedMultiplier":factor,"RoundedExpected":expected,"Studio":studio[level]})
checks["OldCSVRelationshipRows"]=len(reference_results)
for r in rows:
 level,curve=r["Level"],r["CurveVersion"]
 assert curve in (1,2) and 1<=level<=201
 a,b=r["StudioRequiredStrength"],r["PreIntegrationGitHubRequiredStrength"]
 assert math.isfinite(a) and a>0 and math.isfinite(b) and b>0
 if level<=50: assert a==b
 if 51<=level<=200: assert a==studio[level]
 r["Difference"]=a-b
 r["Ratio"]=format(decimal.Decimal(a)/decimal.Decimal(b),".16g")
csvfile=HERE/"Studio実装から生成した比較用CSV_Lv1-201.csv"
with csvfile.open("w",encoding="utf-8-sig",newline="") as f:
 writer=csv.DictWriter(f,fieldnames=["Level","CurveVersion","StudioRequiredStrength","PreIntegrationGitHubRequiredStrength","Difference","Ratio"])
 writer.writeheader();writer.writerows(rows)
(HERE/"verification_old_csv.json").write_text(json.dumps({"Reference":str(oldcsv.relative_to(ROOT)).replace("\\","/"),"ReferenceSHA256":sha(oldcsv.read_bytes()),"Formula":"smooth(t)=t*t*(3-2*t); 51..100 factor=10^smooth((L-50)/50); 101..140 factor=10^(1+2*smooth((L-100)/40)); 141..200 factor=1000; ceil(oldQ*factor/10)*10","Rows":reference_results},ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
for full,rel in {
 "ReplicatedStorage.Config.LevelRequirements":"src/ReplicatedStorage/Config/LevelRequirements.luau",
 "StarterPlayer.StarterPlayerScripts.Combat.CombatClient":"src/StarterPlayer/StarterPlayerScripts/Combat/CombatClient.client.luau",
}.items():
 assert (ROOT/rel).read_bytes().replace(b"\r\n",b"\n")==(HERE/"before/sources"/(full+".luau")).read_bytes().replace(b"\r\n",b"\n")
checks["IntegratedSourceMatches"]=2
daily=(HERE/"before/sources/StarterGui.StrengthGui.DailyRewardsClient.luau").read_bytes().decode()
fixed=daily.replace('"VIP 窶｢ Daily bonus"','"VIP • Daily bonus"').replace('" 窶｢ READY"','" • READY"')
assert daily.count("窶｢")==2 and "窶｢" not in fixed
main=(ROOT/"src/StarterGui/StrengthGui/DailyRewardsClient.client.luau").read_bytes().decode()
assert fixed.replace("\r\n","\n").rstrip()==main.replace("\r\n","\n").rstrip()
checks["DailyLiteralCorrections"]=2
base=readjson(HERE/"before/git_state.json")["OriginMain"]
for rel in ["src/ReplicatedStorage/Modules/LevelProgression.luau","src/ServerScriptService/Services/PlayerDataService.luau"]:
 before=subprocess.check_output(["git","-C",str(ROOT),"show",base+":"+rel])
 assert (ROOT/rel).read_bytes().replace(b"\r\n",b"\n")==before.replace(b"\r\n",b"\n")
checks["UnmodifiedProgressionAndPlayerDataService"]=True
checks["PureLuauAssertions"]=pure["Assertions"]
checks["ComparisonCSVRows"]=len(rows)
checks["CSV_SHA256"]=sha(csvfile.read_bytes())
checks["OriginalApprovalCSVLocated"]=False
(HERE/"verification_artifacts.json").write_text(json.dumps(checks,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps(checks))
