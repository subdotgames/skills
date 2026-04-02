# Framework-Specific Integration Patterns

## Phaser 3

```js
// In your main scene's create() method:
const subgames = SubGamesSDK.init({ gameKey: 'my-game', overlay: true });

subgames.on('pause', () => this.scene.pause());
subgames.on('unpause', () => this.scene.resume());

// Gate a feature in any scene method:
async unlockBonusLevel() {
  const allowed = await subgames.requireTier('supporter', 'bonus levels');
  if (!allowed) return;
  this.scene.start('BonusLevel');
}
```

## Three.js

```js
let paused = false;
const subgames = SubGamesSDK.init({ gameKey: 'my-game', overlay: true });

subgames.on('pause', () => { paused = true; });
subgames.on('unpause', () => { paused = false; });

function animate() {
  requestAnimationFrame(animate);
  if (paused) return;
  // ... render loop
}
```

## Pixi.js

```js
const subgames = SubGamesSDK.init({ gameKey: 'my-game', overlay: true });

subgames.on('pause', () => app.ticker.stop());
subgames.on('unpause', () => app.ticker.start());
```

## Vanilla Canvas / requestAnimationFrame

```js
let animFrameId;
const subgames = SubGamesSDK.init({ gameKey: 'my-game', overlay: true });

subgames.on('pause', () => {
  if (animFrameId) cancelAnimationFrame(animFrameId);
  animFrameId = null;
});

subgames.on('unpause', () => {
  if (!animFrameId) animFrameId = requestAnimationFrame(gameLoop);
});
```

## HTML / DOM-Based Games

```js
const subgames = SubGamesSDK.init({ gameKey: 'my-game', overlay: true });

subgames.on('pause', () => {
  clearInterval(gameInterval);
  document.getElementById('game').classList.add('paused');
});

subgames.on('unpause', () => {
  gameInterval = setInterval(tick, 1000 / 60);
  document.getElementById('game').classList.remove('paused');
});
```
