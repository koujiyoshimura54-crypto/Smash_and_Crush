"""Replay the old isolated fixture, optionally preserving only donor MeshSize.

Requires the local source/geometry audits listed in the report. Never plays the
connected copy; generated RunFixture aborts before Play on isolation failure.
"""
from pathlib import Path
import json, shutil, sys
root=Path(__file__).resolve().parents[1]
out=root/'tmp/World2Dumbbell3D/original_replay';out.mkdir(parents=True,exist_ok=True)
shutil.copyfile(root/'tmp/Dumbbell3D/geometry.json',out/'geometry.json')
if '--serialized-mesh' in sys.argv:
 data=json.loads((out/'geometry.json').read_text(encoding='utf-8'))
 audit=json.loads((root/'tmp/World2Dumbbell3D/NativeDonorAudit.json').read_text(encoding='utf-8'))
 def fix(row):
  if row['Class']=='MeshPart':row['Properties']['InitialSize']={'T':'Vector3','V':audit[row['Properties']['Name']['V']]['MeshSize']}
  for child in row['Children']:fix(child)
 for row in data:
  if row['Path'].endswith('PlayableSourceBody'):fix(row['Tree'])
 (out/'geometry.json').write_text(json.dumps(data),encoding='utf-8')
code=(root/'tests/build_world1_dumbbell_fixture.py').read_text(encoding='utf-8')
code=code.replace("OUT=ROOT/'tmp/Dumbbell3D'","OUT=ROOT/'tmp/World2Dumbbell3D/original_replay'")
code=code.replace('# Fixture-only gate:',"bank=json.loads((ROOT/'tmp/World2Dumbbell3D/SourceSnapshot.json').read_text(encoding='utf-8'))\nbank['ServerScriptService.Systems.Controllers.World1DumbbellExhibitController']=(ROOT/'tmp/World2Dumbbell3D/OriginalExhibitController.luau').read_text(encoding='utf-8')\nfor path in sources:\n    if path in bank:sources[path]=bank[path]\n# Fixture-only gate:")
exec(compile(code,str(root/'tests/build_world1_dumbbell_fixture.py'),'exec'),{'__file__':str(root/'tests/build_world1_dumbbell_fixture.py'),'__name__':'__main__'})
if '--serialized-mesh' in sys.argv:
 runner=out/'RunFixture.luau'
 proof='local audit=game.HttpService:JSONDecode([==['+json.dumps(audit)+']==])\nfor _,p in game.ServerStorage.BodyPrototype_20261114.PlayableSourceBody:GetDescendants()do if p:IsA("MeshPart")then local e=assert(audit[p.Name]);assert((p.MeshSize-Vector3.new(unpack(e.MeshSize))).Magnitude<.0001,"MeshSize mismatch");assert(math.abs(p:GetMass()-e.Mass)<.0001,"Mass mismatch")end end\nprint("ORIGINAL_REPLAY_SERIALIZED_MESH_VERIFIED")\n'
 runner.write_text(runner.read_text(encoding='utf-8').replace('game.ServerStorage.BodyPrototype_20261114:SetAttribute("Enabled",true)',proof+'game.ServerStorage.BodyPrototype_20261114:SetAttribute("Enabled",true)'),encoding='utf-8')
