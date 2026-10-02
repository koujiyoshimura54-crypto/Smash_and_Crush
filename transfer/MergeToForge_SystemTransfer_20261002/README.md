# MergeToForge System Transfer

旧Smash_and_CrushのWorld1 Systemを、Merge to Forgeの購入geometryへ移植するための引き継ぎ資料。

- Map Interface正本: [manifest/map_interface.md](manifest/map_interface.md)
- PC: **Y01**
- 再構築日: **2026-10-02**
- 根拠Source: Smash_and_Crush `origin/main` の `572edcf65a225f14ce83bad80717fc07c55e07f2`
- Studio staging: `ServerStorage.MergeToForge_LegacySystem`（休眠状態）
- 新Map Preview: `Workspace.MergeToForge_GameplayGeometryPreview`
- 次工程: **GeneratedMap互換化**。本書の未決事項を確認し、Previewを保持してClone側で対応する。

今回の成果物はdocumentationのみ。消失した前PCのmanifestを推測復元したものではない。GeneratedMap作成、Legacy起動、Play、Place Save、Publishは実施していない。

`World1Dependencies.rbxm` はこのcommitに含めない。既存Stagingのprogrammatic serialization可否・測定サイズ・対象範囲の注意はmap_interface.md参照。
