import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// npm install --no-save luau-web@1.4.0, or point LUAU_WEB_MODULE to its index.js.
const runtime = process.env.LUAU_WEB_MODULE;
const { LuauState } = runtime ? await import(pathToFileURL(runtime).href) : await import('luau-web');
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const files = {
 BeforeRequirements:'tests/EarlyGameBalance/fixtures/LevelRequirementsBefore.luau',
 AfterRequirements:'src/ReplicatedStorage/Config/LevelRequirements.luau',
 BeforeBossConfig:'tests/EarlyGameBalance/fixtures/World1BossConfigBefore.luau',
 AfterBossConfig:'src/ReplicatedStorage/Config/World1BossConfig.luau',
 Rebirth:'src/ReplicatedStorage/Config/RebirthConfig.luau',
 Auto:'src/ReplicatedStorage/Config/AutoTapConfig.luau',
 BossBehavior:'src/ReplicatedStorage/Config/BossBehaviorConfig.luau',
};
const state=await LuauState.createAsync();
try {
 let code='';
 for (const [name,p] of Object.entries(files)) {
  const s=read(p);state.loadstring(s,'@'+p,true);
  code+=`local ${name}=(function()\n${s}\nend)()\n`;
 }
 state.loadstring(read('src/StarterPlayer/StarterPlayerScripts/Tutorial/TutorialGuideClient.client.luau'),'@TutorialGuideClient.client.luau',true);
 const progression=process.env.LEVEL_PROGRESSION_SOURCE
  ? fs.readFileSync(process.env.LEVEL_PROGRESSION_SOURCE,'utf8')
  : read('tests/EarlyGameBalance/fixtures/LevelProgressionBefore.luau');
 code+=`local function MakeProgression(requirements)\nlocal game={ReplicatedStorage={Config={LevelRequirements='Requirements'}}}\nlocal function require() return requirements end\n${progression}\nend\n`;
 code+=`local function MakeCombat(config)\nlocal refs=setmetatable({WaitForChild=function(_,name) return name end},{__index=function(_,k) return k end})\nlocal game={ReplicatedStorage={Config=refs},ServerScriptService={Services=refs}}\nfunction game:GetService(name) return self[name] end\nlocal modules={World1BossConfig=config,CombatConfig={AttackInterval=.8},StrengthManager={GetLevel=function() return 1 end},ItemService={GetGloveBossDamageBonus=function(p) return p.glove or 0 end}}\nlocal function require(name) return assert(modules[name],name) end\nlocal wall=(function()\n${read('src/ServerScriptService/World/Stage1WallManager.luau')}\nend)()\nlocal boss=(function()\n${read('src/ServerScriptService/World/BossCombatService.luau')}\nend)()\nreturn wall,boss\nend\n`;
 code+=read('tests/EarlyGameBalance/Checks.luau');
 const [checks,recommendedStrength,bossHits,worstIdealAutoSeconds,lethalSeconds,attackCountModel]=await state.loadstring(code,'@early-game-balance-checks',true)();
 console.log(JSON.stringify({kind:'Luau-WASM with service adapters; not Roblox Play',checks,progressionSource:process.env.LEVEL_PROGRESSION_SOURCE||'tracked 2026-09-15 snapshot, current live source must be checked',recommendedStrength,bossHits,worstIdealAutoSeconds,lethalSeconds,attackCountModel},null,2));
} finally { state.destroy(); }
