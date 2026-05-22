---
name: deploy
description: Deploy a browser game to GitHub Pages and register it on sub.games. This is an internal skill used after /subgames SDK integration completes — do not invoke for general deployment. Triggers automatically when sub.games SDK integration finishes and the game needs to be deployed and registered.
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch"]
compatibility: Requires internet access and GitHub CLI authentication. Uses GitHub Pages for hosting and the sub.games API for game registration.
metadata:
  author: Playable Intelligence
  version: 1.0.0
---

# Deploy & Register on sub.games

Deploy a sub.games-integrated browser game to GitHub Pages and register it on the platform. This skill runs after `/subgames` SDK integration is complete.

**Only use this for vanilla/CDN browser games** (no server SDK). If the game uses `@subgames/server-sdk`, the creator handles their own hosting and registration.

## Instructions

### Step 1: Build the game

```bash
npm run build
```

If there's no build step (plain HTML game), skip to Step 2.

Identify the output directory — usually `dist/` for Vite/webpack or the project root for plain HTML.

### Step 2: Deploy to GitHub Pages

Check that GitHub CLI is available and authenticated:

```bash
gh auth status
```

If not authenticated, run:

```bash
gh auth login
```

Create or reuse a public GitHub repo for the static build, push the files, and enable GitHub Pages from the branch root:

```bash
cd <output-directory>
git init
git add .
git commit -m "Deploy game"
gh repo create <repo-name> --public --source=. --push
BRANCH=$(git branch --show-current)
OWNER=$(gh api user --jq '.login')
gh api repos/$OWNER/<repo-name>/pages -X POST --input - <<< "{\"build_type\":\"legacy\",\"source\":{\"branch\":\"$BRANCH\",\"path\":\"/\"}}"
gh api repos/$OWNER/<repo-name>/pages --jq '.html_url'
```

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

### Step 4: Verify embeddability

Before registering, confirm the deployed site can be embedded by sub.games:

```bash
curl -I <deployed-url>
```

If the response includes `X-Frame-Options: DENY`, `X-Frame-Options: SAMEORIGIN`, or a `Content-Security-Policy` `frame-ancestors` rule that excludes `sub.games`, stop and tell the creator GitHub Pages is not embeddable for this project and they need a different host.

### Step 5: Capture a real screenshot for registration

Do not use a blank placeholder image. Capture the actual deployed game with Playwright:

```bash
npx playwright screenshot <deployed-url> /tmp/subgames-registration.png
```

Use the saved screenshot as the `image` in the registration request.

### Step 6: Register on sub.games

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
  -H "Authorization: $AUTH_HEADER" \
  -F "name=<game-name>" \
  -F "description=<game-description>" \
  -F "gameUrl=<deployed-url>" \
  -F "platform=web" \
  -F "isHtmlGame=true" \
  -F "iframable=true" \
  -F "visibility=public" \
  -F "image=@/tmp/subgames-registration.png;type=image/png"
```

The response includes the game's `id` and `gameKey`. Update the SDK init call if the returned `gameKey` differs from what was set.

**If auth fails or the creator prefers manual setup**, direct them to the dashboard:

> Register your game manually:
> 1. Go to https://sub.games/publish
> 2. Click "Add Game"
> 3. Paste your game URL: `<deployed-url>`
> 4. Set the game name, description, and visibility
> 5. Copy the gameKey and update your SDK init if needed

### Step 7: Confirm

Tell the creator:

> Your game is deployed and registered!
>
> **Live URL**: `<github-pages-url>`
> **sub.games page**: `https://sub.games/game/<game-id>` (or check your dashboard at https://sub.games/publish)
> **Creator page**: `https://sub.games/@your-handle`
>
> Players can now discover your game, subscribe, and unlock gated features.

## Troubleshooting

### GitHub Pages deploy fails
- Check `gh auth status`
- Verify the repo is public if you're using free Pages
- Verify the output directory contains `index.html`
- Wait 1-2 minutes for Pages to finish building after enablement

### API registration fails with 401
- Token may be expired — get a fresh one from the sub.games dashboard
- Regenerate the HMAC header immediately before the request

### Game loads but SDK doesn't connect
- Verify the `gameKey` matches what's registered on sub.games
- Check browser console for CORS errors — the game URL must match what was registered
