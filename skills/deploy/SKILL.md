---
name: deploy
description: Deploy a browser game to here.now and register it on sub.games. This is an internal skill used after /subgames SDK integration completes — do not invoke for general deployment. Triggers automatically when sub.games SDK integration finishes and the game needs to be deployed and registered.
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch"]
compatibility: Requires internet access. Uses the here-now skill for hosting and the sub.games API for game registration.
metadata:
  author: Opus Game Labs
  version: 1.0.0
---

# Deploy & Register on sub.games

Deploy a sub.games-integrated browser game to here.now and register it on the platform. This skill runs after `/subgames` SDK integration is complete.

**Only use this for vanilla/CDN browser games** (no server SDK). If the game uses `@subgames/server-sdk`, the creator handles their own hosting and registration.

## Instructions

### Step 1: Build the game

```bash
npm run build
```

If there's no build step (plain HTML game), skip to Step 2.

Identify the output directory — usually `dist/` for Vite/webpack or the project root for plain HTML.

### Step 2: Deploy to here.now

Check if the `here-now` skill is available:

```bash
ls ~/.agents/skills/here-now/scripts/publish.sh 2>/dev/null && echo "here-now available" || echo "not installed"
```

**If here-now is available:**

```bash
~/.agents/skills/here-now/scripts/publish.sh <output-directory>/
```

This returns a live URL like `https://<slug>.here.now/`.

**If here-now is NOT available**, try npx:

```bash
npx @anthropic-ai/here-now publish <output-directory>/
```

**CRITICAL**: Tell the user about the 24-hour claim window:

> Your game is live at `https://<slug>.here.now/`
>
> **IMPORTANT**: Anonymous deploys expire in 24 hours. Visit the claim URL shown above to create a free here.now account and keep the site permanently. The claim token is only shown once.

Save the deployed URL for Step 3.

### Step 3: Update the gameKey

If the game was using a placeholder `gameKey` (like `'your-game-slug'`), now is the time to set the real one. The `gameKey` should be a URL-friendly slug for the game (e.g., `'my-platformer'`, `'space-shooter'`).

Update the `SubGamesSDK.init()` call:

```js
const subgames = SubGamesSDK.init({
  gameKey: 'actual-game-slug',
  overlay: true,
});
```

Rebuild and redeploy if the gameKey changed.

### Step 4: Register on sub.games

**Check for stored credentials:**

```bash
node scripts/subgames-auth.js status
```

**If not authenticated**, run the auth flow:

```bash
node scripts/subgames-auth.js
```

This opens the browser to sub.games where the creator logs in. Credentials are stored locally at `~/.subgames-credentials.json`.

**Once authenticated**, register the game via HMAC-authenticated API call:

```bash
AUTH_HEADER=$(node scripts/subgames-auth.js hmac POST /games)
curl -X POST https://api.sub.games/games \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH_HEADER" \
  -d '{
    "name": "<game-name>",
    "description": "<game-description>",
    "gameUrl": "<deployed-here-now-url>",
    "platform": "WEB",
    "isHTMLGame": true,
    "iframable": true,
    "visibility": "public"
  }'
```

The response includes the game's `id` and `gameKey`. Update the SDK init call if the returned `gameKey` differs from what was set.

**If auth fails or the creator prefers manual setup**, direct them to the dashboard:

> Register your game manually:
> 1. Go to https://sub.games/publish
> 2. Click "Add Game"
> 3. Paste your game URL: `<deployed-url>`
> 4. Set the game name, description, and visibility
> 5. Copy the gameKey and update your SDK init if needed

### Step 5: Confirm

Tell the creator:

> Your game is deployed and registered!
>
> **Live URL**: `<here-now-url>`
> **sub.games page**: `https://sub.games/game/<game-id>` (or check your dashboard at https://sub.games/publish)
> **Creator page**: `https://sub.games/@your-handle`
>
> Players can now discover your game, subscribe, and unlock gated features.

## Troubleshooting

### here-now publish fails
- Check internet connection
- Verify the output directory exists and contains `index.html`
- Try `npx serve <output-dir>` locally first to confirm the build works

### API registration fails with 401
- Token may be expired — get a fresh one from the sub.games dashboard
- Ensure the `Authorization` header uses `Bearer <token>` format

### Game loads but SDK doesn't connect
- Verify the `gameKey` matches what's registered on sub.games
- Check browser console for CORS errors — the game URL must match what was registered
