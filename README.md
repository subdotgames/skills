# sub.games Skills for Claude Code

Integrate [sub.games](https://sub.games) subscriptions into browser games — tier-gated features, subscribe prompts, and recurring revenue for game creators.

## What is sub.games?

sub.games is Substack for games. Creators gate content behind subscription tiers (Free / Supporter / Founder) and earn recurring revenue from fans.

## Installation

```bash
npx skills add subdotgames/skills
```

## Skill Contents

| Skill | Description |
|-------|-------------|
| [sub.games SDK Integration](skills/subgames/SKILL.md) | Add the `@subgames/sdk` to a browser game, set up tier-gating, pause/unpause handling, and sparkle markers |
| [Deploy & Register](skills/deploy/SKILL.md) | Deploy a game to GitHub Pages and register it on sub.games |

### References

| Topic | Description |
|-------|-------------|
| [SDK API Reference](skills/subgames/references/sdk-api.md) | Complete `@subgames/sdk` API reference |
| [Framework Patterns](skills/subgames/references/framework-patterns.md) | Framework-specific pause/unpause and integration patterns |

### Scripts

| Script | Description |
|--------|-------------|
| [Validate Integration](skills/subgames/scripts/validate-integration.sh) | Verify SDK install, init call, pause handlers, and tier gates |
| [Auth Helper](skills/subgames/scripts/subgames-auth.js) | sub.games API authentication helper |

## Quick Start

After installing the skill, tell Claude:

> "Add sub.games subscriptions to my game"

Claude will:
1. Detect your game framework (Phaser, Three.js, Pixi.js, Canvas, plain HTML, and more)
2. Ask which features to gate behind each tier
3. Install and initialize the `@subgames/sdk`
4. Wire up pause/unpause for subscribe modals
5. Add `requireTier()` gates and sparkle markers
6. Validate the integration

### SDK (npm)

```js
import { SubGamesSDK } from '@subgames/sdk';

const subgames = SubGamesSDK.init({
  gameKey: 'your-game-slug',
  overlay: true,
});

subgames.on('pause', () => { /* pause game loop */ });
subgames.on('unpause', () => { /* resume game loop */ });
```

### SDK (CDN)

```html
<script src="https://sdk.sub.games/sdk.js"></script>
<script>
  const subgames = SubGamesSDK.init({
    gameKey: 'your-game-slug',
    overlay: true,
  });
</script>
```

## Compatibility

- **Games**: Any browser-based game (Phaser, Three.js, Pixi.js, Canvas, plain HTML, and more)
- **Install methods**: npm or CDN script tag
- **Requirements**: Node.js 20+ for npm installs

## Resources

- [sub.games Website](https://sub.games)
- [Creator Dashboard](https://sub.games/publish)

## License

MIT
