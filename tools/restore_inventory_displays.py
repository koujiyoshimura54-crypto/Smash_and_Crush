"""Restore the inspected pending Inventory changes and World1 displays only.

Uses the existing lossless editor and 2026-10-17 layout; never replays the
World2 generator. Dry run by default. No alternate place or Studio save.
"""
import argparse
import functools
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

from rbxl_rows import Editor, s, string, udim2, vector
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = 'b6875068599c0cae8a11846027987949468f398dac555ac56f972333c337777f'
IMAGES = {6:92138447886967, 8:110171141876908, 9:129522181601539,
          10:92929093922544, 11:89748292939648, 12:121194224737958}
FILES = {
    'ReplicatedStorage.Modules.InventoryPresentation': 'src/ReplicatedStorage/Modules/InventoryPresentation.luau',
    'StarterGui.StrengthGui.InventoryPanelClient': 'src/StarterGui/StrengthGui/InventoryPanelClient.client.luau',
    'StarterGui.StrengthGui.ItemInventoryTabClient': 'src/StarterGui/StrengthGui/ItemInventoryTabClient.client.luau',
}
MASTER = 'ReplicatedStorage.Config.DumbbellItemMaster'
MASTER_FILE = 'src/ReplicatedStorage/Config/DumbbellItemMaster.luau'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def apply(raw):
    assert digest(raw) == EXPECTED, 'Unexpected owner edit: inspect before writing'
    before, e = Editor(raw), Editor(raw)
    before.path = functools.lru_cache(None)(before.path)
    e.path = functools.lru_cache(None)(e.path)
    paths = {e.path(r):r for r in e.parents}
    allowed, changes = set(), []
    def setprop(path, name, value):
        ref = paths[path]
        if e.get(ref, name) == value:
            return
        allowed.add((ref, name))
        changes.append({'path':path, 'property':name})
        e.set(ref, name, value)
    saved = json.loads((ROOT/'reports/InventorySecrets_20261020/FileValidation.json').read_text())
    source_hashes = {}
    for path, relative in FILES.items():
        old = string(e.get(paths[path], 'Source'), 0)[0]
        new = (ROOT/relative).read_text(encoding='utf8').encode()
        assert digest(old) == saved['changedSources'][path]['before'], path
        assert digest(new) == saved['changedSources'][path]['after'], path
        subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/relative)],
                       check=True, stdout=subprocess.DEVNULL)
        setprop(path, 'Source', s(new))
        source_hashes[path] = {'before':digest(old),'after':digest(new),'reusedUnchanged':True}
    original_master = string(e.get(paths[MASTER], 'Source'), 0)[0].decode()
    assert original_master == (ROOT/MASTER_FILE).read_text(encoding='utf8')
    master = original_master
    for index, image in IMAGES.items():
        master, count = re.subn(r'(ItemId="NORMAL_%02d"[^\n]*ImageAssetId=)\d+' % index,
                               lambda m:m[1]+str(image), master)
        assert count == 1
    assert 'ImageAssetId=134662273184560' in master
    setprop(MASTER, 'Source', s(master))
    source_hashes[MASTER] = {'before':digest(original_master.encode()),'after':digest(master.encode())}
    definitions = {int(n):(int(price),int(bonus),int(image)) for n,price,bonus,image in
                   re.findall(r'ItemId="NORMAL_(\d+)"[^\n]*PriceWin=(\d+), StrengthBonus=(\d+), ImageAssetId=(\d+)',master)}
    facilities = []
    for index in range(1,13):
        path = 'Workspace.PerStepButtons.'+str(index)
        board = path+'.BillboardGui'
        setprop(board, 'Size', udim2(9,0,9,0))
        setprop(board, 'StudsOffset', vector(0,6.5,0))
        setprop(board, 'ClipsDescendants', b'\0')
        setprop(board+'.ItemIcon', 'Size', udim2(.96,0,.58,0))
        setprop(board+'.ItemIcon', 'ScaleType', (3).to_bytes(4,'big'))
        setprop(board+'.ItemIcon', 'ImageRectOffset', vector(0,0))
        setprop(board+'.ItemIcon', 'ImageRectSize', vector(0,0))
        # Current names: Amount contains Win price; Price contains Strength effect.
        for name,width,height in [('Amount',.8,.12),('Price',.95,.14),('Status',.95,.10)]:
            setprop(board+'.'+name, 'Size', udim2(width,0,height,0))
        setprop(board+'.ItemIcon', 'Image', s('rbxassetid://'+str(definitions[index][2])))
        exhibit = paths['Workspace.ShoesModels.'+str(index)]
        assert e.doc.classes[e.class_of[exhibit]][0] == 'Model'
        for ref in e.subtree(exhibit):
            assert e.doc.classes[e.class_of[ref]][0] in ('Model','Part','SpecialMesh','WeldConstraint','Weld'), e.path(ref)
        e.remove(exhibit)
        facilities.append({'path':path,'itemId':'NORMAL_%02d'%index,
                           'image':'rbxassetid://'+str(definitions[index][2]),
                           'priceWin':definitions[index][0],'strengthBonus':definitions[index][1]})
    assert len(e.removed) == 168
    result, repair = e.build()
    after = Editor(result)
    verified = 0
    for (cid,name),col in e.columns.items():
        if ((cid,name) not in e.changed and col[1] not in (19,34)
                and not any(ref in e.removed for ref in before.classes[cid])):
            assert before.doc.chunks[col[0]][1] == after.doc.chunks[after.columns[cid,name][0]][1], (cid,name)
            verified += len(before.classes[cid])
            continue
        oldrows = before.col(cid,name)[3]
        newrows = after.col(cid,name)[3]
        for ref in before.classes[cid]:
            if ref in e.removed:
                continue
            expected = e.get(ref,name)
            assert oldrows[ref] == expected or (ref,name) in allowed, (e.path(ref),name,'unapproved change')
            if col[1] == 19:
                expected = e.final_mapping.get(expected,expected)
            elif col[1] == 34 and expected[0] == 2:
                expected = (2,e.final_mapping.get(expected[1],expected[1]))
            assert newrows[e.final_mapping.get(ref,ref)] == expected, (e.path(ref),name)
            verified += 1
    for ref,parent in e.parents.items():
        if ref not in e.removed:
            assert after.parents[e.final_mapping.get(ref,ref)] == e.final_mapping.get(parent,parent)
    assert len(after.subtree(e.final_mapping.get(paths['Workspace.ShoesModels'],paths['Workspace.ShoesModels']))) == 1
    assert canonicalize(result)[0] == result
    Document(result).assert_studio_bounds()
    report = {'inputSha256':digest(raw),'outputSha256':digest(result),'changedSources':source_hashes,
              'facilities':facilities,'changedProperties':changes,'removedExhibits':12,
              'removedInstances':len(e.removed),'addedInstances':0,'verifiedSurvivingProperties':verified,
              'allOtherSourcesPropertiesParentsPreserved':True,'world2AndDecorationsUnchanged':True,
              'binaryValidation':repair,'written':False}
    return result,report,master


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write',action='store_true')
    args=parser.parse_args()
    raw=PLACE.read_bytes()
    result,report,master=apply(raw)
    with tempfile.TemporaryDirectory(prefix='inventory-display-compile-') as temp:
        candidate=Path(temp)/'DumbbellItemMaster.luau'
        candidate.write_text(master,encoding='utf8')
        subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(candidate)],
                       check=True,stdout=subprocess.DEVNULL)
    if args.write:
        assert not Path(str(PLACE)+'.lock').exists(),'Studio holds the target'
        assert PLACE.read_bytes()==raw,'Target changed during preparation'
        with PLACE.open('r+b') as stream:
            stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
        reread=PLACE.read_bytes()
        assert reread==result
        Document(reread).assert_studio_bounds()
        report['written']=True
        (ROOT/MASTER_FILE).write_text(master,encoding='utf8',newline='\n')
        folder=ROOT/'reports/InventoryDisplayRestore_20261021'
        folder.mkdir(exist_ok=True)
        (folder/'FileValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in report.items() if k not in ('facilities','changedProperties','binaryValidation')},indent=2))


if __name__ == '__main__':
    main()
