#!/usr/bin/env bash
# Validates that @subgames/sdk is properly integrated into a game project.
# Usage: validate-integration.sh [game-directory]
# Exit code 0 = all checks pass, non-zero = issues found.

set -euo pipefail
shopt -s nullglob

DIR="${1:-.}"
ERRORS=0
WARNINGS=0

check_pass() { echo "  PASS: $1"; }
check_fail() { echo "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }
check_warn() { echo "  WARN: $1"; WARNINGS=$((WARNINGS + 1)); }

echo "=== sub.games SDK Integration Validator ==="
echo "Checking: $DIR"
echo ""

SOURCE_GREP=(grep -R)
SOURCE_GREP+=(--include='*.html' --include='*.js' --include='*.ts')
SOURCE_GREP+=(--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.git)

count_matches() {
  local pattern="$1"
  grep -R -c \
    --include='*.html' \
    --include='*.js' \
    --include='*.ts' \
    --exclude-dir=node_modules \
    --exclude-dir=dist \
    --exclude-dir=.git \
    "$pattern" "$DIR" 2>/dev/null | awk -F: '{sum+=$NF} END{print sum+0}'
}

# 1. SDK installed?
echo "[1/6] SDK Installation"
if [ -f "$DIR/package.json" ]; then
  if grep -q '"@subgames/sdk"' "$DIR/package.json"; then
    check_pass "@subgames/sdk found in package.json"
  else
    # Check for CDN script tag
    if "${SOURCE_GREP[@]}" 'sdk.sub.games/sdk' "$DIR" >/dev/null 2>&1; then
      check_pass "SDK loaded via CDN script tag"
    else
      check_fail "@subgames/sdk not found in package.json or as CDN script tag"
    fi
  fi
else
  if "${SOURCE_GREP[@]}" 'sdk.sub.games/sdk' "$DIR" >/dev/null 2>&1; then
    check_pass "SDK loaded via CDN script tag (no package.json)"
  else
    check_fail "No package.json and no CDN script tag found"
  fi
fi

# 2. SDK initialized?
echo "[2/6] SDK Initialization"
if "${SOURCE_GREP[@]}" 'SubGamesSDK.init' "$DIR" >/dev/null 2>&1; then
  check_pass "SubGamesSDK.init() call found"
else
  check_fail "No SubGamesSDK.init() call found in source files"
fi

# 3. gameKey set?
echo "[3/6] Game Key Configuration"
if "${SOURCE_GREP[@]}" "gameKey:" "$DIR" >/dev/null 2>&1; then
  if "${SOURCE_GREP[@]}" "gameKey: 'your-game-slug'" "$DIR" >/dev/null 2>&1; then
    check_warn "gameKey is still set to placeholder 'your-game-slug' — update before deploying"
  else
    check_pass "gameKey is configured"
  fi
else
  check_fail "No gameKey found in SDK init config"
fi

# 4. Pause/unpause handlers?
echo "[4/6] Pause/Unpause Handlers"
PAUSE_COUNT=$(count_matches "\\.on(['\"]pause['\"]")
UNPAUSE_COUNT=$(count_matches "\\.on(['\"]unpause['\"]")
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
TIER_COUNT=$(count_matches "requireTier")
if [ "$TIER_COUNT" -gt 0 ]; then
  check_pass "$TIER_COUNT requireTier() call(s) found"
else
  check_warn "No requireTier() calls found — SDK will only show the 30-second auto-prompt"
fi

# 6. Sparkle markers?
echo "[6/6] Sparkle Emoji Markers"
if "${SOURCE_GREP[@]}" '✨\|&#10024;\|\\u2728\|\u2728' "$DIR" >/dev/null 2>&1; then
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
