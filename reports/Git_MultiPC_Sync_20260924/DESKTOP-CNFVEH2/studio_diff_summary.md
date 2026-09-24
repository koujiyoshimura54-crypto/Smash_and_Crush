# Studio/source comparison

All 482 Script/LocalScript/ModuleScript sources were read from the connected Edit DataModel, not from old reports. 419 paths were absent from src; none of the 63 existing source paths was Studio-missing. Seven duplicated sandbox paths are separately suffixed __duplicate2; Windows-incompatible/empty name components are percent-encoded. Original DataModel path components are retained in the manifest.

## Semantic differences from the local files at start

- ItemEffectHUDClient: Fire/Ice/Electric use 123468572441838 / 90857153952000 / 95738063615255, not ItemMaster lookups. Preserved current Studio IDs without judging intended versions.
- InventoryPanelClient: InventorySavePending message added in Studio.
- AuraConfig: Studio bonuses/prices/templates differ (Pink 5/30, Purple 10/75, Yellow 30/200, Green 50/500, Blue 150/1250, Red 500); Blue includes additional array entries. No balance correction performed.
- PlayerDataService: Studio contains finite pending-item retry delays 1/2/4/8, metadata checks and diagnostic warning code. No DataStore reads/writes executed by this audit.
- DailyRewardsClient: Studio contains mojibake bullet strings; copied exactly.
- CombatClient: initial local uncommitted Trophy sizing/distance/offset already matches Studio; included.
- Additional changed files differ by BOM/end-of-file whitespace. Native exported source was preserved.

EnemyManager, CombatClient, Stage01AppearanceClient, PlayerDataService, DumbbellService, InventoryPanelClient, EnemyDropGachaClient, localization-related scripts, World2 Configs and all external/archived scripts are represented in the source manifest. Stage01AppearanceClient/DumbbellService and many other current scripts previously lacked src files.

## Non-source state

scene_roots.json lists current top-level scene roots and all 11 original SCP models. Native local scene-instances.rbxm contains Models, attributes, pivots, collider/trigger parts and appearance assets. SCP-131 remains at ServerStorage.World2SCPAssets.SourceModels.SCP-131. SourceModels and ReservedNPCDisplays/ReservedPlaceholders are retained. GeneratedMap/TrainingArea and Treadmill locations were not moved. No ForceField/WallCombatTrigger, PersonalBossCollider, shared boss display, or gameplay logic was changed in Studio.

## Localization

Repository localization/GameLocalizationTable.csv: 208 rows, 9,194 bytes, SHA-256 F1E2251FBC06CA0E3B4D77975FE7BC0282CE453036245035A2B7CB4AE9D0B52A; unchanged.
Downloads candidate tables contain 35 and 192 rows (September 19), versus repository September 22. They were not used to overwrite the repository. The 158-row missing-entry and 313-row source-audit CSVs are reports, not substitute tables. All four candidates remain local.
Studio contains zero LocalizationTable instances; Cloud table contents were not retrievable through this local Instance audit, so Cloud/latest CSV equality is unverified. No localization modifications or upload occurred.

