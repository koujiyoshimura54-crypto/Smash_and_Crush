"""Scoped Source-only writeback; preserve every saved template and unrelated row."""
from pathlib import Path
import hashlib,json,os,subprocess,functools,argparse
from rbxl_rows import Editor,s,string
ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r"C:\Users\kouji\MergeToForge_CurrentCloud.rbxl")
EXPECTED="68aed1f64f92cae7fa621f606661d301caee5b04c45772eed3cc1c62649ae8b0"
FILES={
 "ReplicatedStorage.Modules.World2BossRig":"src/ReplicatedStorage/Modules/World2BossRig.luau",
 "ServerScriptService.StudioBossAnimationPreview":"src/ServerScriptService/StudioBossAnimationPreview.server.luau",
 "StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview":"src/StarterPlayer/StarterPlayerScripts/StudioBossAnimationPreview.client.luau",
}
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--write",action="store_true");args=parser.parse_args()
 raw=PLACE.read_bytes();assert hashlib.sha256(raw).hexdigest()==EXPECTED,"Unexpected saved edits; inspect first"
 before,edit=Editor(raw),Editor(raw);edit.path=functools.lru_cache(None)(edit.path)
 paths={edit.path(r):r for r in edit.parents};approved=set();changes={}
 for path,relative in FILES.items():
  ref=paths[path];old=string(before.get(ref,"Source"),0)[0].decode().replace("\r\n","\n")
  git=subprocess.check_output(["git","show","4ffb306:"+relative],cwd=ROOT).decode().replace("\r\n","\n")
  assert old==git,("Unexpected source edits",path)
  source=(ROOT/relative).read_text(encoding="utf-8")
  subprocess.run([r"C:\Users\kouji\stage_skip_work\luau\luau-compile.exe","--null",str(ROOT/relative)],check=True,stdout=subprocess.DEVNULL)
  if path.endswith("StudioBossAnimationPreview") and path.startswith("Server"):
   a=old.index("\tlocal walkCandidates =");b=old.index("\tlocal candidates, ids =",a);assert old[a:b] in source
  edit.set(ref,"Source",s(source));approved.add((ref,"Source"))
  changes[path]={"before":hashlib.sha256(old.encode()).hexdigest(),"after":hashlib.sha256(source.encode()).hexdigest()}
 result,_=edit.build();after=Editor(result);assert after.parents==before.parents
 verified=0
 for (cid,name),col in before.columns.items():
  if (cid,name) not in edit.changed:
   assert before.doc.chunks[col[0]][1]==after.doc.chunks[after.columns[cid,name][0]][1]
   verified+=len(before.classes[cid]);continue
  for ref,value in before.col(cid,name)[3].items():
   if (ref,name) not in approved:assert value==after.get(ref,name)
   verified+=1
 for path,relative in FILES.items():assert string(after.get(paths[path],"Source"),0)[0].decode()==(ROOT/relative).read_text(encoding="utf-8")
 report={"before":before.doc.summary(),"after":after.doc.summary(),"sources":changes,"originalRowsChecked":verified,"allSavedTemplatesParentsAndOtherPropertiesPreserved":True,"written":False}
 if args.write:
  assert not Path(str(PLACE)+".lock").exists();assert PLACE.read_bytes()==raw
  with PLACE.open("r+b") as f:f.write(result);f.truncate();f.flush();os.fsync(f.fileno())
  assert PLACE.read_bytes()==result;Editor(PLACE.read_bytes()).doc.assert_studio_bounds();report["written"]=True
  (ROOT/"reports/World2RemainingBossAnimations_20261022/Writeback.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
 print(json.dumps(report,indent=2))
if __name__=="__main__":main()
