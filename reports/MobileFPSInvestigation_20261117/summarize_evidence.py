"""Offline aggregation only. Reads captured JSON/prior manifests, never Roblox APIs.
Run from the repository root: python reports/MobileFPSInvestigation_20261117/summarize_evidence.py
"""
from pathlib import Path
from collections import Counter, defaultdict
import csv, gzip, hashlib, json

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
def read(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))
def save(name, obj):
    (OUT / name).write_bytes((json.dumps(obj, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
def csvout(name, rows):
    if not rows: return
    with (OUT/name).open("w",encoding="utf-8-sig",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator="\n");w.writeheader();w.writerows(rows)
def assetid(value):
    return str(value or "").removeprefix("rbxassetid://")

scene=read(OUT/"scene.json")
dumbbells=read(OUT/"dumbbell_instances.json")
effects=json.loads(gzip.decompress((OUT/"effects.json.gz").read_bytes()))
extra=read(OUT/"physics_gui_inventory.json")
w1=read(ROOT/"reports/World1Dumbbell3D_20261116/ASSETS.json")
w2=read(ROOT/"reports/World2Dumbbell3D_20261117/ASSETS.json")["Models"]
metadata={r["ItemId"]:r for r in w1+w2 if r.get("ItemId")}
exhibits={r["ItemId"]:r for r in dumbbells["Exhibits"]}
rows=[]; hashes=defaultdict(list); mapids=set(); verified_source_triangles=[]
for lib in sorted(dumbbells["Libraries"], key=lambda r:r["ItemId"]):
    item=lib["ItemId"]; exhibit=exhibits.get(item)
    mesh=next((p for p in lib["Parts"] if p["Class"]=="MeshPart"),None)
    exmesh=next((p for p in (exhibit or {}).get("Parts",[]) if p["Class"]=="MeshPart"),None)
    m=metadata.get(item,{})
    expected_mesh=assetid(m.get("MeshId",m.get("MeshAssetId")))
    matched=bool(mesh and assetid(mesh["MeshId"])==expected_mesh)
    maps=mesh.get("SurfaceAppearance",{}) if mesh else {}
    triangles=m.get("Triangles") if matched else None
    if triangles: verified_source_triangles.append(triangles)
    row=dict(ItemId=item,Library=lib["Path"],Exhibit=(exhibit or {}).get("Path"),
        PartsPerModel=len(lib["Parts"]),MeshPartsPerModel=int(mesh is not None),
        MeshId=assetid(mesh["MeshId"]) if mesh else "",SourceManifestMeshMatches=matched,
        SourceConversionTriangles=triangles,RuntimeRenderedTriangles="unavailable",
        LibraryAndExhibitShareMesh=bool(mesh and exmesh and mesh["MeshId"]==exmesh["MeshId"]) if mesh else "primitive",
        LibraryAndExhibitShareMaps=maps==exmesh.get("SurfaceAppearance",{}) if exmesh else "primitive",
        RenderFidelity=mesh.get("RenderFidelity") if mesh else "",
        CastShadow=mesh.get("CastShadow") if mesh else "",
        SourceTextureDimensions=";".join(sorted(set("x".join(map(str,v.get("size",[]))) for v in m.get("Maps",{}).values()))) if matched else "",
        MetadataReference="reports/World2Dumbbell3D_20261117/ASSETS.json" if item.startswith("W2_") else "reports/World1Dumbbell3D_20261116/ASSETS.json")
    # SurfaceAppearance.Path differs between copies; compare IDs explicitly.
    if exmesh: row["LibraryAndExhibitShareMaps"]=all(maps.get(k)==exmesh.get("SurfaceAppearance",{}).get(k) for k in ["ColorMap","NormalMap","RoughnessMap","MetalnessMap"])
    for sourcekey,livekey,w2key in [("basecolor","ColorMap","BaseColor"),("normal","NormalMap","Normal"),("roughness","RoughnessMap","Roughness"),("metallic","MetalnessMap","Metallic")]:
        liveid=assetid(maps.get(livekey))
        row[livekey]=liveid
        expected=assetid(m.get(livekey,m.get("TextureAssetIds",{}).get(w2key)))
        rec=(m.get("Maps") or {}).get(sourcekey,{})
        if liveid: mapids.add(liveid)
        if matched and liveid and liveid==expected and rec.get("sha256"):
            hashes[rec["sha256"]].append(dict(ItemId=item,Channel=livekey,AssetId=liveid,SourceDimensions=rec.get("size")))
    rows.append(row)
csvout("dumbbell_asset_summary.csv",rows)
duplicates=[dict(SHA256=h,Records=r,DistinctAssetIds=sorted({x["AssetId"] for x in r})) for h,r in hashes.items() if len({x["AssetId"] for x in r})>1]
save("texture_duplicate_evidence.json",dict(Basis="Prior conversion manifest file SHA256, linked only where current mesh and map ID match. Not a fresh download/content hash of Roblox CDN assets.",Groups=duplicates))
groups=defaultdict(list)
for e in effects["Records"]:
    p=e["Path"].split(".")
    if p[0]=="ReplicatedStorage": key=".".join(p[:3])
    elif p[:3]==["Workspace","World2Map","TrainingArea"] and len(p)>4: key=".".join(p[:5])
    elif p[:2]==["Workspace","Treadmills"]: key=".".join(p[:3])
    else:key=".".join(p[:2])
    groups[key].append(e)
summary=[]
for path, es in sorted(groups.items()):
    pe=[e for e in es if e["Class"]=="ParticleEmitter"]
    on=[e for e in pe if e.get("Enabled")]
    lifetimes=[v for e in on for v in e.get("Lifetime",[])]
    sizes=[k["Value"]+k.get("Envelope",0) for e in on for k in e.get("Size",[])]
    lights=[e for e in es if e["Class"].endswith("Light")]
    summary.append(dict(Path=path,ParticleEmitters=len(pe),EnabledParticles=len(on),AuthoredEnabledRateSum=round(sum(e.get("Rate",0) for e in on),3),
        EnabledLifetimeMin=min(lifetimes,default=None),EnabledLifetimeMax=max(lifetimes,default=None),
        MaxAuthoredSizePlusEnvelope=max(sizes,default=None),Beams=sum(e["Class"]=="Beam" for e in es),
        Trails=sum(e["Class"]=="Trail" for e in es),Lights=len(lights),EnabledLights=sum(bool(e.get("Enabled")) for e in lights),
        ShadowLights=sum(bool(e.get("Shadows")) for e in lights),Highlights=sum(e["Class"]=="Highlight" for e in es),
        UniqueParticleTextures=len({e["Texture"] for e in pe if e.get("Texture")})))
csvout("effect_summary.csv",summary)
save("highest_authored_emitters.json",sorted([e for e in effects["Records"] if e["Class"]=="ParticleEmitter" and e.get("Enabled")],key=lambda e:e.get("Rate",0),reverse=True)[:15])
gui=extra["WorldGUI"]
save("summary.json",dict(
    SourceComparisonCount=len(read(OUT/"source_comparison.json")),
    SourceMismatches=[r["Path"] for r in read(OUT/"source_comparison.json") if not r["SourceEqualsLocal"]],
    Exhibits=len(exhibits),RegisteredModels=len(dumbbells["Libraries"]),
    ExhibitBaseParts=sum(len(e["Parts"]) for e in exhibits.values()),
    UniqueDumbbellMeshes=len({r["MeshId"] for r in rows if r["MeshId"]}),
    UniqueDumbbellMapIds=len(mapids),SourceTriangleRecordCount=len(verified_source_triangles),
    SourceTriangleRange=[min(verified_source_triangles),max(verified_source_triangles)],
    SourceTriangleSumAll23DistinctModels=sum(verified_source_triangles),
    SourceMapHashRecordsLinkedToCurrentIds=sum(len(v) for v in hashes.values()),
    DuplicateSourceFileHashesWithDifferentCurrentAssetIds=len(duplicates),
    EffectInventoryRecords=len(effects["Records"]),EffectInventoryExpected=effects["Total"],
    WorldGUIs=len(gui),EnabledWorldGUIs=sum(g["Enabled"] for g in gui),
    AlwaysOnTopGUIs=sum(g["AlwaysOnTop"] for g in gui),
    WorldGUIMaxDistanceDistribution=dict(Counter("infinity" if isinstance(g["MaxDistance"],dict) and g["MaxDistance"].get("v")=="inf" else str(g["MaxDistance"]) for g in gui)),
    PhysicsGroups=extra["PhysicsGroups"],
    Cautions=["Edit inventory is not the visible/streamed/active runtime population.",
              "Authored Rate sums are not measured particles per second.",
              "Source triangulation is historical conversion metadata, not rendered mesh LOD.",
              "Texture dimensions/PNG bytes do not establish runtime memory."]))
print(json.dumps(read(OUT/"summary.json"),ensure_ascii=False,indent=2))
