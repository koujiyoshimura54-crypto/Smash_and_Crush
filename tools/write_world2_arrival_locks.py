"""Write only the nine reviewed World2-arrival Source rows into the current place."""
import argparse
import functools
import hashlib
import json
import os
from pathlib import Path
import subprocess

from rbxl_rows import Editor, s, string
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '9222a7f50906cdd0c582862929586a96dfc99088a60f66d5675cb6ade1140bc6'
FILES = {
    "ServerScriptService.Services.PlayerDataService": "src/ServerScriptService/Services/PlayerDataService.luau",
    "ServerScriptService.Services.DumbbellService": "src/ServerScriptService/Services/DumbbellService.luau",
    "ServerScriptService.Services.ItemService": "src/ServerScriptService/Services/ItemService.luau",
    "ServerScriptService.Systems.Controllers.StageProgressController": "src/ServerScriptService/Systems/Controllers/StageProgressController.server.luau",
    "ReplicatedStorage.Modules.InventoryPresentation": "src/ReplicatedStorage/Modules/InventoryPresentation.luau",
    "ReplicatedStorage.Modules.ResponsivePanels": "src/ReplicatedStorage/Modules/ResponsivePanels.luau",
    "StarterGui.StrengthGui.InventoryPanelClient": "src/StarterGui/StrengthGui/InventoryPanelClient.client.luau",
    "StarterGui.StrengthGui.ItemInventoryTabClient": "src/StarterGui/StrengthGui/ItemInventoryTabClient.client.luau",
    "StarterGui.StrengthGui.EssentialStudShopClient": "src/StarterGui/StrengthGui/EssentialStudShopClient.client.luau"
}
REPORT = ROOT/'reports/World2ArrivalLocks_20261021'

def digest(raw):
    return hashlib.sha256(raw).hexdigest()

def apply(raw):
    assert digest(raw) == EXPECTED, 'Unexpected owner edit: inspect before writing'
    before, editor = Editor(raw), Editor(raw)
    editor.path = functools.lru_cache(None)(editor.path)
    paths = {editor.path(ref):ref for ref in editor.parents}
    changed = {}
    for path, relative in FILES.items():
        ref = paths[path]
        old = string(editor.get(ref,'Source'),0)[0]
        # The latest committed mirror is the inspected baseline, never a replacement.
        committed = subprocess.check_output(['git','show','HEAD:'+relative],cwd=ROOT).replace(b'\r\n',b'\n')
        assert old.replace(b'\r\n',b'\n') == committed, path
        new = (ROOT/relative).read_text(encoding='utf8').encode()
        assert old != new, path
        subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/relative)],
                       check=True,stdout=subprocess.DEVNULL)
        editor.set(ref,'Source',s(new))
        changed[path] = {'before':digest(old),'after':digest(new)}
    result, repair = editor.build()
    after = Editor(result)
    assert before.parents == after.parents
    assert before.classes == after.classes
    verified = 0
    allowed = {paths[path] for path in FILES}
    for (cid,name),column in before.columns.items():
        if (cid,name) not in editor.changed:
            assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[cid,name][0]][1], (cid,name)
            verified += len(before.classes[cid])
            continue
        assert name == 'Source'
        for ref,old in before.col(cid,name)[3].items():
            actual = after.col(cid,name)[3][ref]
            assert actual == editor.get(ref,name), (ref,name)
            assert actual == old or ref in allowed, ref
            verified += 1
    assert canonicalize(result)[0] == result
    Document(result).assert_studio_bounds()
    return result,{'inputSha256':digest(raw),'outputSha256':digest(result),
        'changedSources':changed,'changedSourceCount':len(changed),'addedInstances':0,
        'removedInstances':0,'allOtherSourcesPropertiesParentsPreserved':True,
        'verifiedProperties':verified,'binaryValidation':repair,'written':False}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write',action='store_true')
    args=parser.parse_args()
    raw=PLACE.read_bytes()
    result,report=apply(raw)
    if args.write:
        assert not Path(str(PLACE)+'.lock').exists(),'Studio holds the target'
        assert PLACE.read_bytes()==raw,'Target changed during preparation'
        with PLACE.open('r+b') as stream:
            stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
        reread=PLACE.read_bytes()
        assert reread==result
        Document(reread).assert_studio_bounds()
        report['written']=True
        REPORT.mkdir(exist_ok=True)
        (REPORT/'FileValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in report.items() if k!='binaryValidation'},indent=2))

if __name__=='__main__':
    main()
