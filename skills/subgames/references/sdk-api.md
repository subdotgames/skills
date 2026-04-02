# @subgames/sdk API Reference

## SubGamesSDK.init(config)

Creates and returns an SDK instance.

```js
const sdk = SubGamesSDK.init({
  gameKey: 'your-game-key',  // Required. Unique key from the dashboard.
  apiUrl: 'https://api.sub.games',  // Optional. API endpoint.
  appUrl: 'https://sub.games',      // Optional. Platform URL.
  overlay: true,                     // Optional. Enable social overlay.
});
```

## Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getPlayerTier()` | `Promise<PlayerTier>` | Get the player's current tier (`none`, `free`, `supporter`, `founder`) |
| `requireTier(tier, feature?)` | `Promise<boolean>` | Check tier, prompt subscribe if insufficient. Returns `true` if met. |
| `isLoggedIn()` | `boolean` | Whether the player has a valid session |
| `getPlayer()` | `Promise<PlayerInfo \| null>` | Get `{ id, email, displayName, avatarUrl }` |
| `promptLogin()` | `Promise<void>` | Open login popup. Pauses game automatically. |
| `promptSubscribe(tier?, feature?)` | `Promise<void>` | Open subscribe popup. Pauses game automatically. |
| `pause()` | `void` | Manually pause the game |
| `unpause()` | `void` | Manually unpause the game |
| `isPaused()` | `boolean` | Check if the game is paused |
| `getToken()` | `string \| null` | Get the player's auth token |
| `setToken(token)` | `void` | Set auth token (external auth scenarios) |
| `logout()` | `void` | Clear session and token |
| `on(event, handler)` | `void` | Subscribe to an event |
| `off(event, handler)` | `void` | Unsubscribe from an event |

## Events

| Event | Callback | When |
|-------|----------|------|
| `login` | `() => void` | Player logged in |
| `logout` | `() => void` | Player logged out |
| `tierChange` | `(tier: PlayerTier) => void` | Subscription tier changed |
| `pause` | `() => void` | Game paused by SDK (modal opening) |
| `unpause` | `() => void` | Game unpaused by SDK (modal closed) |

## Tier Hierarchy

`none` (0) < `free` (1) < `supporter` (2) < `founder` (3)

`requireTier('supporter')` returns `true` for both `supporter` and `founder` players.

## Session Storage

The SDK stores tokens in `localStorage` under the key `subgames_token`. Sessions are restored automatically on `init()`.

## 30-Second Prompt

The SDK auto-prompts unauthenticated players (tier = `none`) to subscribe after 30 seconds. This is not configurable. If your `requireTier()` fires before 30s, it takes priority.
