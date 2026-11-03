# Limited Egg Studio tester authorization — 2026-11-03

## Applied scope

Canonical live Edit DataModel: PlaceId `126576845524886`, UniverseId `10765181857`.
The live unsaved Sources were the baseline. Only these two production Sources changed:

- `ServerScriptService.Config.StudioDebugConfig`: added server-only `LimitedEggTestUserIds` containing **7467238848, 10591394123, 10653503502**.
- `ServerScriptService.Systems.Purchases.ReceiptService`: the existing shared Studio authorization predicate now reads that dedicated list; the client Ready/result-redelivery request also uses it.

Previously Limited Egg tests reused `ProductionCreatorUserIds`. That list and GamePass switches remain unchanged. Both new IDs therefore receive no creator/GamePass privilege. The same predicate covers Offer/Purchase, Receipt/retry, notification Ready and result acknowledgment. Pet grants still occur solely through the existing server receipt and fenced PlayerData transaction; hatch presentation still requires a committed saved result. Public paid-product processing, pools, quantity1, IDs, prices, eligibility/location checks, journal format and Studio store names are unchanged.

`ServerScriptService.Systems.Debug.StudioDebugController` and `ServerScriptService.Systems.Debug.StudioDebugService` already implement Studio-only, issuer-only `/setwin`; both live Sources were retained byte-for-byte. Their existing command scope was not expanded or restricted. No `/resetdata` operation or permission change was made.

## Focused verification

All native Play datastore/badge dependencies were replaced temporarily with memory adapters, Marketplace with a prompt recorder, and paid-random policy with a controlled fixture. No real purchase or external saved player data was used. Actual logged-in actor: **7467238848**. The two requested accounts were **not logged in**: their whitelist lookup IDs were simulated only in the temporary server test substitution, while receipt ownership/PlayerData retained the real actor identity.

| Check | Result |
|---|---|
| Pure shared predicate | All three IDs allowed in canonical Studio; outsider123456789 denied. Wrong Place, Universe or non-Studio store names denied. Studio-specific predicate false in public context. |
| Native W1 + W2 × each of the three allowed IDs | Six separate successful receipts; existing random pool used; exactly one owned individual per receipt. |
| Prompt cancellation / purchase-finished callback | Neither callback granted a Pet. Only the subsequent simulated Receipt granted it. |
| Duplicate Receipt | Granted decision repeated, additional Pet count0. Immutable saved result and PlayerData PurchaseId marker matched. |
| Actual client result consumer | All six notices accepted by existing `StandClient -> HatchClient.playCommittedLimited` exactly once; repeats returned `AlreadyShown`. All six journal records became `Granted, Presented=true` through existing acknowledgment. |
| Outsider | Offer, Purchase, Ready and Acknowledge returned `StudioDeveloperRequired`; Receipt stayed `NotProcessedYet`; no prompt/Pet. |
| Native `/setwin 1000`, then `/setwin 0` | Actual Debug.Execute changed own session and Win attribute0→1000→0. Visible `Players.yossy945.PlayerGui.StrengthGui.HUD.WinAmount.Main` changed to `1K`, then `0`. The hidden legacy WinLabel remained0 and was not used as display evidence. |
| Invalid values | Negative, fractional, nan, inf, exponent notation, >9007199254740991, missing argument and extra target-ID argument rejected without changing Win. |
| Other-player isolation | Separate dependency-isolated execution of the unchanged Debug module for each allowed ID kept a peer's Win77 unchanged; extra target rejected. This was a simulated peer, not a second real client. |
| Public debug guard | Unchanged Debug module executed with IsStudio=false returned `false, StudioOnly` before loading gameplay dependencies. |
| Storage | Native memory save used only `PlayerData_v1_Studio`, `DeveloperProductReceipts_v1_Studio` and existing Studio-suffixed ranking stores. No production store used. |

Client acknowledgments can temporarily collide with the existing0.75s request throttle; the fixture retried `PleaseWait` without changing production throttling. Final six grants and acknowledgments succeeded.

## Limits and cleanup

- Verified native server/client processing and GUI text properties; no physical clicks/chat typing, real target-account login, live Marketplace prompt/payment, production persistence/rejoin or screenshot-based hatch pixel acceptance.
- Existing asset-permission/availability warnings appeared for some hatch/Pet assets (including95256658378010,139190015780830,82687933211372,17387207972,89137136456777,7221927873 and the Images/wd alias). Result acceptance does not prove every texture/effect rendered. No asset IDs or permissions were changed.
- Stopped Play and removed all temporary fixtures, authorization-ID override and dependency substitutions. Verified **472** original Source hashes/Enabled states and **74** SoundIds against the post-change baseline. Debug service/controller unchanged; final two production Sources verified against intended live edits.
- Preserved other current unsaved work. Fetched and fast-forwarded the existing repository to remote `a5fd0db` before recording this task, without applying repository Sources back over Studio.
- Left canonical Studio in **unsaved Edit**. No Save, Publish, rbxl write, Studio shutdown, OS input, camera or window changes.
