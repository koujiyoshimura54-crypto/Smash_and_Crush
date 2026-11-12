"""Render measured route CSVs without replacing any historical report."""
from pathlib import Path
import csv,json
root=Path(__file__).resolve().parents[2]/'reports/World1Stage1To5Balance_20261112'
def read(name):return list(csv.DictReader((root/name).open(encoding='utf8',newline='')))
def n(v):return f'{float(v):.2f}' if v not in ('',None) else '—'
def table(headers,rows):
 return '| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+'\n'.join('| '+' | '.join(map(str,r))+' |'for r in rows)+'\n'
runs=read('individual_runs.csv');agg=read('aggregates.csv');strata=read('equipment_strata.csv')
out=['# 通常ルート実Playの個別結果と集計\n',
 '単位は秒。Stage累計は共通操作開始基準、Stage区間は直前Stage初撃破からの経過時間。参加基準は別表。死亡・再生・合成を含む自然獲得ルートのみ。データ注入検証は含まない。\n',
 '操作開始・Operableは自動操作スクリプトの準備完了。一部クライアントで画面描画とClientPlayableが欠測しており、人間が画面を見て操作可能になった時刻とは同一視しない。物理・Remote・サービスはネイティブPlayで実行。詳細と未達の証拠検査は[REPORT](REPORT.md)を参照。\n']
for variant in ['Before','After']:
 rows=sorted([r for r in runs if r['Variant']==variant],key=lambda r:(r['Mode'],int(r['Repetition'])))
 out.append('## '+variant+'：操作開始から各Stage初撃破\n')
 out.append(table(['Mode','回','装備経路','S1','S2','S3','S4','S5','死亡','再試行','成功'],
  [[r['Mode'],r['Repetition'],r['EquipmentRoute'],*[n(r[f'Stage{i}FromOperable'])for i in range(1,6)],r['Deaths'],r['Retries'],r['Success']]for r in rows]))
 out.append('## '+variant+'：各Stage区間・Stage6最初の壁\n')
 out.append(table(['Mode','回','S1区間','S2区間','S3区間','S4区間','S5区間','S6壁1','追加帰還等を含む完了'],
  [[r['Mode'],r['Repetition'],*[n(r[f'Stage{i}Segment'])for i in range(1,6)],n(r['Stage6FirstWall']),n(r['CompleteSeconds'])]for r in rows]))
 out.append('## '+variant+'：参加からの累計\n')
 out.append(table(['Mode','回','スクリプト操作開始','S1','S2','S3','S4','S5','参加起点の精度'],
  [[r['Mode'],r['Repetition'],n(r['OperableFromJoin']),*[n(r[f'Stage{i}FromJoin'])for i in range(1,6)],r['JoinPrecision']]for r in rows]))
 out.append('## '+variant+'：再生の実時刻\n')
 out.append(table(['Mode','回','成立回数@操作開始からの秒'],
  [[r['Mode'],r['Repetition'],', '.join(str(x['Count'])+'@'+n(x['Seconds'])for x in json.loads(r['Rebirths']))]for r in rows]))
out.append('## 前後平均と速度比\n')
out.append('速度比=変更前平均÷変更後平均。1.50以上の区間だけ目標到達。少数・自然RNGの比較であり統計的な効果保証ではない。\n')
out.append(table(['Mode','Stage','前n/後n','前区間','後区間','区間比','区間1.5倍','前累計','後累計','累計比','累計1.5倍'],
 [[r['Mode'],r['Stage'],r['BeforeN']+'/'+r['AfterN'],n(r['BeforeSegment']),n(r['AfterSegment']),n(r['SpeedRatioSegment']),r['Reached1_5Segment']or'未比較',n(r['BeforeFromOperable']),n(r['AfterFromOperable']),n(r['SpeedRatioFromOperable']),r['Reached1_5FromOperable']or'未比較']for r in agg]))
out.append('## 同じ装備経路でのStage5比較\n')
out.append('同じ装備名でも獲得時刻・途中の所持品は一致しない。前後どちらかの標本がない経路は比率を出さない。追加4回目も含め、RNG結果を捨てていない。\n')
out.append(table(['Mode','装備経路','前n/後n','前S5','後S5','速度比'],[[r['Mode'],r['EquipmentRoute'],r['BeforeN']+'/'+r['AfterN'],n(r['BeforeStage5']),n(r['AfterStage5']),n(r['SpeedRatio'])]for r in strata]))
out.append('## 全回のイベント区間\n')
out.append('育成はTrainStart〜Endから内部の合成を控除。合成には合成所への移動と通常結果確認を含む。Trophy帰還には接近を含む。Stage6追加区間後までの全経路を対象とする。\n')
out.append(table(['版','Mode','回','育成（合成控除）','合成・装備','Trophy帰還','再生応答待ち'],[[r['Variant'],r['Mode'],r['Repetition'],n(r['TrainingExcludingMerge']),n(r.get('MergeEquip')),n(r.get('TrophyReturn')),n(r.get('Rebirth'))]for r in runs]))
out.append('## 4回目の排他的区間（Stage5初撃破まで）\n')
out.append('0.1秒間隔の観測。優先順は再生→合成→育成→帰還→戦闘→移動→待機。区間名称は行動状態であり、育成中の歩行は育成に含む。最初の観測前の端数は含まない。\n')
categories=['Training','Movement','Combat','MergeEquip','Rebirth','Return','Idle']
out.append(table(['版','Mode',*categories],[[r['Variant'],r['Mode'],*[n(r.get('ExclusiveToStage5_'+c))for c in categories]]for r in runs if r['Repetition']=='4']))
(root/'RUNS.md').write_text('\n'.join(out),encoding='utf8')
print(f'Rendered {len(runs)} individual routes; all records retained.')
