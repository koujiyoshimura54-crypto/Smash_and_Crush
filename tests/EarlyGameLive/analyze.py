"""Summarize actual native route events; never substitute arithmetic for Play."""
import csv,json,pathlib,statistics
root=pathlib.Path(__file__).resolve().parents[2]
report=root/"reports/EarlyGameLive_20261111"
rows=[]
for file in sorted(report.glob("*-[0-9].json")):
    data=json.loads(file.read_text(encoding="utf-8"))
    for run in data["Runs"]:
        events=run["Events"]
        def event(name): return next(e for e in events if e["Kind"]==name)
        op=event("Operable")["Seconds"]
        def elapsed(name): return event(name)["Seconds"]-op
        row=dict(Variant=run["Variant"],Repetition=run["Repetition"],Mode=run["Mode"],Success=run["Success"],
                 OperableFromCommonStart=op,LoadedSecondsAtOperable=event("Operable")["State"]["TimeRewards"]["ElapsedSeconds"])
        for name in ["Level2","Level3","Level4","BossDefeated1","TrophyReturned1","FirstMerge","DumbbellEquipped","BossDefeated2","TrophyReturned2","FirstRebirth"]:
            if not any(e["Kind"]==name for e in events): continue
            e=event(name);row[name]=elapsed(name)
            if name in ["BossDefeated1","BossDefeated2"]:
                for field in ["Strength","Level","Progress","EquippedDumbbell"]:row[name+"_"+field]=e["State"][field]
        row["Stage1Combat"]=event("BossDefeated1")["Seconds"]-event("FirstStage1Start")["Seconds"]
        row["Stage2Phase"]=event("BossDefeated2")["Seconds"]-event("TrophyReturned1")["Seconds"]
        row["Stage2Corridor"]=event("BossDefeated2")["Seconds"]-event("FirstStage2Start")["Seconds"]
        row["AfterStage2ToRebirth"]=event("FirstRebirth")["Seconds"]-event("BossDefeated2")["Seconds"]
        row["MergeResults"]="; ".join(str(e["Details"]["Material"])+":"+str(e["Details"]["Result"]) for e in events if e["Kind"] in ["FirstMerge","HigherMerge"])
        row["GearPathToStage2"]=" -> ".join(e["Details"]["Result"] for e in events if e["Kind"] in ["FirstMerge","HigherMerge"] and e["Seconds"]<event("BossDefeated2")["Seconds"])
        row["GearAtRebirth"]=event("Level10")["State"]["EquippedDumbbell"]
        row["RewardClaims"]="; ".join(str(e["Details"])+"@"+str(round(e["State"]["TimeRewards"]["ElapsedSeconds"],2)) for e in events if e["Kind"]=="TimeReward")
        row["Deaths"]=event("Complete")["Details"]["Deaths"] if run["Success"] else None
        rows.append(row)
rows.sort(key=lambda r:(r["Variant"],r["Repetition"],r["Mode"]))
with (report/"route-times.csv").open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
summary={}
for mode in ["Auto","Manual","Mixed"]:
    group={v:[r for r in rows if r["Mode"]==mode and r["Variant"]==v] for v in ["Before","After"]}
    item={"Counts":{v:len(rs) for v,rs in group.items()}}
    for metric in ["BossDefeated1","Stage2Phase","Stage2Corridor","BossDefeated2","FirstRebirth","AfterStage2ToRebirth"]:
        means={v:statistics.mean(r[metric] for r in rs) for v,rs in group.items() if rs}
        item[metric]=means
        if len(means)==2:means["AfterBeforeRatio"]=means["After"]/means["Before"]
    summary[mode]=item
(report/"timing-summary.json").write_text(json.dumps(summary,indent=2)+"\n",encoding="utf-8")
matched=[]
for mode in ["Auto","Manual","Mixed"]:
    for path in sorted({r["GearPathToStage2"] for r in rows if r["Mode"]==mode}):
        item={"Mode":mode,"GearPathToStage2":path}
        for variant in ["Before","After"]:
            rs=[r for r in rows if r["Mode"]==mode and r["Variant"]==variant and r["GearPathToStage2"]==path]
            item[variant+"Count"]=len(rs)
            item[variant+"Stage2Total"]=statistics.mean(r["BossDefeated2"] for r in rs) if rs else None
        if item["BeforeCount"] and item["AfterCount"]:
            item["AfterBeforeRatio"]=item["AfterStage2Total"]/item["BeforeStage2Total"]
        matched.append(item)
(report/"matched-gear.json").write_text(json.dumps(matched,indent=2)+"\n",encoding="utf-8")
lines=["# Per-run actual Play times","","Seconds from that client's Operable event. CSV/JSON include LV2/3, exact Strength/LV/progress, equipment, reward clocks and loading. These tables contain individual runs, not arithmetic simulations.",""]
for mode in ["Auto","Manual","Mixed"]:
    lines += ["## "+mode,"","| Variant / run | LV4 | Stage1 defeat | Stage2 phase | Stage2 defeat total | First Rebirth | Gear path to Stage2 |","|---|---:|---:|---:|---:|---:|---|"]
    for variant in ["Before","After"]:
        for r in rows:
            if r["Mode"]==mode and r["Variant"]==variant:
                lines.append("| "+variant+" "+str(r["Repetition"])+" | "+" | ".join(f'{r[k]:.2f}' for k in ["Level4","BossDefeated1","Stage2Phase","BossDefeated2","FirstRebirth"])+" | "+r["GearPathToStage2"]+" |")
    lines.append("")
(report/"RUNS.md").write_text("\n".join(lines).rstrip()+"\n",encoding="utf-8")
print(json.dumps(summary,indent=2))
