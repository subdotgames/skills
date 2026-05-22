---
name: subgames
description: Integrate sub.games subscriptions into a browser game — add the @subgames/sdk, set up tier-gating for features, and register on sub.games. Use when the user says "add subscriptions", "add sub.games", "monetize with subscriptions", "gate features", "add tier-gating", or "integrate sub.games SDK". Requires a deployed or local browser game. Do NOT use for server-side games without a browser client, native mobile apps, or general payment/Stripe integration (this is specifically for sub.games tiers).
argument-hint: "[path to game directory, or leave blank to use current dir]"
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch"]
compatibility: Browser games using Phaser, Three.js, Pixi.js, vanilla Canvas, or plain HTML. Requires npm or a script tag (CDN). Node.js 20+ for npm installs.
metadata:
  author: Playable Intelligence
  version: 1.0.0
license: MIT
---

# sub.games SDK Integration

Integrate [sub.games](https://sub.games) subscriptions into a browser game. sub.games is Substack for games — creators gate content behind subscription tiers (Free/Supporter/Founder) and earn recurring revenue from fans.

**What you'll get:**
1. The `@subgames/sdk` integrated into the game
2. Tier-gated features with subscribe prompts
3. Pause/unpause handling when modals appear
4. Sparkle emoji markers on gated UI elements
5. A registered game on sub.games (if credentials available)

For the full SDK API, consult `references/sdk-api.md`. For framework-specific pause/unpause patterns, consult `references/framework-patterns.md`.

## Instructions

### Step 0: Locate the game

Parse `$ARGUMENTS` to find the game project directory. If not provided, check the current working directory for a game project (look for `package.json` with game framework dependencies like Phaser, Three.js, Pixi.js, or a plain `index.html` with a canvas).

Read the project structure to understand:
- Entry point (`index.html`, `src/main.js`, `src/main.ts`, etc.)
- Build system (Vite, webpack, plain HTML)
- Game framework (Phaser, Three.js, Pixi.js, vanilla Canvas)
- Event system (EventBus, custom events, callbacks)

If no game project is found, stop and tell the user: "I couldn't find a game project here. Point me to the directory with your game's source code."

### Step 1: Ask about tier-gating

Ask the creator which features should be behind each tier:

> **Let's set up your subscription tiers.** Every game should have some free content to preserve virality. Which features should require a subscription?
>
> **Free tier** (email only): e.g., save progress, access past level 1
> **Supporter tier** ($3-8/mo): e.g., exclusive levels, special items/skins
> **Founder tier** ($150/yr VIP): e.g., everything + name in credits, early access
>
> Which features map to which tier? (Or tell me your game and I'll suggest a plan.)

If the creator describes their game without specifying tiers, suggest a sensible default:

- **Free**: Play the full base game. Prompt for email subscription after play.
- **Supporter**: Exclusive skins/cosmetics, bonus levels, save progress across sessions.
- **Founder**: Everything + name in credits, early access to new content.

Wait for confirmation before proceeding.

### Step 2: Install the SDK

**For npm/bundled projects:**

```bash
npm install @subgames/sdk
```

Then import in the game's entry point:

```js
import { SubGamesSDK } from '@subgames/sdk';
```

**For plain HTML games (no bundler):**

Add before `</head>` in `index.html`:

```html
<script src="https://sdk.sub.games/sdk.js"></script>
```

The CDN bundle is available as `window.SubGames.SubGamesSDK`.

### Step 3: Initialize the SDK

Add initialization to the game's entry point. The SDK needs a `gameKey` — the game's slug on sub.games.

```js
const subgames = SubGames.SubGamesSDK.init({
  gameKey: 'your-game-slug',
  overlay: true,
});

subgames.on('pause', () => {
  // Pause your game loop, audio, timers
});

subgames.on('unpause', () => {
  // Resume your game loop, audio, timers
});
```

**CRITICAL**: Find the game's actual pause/resume mechanism. Consult `references/framework-patterns.md` for Phaser, Three.js, Pixi.js, and Canvas examples. Common patterns:
- Phaser: `this.scene.pause()` / `this.scene.resume()`
- Three.js: set a `paused` flag checked in the render loop
- Canvas: `cancelAnimationFrame()` / re-call `requestAnimationFrame()`
- Custom: look for existing pause menu code and reuse that logic

### Step 4: Add tier-gating to features

Based on the creator's answers from Step 1, add `requireTier()` calls at the gate points.

**Pattern**: Call `requireTier()` when the player tries to access a gated feature. If they don't meet the tier, the SDK automatically shows a subscribe modal and pauses the game.

```js
async function startLevel(levelNumber) {
  if (levelNumber > 3) {
    const allowed = await subgames.requireTier('supporter', 'bonus levels');
    if (!allowed) return; // Modal shown, game paused
  }
  // ... load level
}

async function saveProgress() {
  const allowed = await subgames.requireTier('free', 'save progress');
  if (!allowed) return;
  // ... save
}
```

**Important guidelines:**
- `requireTier()` is async — always `await` it
- If it returns `false`, the subscribe modal is showing — don't proceed
- Place gates at natural decision points, not mid-action
- The second argument is a feature label shown in the subscribe prompt
- The SDK has a built-in 30-second timer that prompts non-subscribers — you don't need a manual timer

### Step 5: React to tier changes

Listen for `tierChange` to unlock content when the player subscribes mid-game:

```js
subgames.on('tierChange', (newTier) => {
  const rank = { none: 0, free: 1, supporter: 2, founder: 3 };
  if (rank[newTier] >= rank['supporter']) {
    unlockSupporterContent();
  }
});
```

### Step 6: Add sparkle emoji markers to UI

The sparkle emoji is the sub.games convention for gated features:

- No marker = free for everyone
- One sparkle = free tier (email)
- Two sparkles = supporter tier (paid)
- Three sparkles = founder tier (VIP)

```js
function getTierLabel(name, tier) {
  const sparkles = { none: '', free: ' ✨', supporter: ' ✨✨', founder: ' ✨✨✨' };
  return name + (sparkles[tier] || '');
}
```

Find all UI elements that display gated features (level selectors, shop items, menus) and add the appropriate sparkle count.

### Step 7: Build and verify

Run the build:

```bash
npm run build
```

**If the build fails**, check these common issues:
- `Cannot find module '@subgames/sdk'` → Run `npm install` again, check `package.json` has the dependency
- `SubGamesSDK is not defined` → For CDN usage, ensure the script tag is before your game script
- `SubGamesSDK.init is not a function` → Check you're importing from `'@subgames/sdk'`, not a wrong path
- TypeScript errors → The SDK ships type declarations; check your `tsconfig.json` includes `node_modules`

**Run the validation script** to programmatically check the integration:

```bash
bash scripts/validate-integration.sh [game-directory]
```

This checks: SDK installed, `init()` call present, `gameKey` configured, pause/unpause handlers wired, `requireTier()` calls exist, and sparkle markers present. Fix any FAIL items before proceeding.

**Manual verification checklist** — confirm each item:
1. Open browser console — no SDK-related errors on page load
2. `SubGamesSDK.init()` runs without throwing
3. Each `requireTier()` call is at the correct gate point (search for all `requireTier` in the codebase)
4. Pause/unpause events are wired to the game's actual loop (not generic stubs)
5. Sparkle markers appear on gated UI elements

### Step 8: Deploy and register (vanilla/CDN games only)

If the game is a **vanilla browser game** (no server SDK, no existing hosting), default to deploying it to GitHub Pages and registering it on sub.games once the integration passes validation. Use the `deploy` skill to handle this unless the creator explicitly says not to deploy yet.

If the game **already has hosting** or uses the **server SDK**, skip to Step 9 and tell the creator to register manually at https://sub.games/publish.

### Step 9: Confirm integration

Tell the creator what's active and the tier breakdown:

> Your game is integrated with sub.games!
>
> **Active:** Subscribe prompts (auto 30s + at gated features), tier-gating, pause on modals, sparkle markers, social overlay
>
> **Tiers:** [list each tier and its gated features]
>
> **Next steps:**
> - If this is a local vanilla browser game and the creator did not opt out, proceed directly to deployment on GitHub Pages and sub.games registration
> - If already hosted: register at https://sub.games/publish and set your gameKey
> - Share your creator page: `https://sub.games/@your-handle`

## Troubleshooting

### SDK doesn't load
- **CDN**: Verify the script tag is before your game script and has the correct URL
- **npm**: Run `npm ls @subgames/sdk` to confirm it's installed. Check the import path.
- **CORS**: If testing locally, use a dev server (`npx serve` or `vite dev`), not `file://`

### Subscribe modal doesn't appear
- Check that `requireTier()` is actually being called (add a `console.log` before it)
- Verify the player's tier is below the required tier — use `await subgames.getPlayerTier()` to debug
- The 30-second auto-prompt only fires for `tier === 'none'` (completely unauthenticated)

### Game doesn't pause when modal opens
- Confirm `pause`/`unpause` event handlers are registered before any `requireTier()` calls
- Check that your pause logic actually stops the game loop — test by calling `subgames.pause()` manually in the console

### Build fails after adding SDK
- **Vite**: No extra config needed — `@subgames/sdk` is ESM-compatible
- **Webpack**: May need to add `@subgames/sdk` to `transpileModules` if using an old version
- **TypeScript**: The SDK ships `.d.ts` files. If types aren't resolving, add `"node_modules/@subgames/sdk"` to `typeRoots`

## Examples

### Example 1: Phaser platformer with bonus levels

User says: "Add sub.games to my Phaser platformer"

1. Detect Phaser in `package.json`, find the main scene
2. Ask which levels are free vs paid
3. `npm install @subgames/sdk`
4. Add `SubGamesSDK.init()` in the Boot scene's `create()`
5. Wire `scene.pause()`/`scene.resume()` to SDK pause events
6. Add `requireTier('supporter', 'bonus levels')` in the level select handler for levels 4+
7. Add sparkle markers to level select buttons
8. Run validation script, build, confirm

### Example 2: Plain HTML canvas game with premium skins

User says: "I want to gate the skins in my canvas game behind subscriptions"

1. Detect `index.html` with `<canvas>`, no bundler
2. Ask which skins are free vs supporter vs founder
3. Add CDN script tag
4. Add `SubGamesSDK.init()` after DOM ready
5. Wire `cancelAnimationFrame`/`requestAnimationFrame` to pause events
6. Add `requireTier('supporter', 'premium skins')` before equipping a paid skin
7. Add sparkle markers to the skin picker UI
8. Run validation script, confirm

## Performance Notes

- Take your time to read the game's codebase before making changes. Understanding the existing pause mechanism and event system is more important than speed.
- Quality is more important than speed — a broken pause handler causes a worse experience than taking an extra step to verify.
- Do not skip the validation step. Run `scripts/validate-integration.sh` to catch issues programmatically.
- If unsure about the game's architecture, ask the user rather than guessing.
