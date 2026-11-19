"""Generate an isolated Luau suite for execute_luau(Edit). Does not connect or run Play.

python tests/EngagementOffline.py core [--output path]
Suites: core, adapter, save, rewards. Execute generated code via the existing Studio
Edit connection. Source is compiled with injected services, never require(live module).
No test needs real DataStore/Secret/HTTP, purchases, invites or notification prompts.
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATHS = {
    "Config": "src/ReplicatedStorage/Config/EngagementConfig.luau",
    "State": "src/ServerScriptService/Services/OfflineNotificationState.luau",
    "Worker": "src/ServerScriptService/Services/OfflineNotificationWorker.luau",
    "Service": "src/ServerScriptService/Services/OfflineNotificationService.luau",
    "Prompts": "src/ReplicatedStorage/Modules/EngagementPrompts.luau",
    "Client": "src/ReplicatedStorage/Modules/EngagementClient.luau",
    "RewardConfig": "src/ReplicatedStorage/Config/StrengthRewardConfig.luau",
    "RewardState": "src/ServerScriptService/Services/StrengthRewardState.luau",
    "Ownership": "src/ServerScriptService/Services/PlayerDataOwnership.luau",
    "PlayerData": "src/ServerScriptService/Services/PlayerDataService.luau",
}
SUITES = {
    "core": ("tests/EngagementNotifications.spec.luau", ["Config", "State", "Worker", "Prompts", "RewardConfig", "RewardState", "Ownership"]),
    "adapter": ("tests/EngagementAdapter.spec.luau", ["Config", "State", "Worker", "Service", "Prompts", "Client", "RewardConfig"]),
    "save": ("tests/EngagementSaveHook.spec.luau", ["Config", "State", "RewardConfig", "RewardState", "PlayerData"]),
}


def read(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")


def build(suite):
    if suite == "rewards":
        paths = {
            "Config": PATHS["RewardConfig"], "State": PATHS["RewardState"],
            "Ownership": PATHS["Ownership"],
            "Requirements": "src/ReplicatedStorage/Config/LevelRequirements.luau",
            "Progress": "src/ReplicatedStorage/Modules/LevelProgression.luau",
            "Persistence": "src/ServerScriptService/Services/StrengthRewardPersistence.luau",
            "Test": "tests/StrengthRewards.spec.luau",
            "OwnershipTest": "tests/StrengthRewardOwnership.spec.luau",
        }
        sources = {k: read(v) for k, v in paths.items()}
        result = '{Rewards=assert(loadstring(s.Test,"Rewards.spec"))()(s),Ownership=assert(loadstring(s.OwnershipTest,"Ownership.spec"))()(s)}'
    else:
        spec, keys = SUITES[suite]
        sources = {k: read(PATHS[k]) for k in keys}
        if "PlayerData" in sources:
            source = sources["PlayerData"]
            start = source.index("function PlayerDataService.Save(")
            end = source.index("-- Called only by EnemyManager", start)
            sources["PlayerData"] = source[start:end] + "-- Called only by EnemyManager"
        sources["Test"] = read(spec)
        result = 'assert(loadstring(s.Test,"Engagement.spec"))()(s)'
    encoded = json.dumps(json.dumps(sources, ensure_ascii=False), ensure_ascii=False)
    return (
        'assert(not game:GetService("RunService"):IsRunning(),"Edit fixture only")\n'
        'local H=game:GetService("HttpService")\n'
        f'local s=H:JSONDecode({encoded})\n'
        f'return H:JSONEncode({result})\n'
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", choices=[*SUITES, "rewards"])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    code = build(args.suite)
    if args.output:
        args.output.write_text(code, encoding="utf-8")
    else:
        # Avoid Windows console's legacy encoding when passed through tooling.
        import sys
        sys.stdout.buffer.write(code.encode("utf-8"))
