#!/usr/bin/env bash
# Validates that @subgames/sdk is properly integrated into a game project.
# Usage: validate-integration.sh [game-directory]
# Exit code 0 = all checks pass, non-zero = issues found.

set -euo pipefail

DIR="${1:-.}"
ERRORS=0
WARNINGS=0

check_pass() { echo "  PASS: $1"; }
check_fail() { echo "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }
check_warn() { echo "  WARN: $1"; WARNINGS=$((WARNINGS + 1)); }

echo "=== sub.games SDK Integration Validator ==="
echo "Checking: $DIR"
echo ""

# 1. SDK installed?
echo "[1/6] SDK Installation"
if [ -f "$DIR/package.json" ]; then
  if grep -q '"@subgames/sdk"' "$DIR/package.json"; then
    check_pass "@subgames/sdk found in package.json"
  else
    # Check for CDN script tag
    if grep -rq 'cdn.sub.games/sdk' "$DIR"/*.html "$DIR"/index.html 2>/dev/null; then
      check_pass "SDK loaded via CDN script tag"
    else
      check_fail "@subgames/sdk not found in package.json or as CDN script tag"
    fi
  fi
else
  if grep -rq 'cdn.sub.games/sdk' "$DIR"/*.html 2>/dev/null; then
    check_pass "SDK loaded via CDN script tag (no package.json)"
  else
    check_fail "No package.json and no CDN script tag found"
  fi
fi

# 2. SDK initialized?
echo "[2/6] SDK Initialization"
if grep -rq 'SubGamesSDK.init' "$DIR/src" "$DIR"/*.js "$DIR"/*.ts "$DIR"/*.html 2>/dev/null; then
  check_pass "SubGamesSDK.init() call found"
else
  check_fail "No SubGamesSDK.init() call found in source files"
fi

# 3. gameKey set?
echo "[3/6] Game Key Configuration"
if grep -rq "gameKey:" "$DIR/src" "$DIR"/*.js "$DIR"/*.ts "$DIR"/*.html 2>/dev/null; then
  if grep -rq "gameKey: 'your-game-slug'" "$DIR/src" "$DIR"/*.js "$DIR"/*.ts "$DIR"/*.html 2>/dev/null; then
    check_warn "gameKey is still set to placeholder 'your-game-slug' — update before deploying"
  else
    check_pass "gameKey is configured"
  fi
else
  check_fail "No gameKey found in SDK init config"
fi

# 4. Pause/unpause handlers?
echo "[4/6] Pause/Unpause Handlers"
PAUSE_COUNT=$(grep -rc "\.on('pause'" "$DIR/src" "$DIR"/*.js "$DIR"/*.ts "$DIR"/*.html 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
UNPAUSE_COUNT=$(grep -rc "\.on('unpause'" "$DIR/src" "$DIR"/*.js "$DIR"/*.ts "$DIR"/*.html 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
if [ "$PAUSE_COUNT" -gt 0 ] && [ "$UNPAUSE_COUNT" -gt 0 ]; then
  check_pass "pause and unpause event handlers found"
else
  if [ "$PAUSE_COUNT" -eq 0 ]; then
    check_fail "No 'pause' event handler found — game won't freeze when subscribe modal opens"
  fi
  if [ "$UNPAUSE_COUNT" -eq 0 ]; then
    check_fail "No 'unpause' event handler found — game won't resume after modal closes"
  fi
fi

# 5. Tier-gating?
echo "[5/6] Tier-Gating"
TIER_COUNT=$(grep -rc "requireTier" "$DIR/src" "$DIR"/*.js "$DIR"/*.ts "$DIR"/*.html 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
if [ "$TIER_COUNT" -gt 0 ]; then
  check_pass "$TIER_COUNT requireTier() call(s) found"
else
  check_warn "No requireTier() calls found — SDK will only show the 30-second auto-prompt"
fi

# 6. Sparkle markers?
echo "[6/6] Sparkle Emoji Markers"
if grep -rq '✨\|&#10024;\|\\u2728\|\u2728' "$DIR/src" "$DIR"/*.js "$DIR"/*.ts "$DIR"/*.html 2>/dev/null; then
  check_pass "Sparkle emoji markers found in source"
else
  check_warn "No sparkle markers found — gated features should show ✨ indicators"
fi

echo ""
echo "=== Results ==="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  echo "STATUS: FAIL — fix errors above before deploying"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  echo "STATUS: PASS with warnings"
  exit 0
else
  echo "STATUS: PASS — integration looks good"
  exit 0
fi
