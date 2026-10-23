# PreMerge camera zoom bounds restored — 2026-10-23

The owner requested direct inspection of `C:\Users\kouji\Smash_and_Crush_PreMerge_20261003.rbxl`, then explicitly requested applying its settings. Read-only binary decoding found StarterPlayer.CameraMinZoomDistance=18 and CameraMaxZoomDistance=30. The reference SHA-256 is `b613d2c61617e004290bfbb2d153c3272739add6f7ef28b8a307d5560b25abee`; it remained unchanged after inspection. Its camera Source already used base18 and scale influence.15, and its saved FOV was70.

The prior delivery checked the Source calibration but missed the authored StarterPlayer properties. This follow-up changes only those two properties in the currently open Cloud-place Studio, PlaceId126576845524886 / UniverseId10765181857, from .5/128 to18/30. No Source or body-tier setting was changed. The earlier README describes the earlier delivery and is retained as historical evidence.

One ordinary native Studio Play, without service substitutions or profile-condition fixtures, confirmed:

| Measurement | Result |
|---|---:|
| Authored StarterPlayer minimum / maximum | 18 / 30 |
| Current character height multiplier | 1.175 |
| Expected automatic camera distance | 18.4725 |
| Actual CFrame-to-Focus distance | 18.472501754760743 |
| Runtime Player minimum / maximum after existing framing | 9.236249923706055 / 35.25 |
| Camera type / FOV | Custom / 70 |

The reduced runtime minimum is intentional existing behavior: `min(baseMinZoom, distance/2)`. The maximum is `baseMaxZoom * heightScale`. Restoring18/30 does not change the existing automatic-distance formula; it restores initialization and manual zoom bounds. No claim is made that this alone resolves every reported visual difference. No new scoped camera error or infinite-yield message was found; existing unrelated asset-authorization warnings remain.

Play was stopped. Final Edit readback confirms18/30, exact unchanged camera Source, and restored edit camera CFrame/Focus with unchanged development-GUI setting. The user Studio remains open and unsaved. Neither rbxl was written or reopened; no Studio Save/Publish occurred. Public-server behavior, all body tiers and further lifecycle regression were not retested for this two-property change.
