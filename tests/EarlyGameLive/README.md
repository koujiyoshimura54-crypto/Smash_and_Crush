# Current canonical Studio verification fixtures

These files are temporary native Play fixtures for PR #1, not shipping game dependencies. They require Place126576845524886 and the memory isolation installed by InstallIsolation.luau. Never run them against production persistence. The adapter blocks real payments and external writes; fresh native test sessions start with empty memory stores.

- Route.client.luau / Observer.server.luau: create ReplicatedStorage.__EarlyQARoute with State (RemoteFunction), Report (RemoteEvent), attributes ExpectedPlayers=3, Variant=Before or After, Repetition, Multiplayer=true, HoldOnComplete=false. Install the observer as a temporary server Script and the driver as a temporary StarterPlayer LocalScript. Native StudioTestService.ExecuteMultiplayerTestAsync(3,{}) starts real clients; EndTest returns the JSON result.
- The route driver calls the existing hatch pressed callback through a temporary __EarlyQAPress alias on HatchClient. Preserve that ModuleScript's exact Source in a backup, append the alias before return, and restore its exact Source afterward. Do not ship the alias or bypass the animation.
- HoldOnComplete enables extra ordinary movement/Back/natural-death actions after the timed run. Export Result before the connector's300s timeout, then call EndTest on the test server. Extra action time is not a benchmark time.
- Boundary.server.luau / Boundary.client.luau: use ReplicatedStorage.__EarlyQABoundary.Request (RemoteFunction). These deliberately seed existing save boundaries, then use ordinary Tap input, real HUD, native save retry and memory reload. They are separate from the fresh normal-route benchmark.
- FaultControl.server.luau provides scoped memory fault controls for delayed/replayed TimeRewards. AttributeOrder.client.luau deliberately staggers local attribute mirrors to test the intro guide; it is not actual packet loss.
- VisualRoute.client.luau is a separate fresh ordinary Stage1 route that pauses for a screenshot before Trophy. Its pause excludes it from timing comparisons. Resume through the fixture's Resume attribute.
- VisualObserver.server.luau records that separate route and its memory save/reload plus confirmed-reward replay check.
- analyze.py reads the accepted raw run JSON and writes CSV, individual-run tables and aggregate/matched-equipment summaries. RNG is never forced; aggregate sample skew must not be mistaken for a Config change.

Cleanup order: stop all test Play sessions; restore any temporary baseline Source substitution; restore HatchClient; remove route/boundary fixture scripts and folders; run RemoveIsolation.luau. It asserts every redirected Source still equals the installed test substitution before restoring the exact saved Source. Verify no __EarlyQA objects or source references remain and canonical Studio is unsaved Edit. Never Save/Publish or write back an rbxl.

See reports/EarlyGameLive_20261111/REPORT.md for actual runs, failures, limits and acceptance status.
